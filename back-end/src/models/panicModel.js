const db = require("../config/database");

const createPanicEvent = async ({
    citizenId,
    citizenName,
    lat,
    lng,
    address,
}) => {
    const [ins] = await db.execute(
        `INSERT INTO panic_events
     (citizen_id, citizen_name_snap, citizen_lat, citizen_lng, citizen_address_snap, status)
     VALUES (?,?,?,?,?, 'OPEN')`,
        [citizenId, citizenName, lat, lng, address || null]
    );
    return ins.insertId;
};

// cari officer terdekat yang approved + verified + on duty + lokasi fresh
const findNearestOfficers = async ({ lat, lng, limit = 3 }) => {
    const [rows] = await db.execute(
        `SELECT
        u.id,
        u.nama,
        ST_Distance_Sphere(
          POINT(ol.last_lng, ol.last_lat),
          POINT(?, ?)
        ) AS dist_m
     FROM \`user\` u
     JOIN officer_applications oa
       ON oa.user_id = u.id
      AND oa.status = 'approved'
     JOIN officer_live ol
       ON ol.user_id = u.id
     WHERE u.role = 'officer'
       AND u.status_verifikasi = 'verified'
       AND ol.is_on_duty = 1
       AND ol.last_lat IS NOT NULL
       AND ol.last_lng IS NOT NULL
       AND ol.last_loc_updated_at >= (NOW() - INTERVAL 2 MINUTE)
       AND ol.is_busy = 0
     ORDER BY dist_m ASC
     LIMIT ?`,
        [lng, lat, Number(limit)]
    );
    return rows;
};

const insertDispatchTarget = async (panicId, officerId, distanceM) => {
    await db.execute(
        `INSERT INTO panic_dispatch_targets (panic_id, officer_id, distance_m)
     VALUES (?,?,?)`,
        [panicId, officerId, distanceM]
    );
};

// first accept wins (transaction + FOR UPDATE)
const assignPanicToOfficerTx = async ({ panicId, officerId, officerName }) => {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        const [[panic]] = await conn.execute(
            `SELECT * FROM panic_events WHERE id=? FOR UPDATE`,
            [panicId]
        );

        if (!panic) {
            await conn.rollback();
            return { ok: false, code: 404, message: "Panic tidak ditemukan" };
        }

        if (panic.status !== "OPEN") {
            await conn.rollback();
            return { ok: false, code: 409, message: "Panic sudah diambil / tidak OPEN" };
        }

        // ✅ SET PANIC ASSIGNED
        await conn.execute(
            `UPDATE panic_events
       SET status='ASSIGNED',
           assigned_officer_id=?,
           assigned_officer_name_snap=?,
           responded_at=NOW()
       WHERE id=?`,
            [officerId, officerName, panicId]
        );

        // ✅ SET OFFICER BUSY (kunci: supaya dia gak dapat panic lain)
        await conn.execute(
            `UPDATE officer_live
       SET is_busy = 1,
           current_panic_id = ?,
           busy_since = NOW()
       WHERE user_id = ?`,
            [panicId, officerId]
        );

        await conn.commit();
        return { ok: true, panic };
    } catch (e) {
        await conn.rollback();
        return { ok: false, code: 500, message: e.message };
    } finally {
        conn.release();
    }
};


const getPanicById = async (panicId) => {
    const [rows] = await db.execute(`SELECT * FROM panic_events WHERE id=?`, [panicId]);
    return rows[0] || null;
};

const getDispatchTargets = async (panicId) => {
    const [rows] = await db.execute(
        `SELECT officer_id FROM panic_dispatch_targets WHERE panic_id=?`,
        [panicId]
    );
    return rows;
};

const listOfferedPanicsForOfficer = async (officerId) => {
    const [rows] = await db.execute(
        `SELECT
        pe.id AS panicId,
        pe.citizen_name_snap AS fromName,
        pe.citizen_lat AS lat,
        pe.citizen_lng AS lng,
        pe.citizen_address_snap AS address,
        pdt.distance_m AS distanceM,
        pe.status,
        pe.created_at
     FROM panic_dispatch_targets pdt
     JOIN panic_events pe ON pe.id = pdt.panic_id
     WHERE pdt.officer_id = ?
     ORDER BY pe.created_at DESC
     LIMIT 30`,
        [officerId]
    );
    return rows;
};

const resolvePanicForOfficer = async ({ panicId, officerId }) => {
    const [result] = await db.execute(
        `UPDATE panic_events
     SET status='RESOLVED', resolved_at=NOW()
     WHERE id=? AND assigned_officer_id=? AND status='ASSIGNED'`,
        [panicId, officerId]
    );
    return result.affectedRows; // 1 kalau sukses
};

const getActivePanicByCitizenId = async (citizenId) => {
    const [rows] = await db.execute(
        `SELECT id, status, created_at
     FROM panic_events
     WHERE citizen_id=? AND status IN ('OPEN','ASSIGNED')
     ORDER BY created_at DESC
     LIMIT 1`,
        [citizenId]
    );
    return rows[0] || null;
};

const listHistoryForOfficer = async (officerId, limit = 100) => {
  const [rows] = await db.execute(
    `SELECT
        pe.id AS panicId,
        pe.citizen_name_snap AS fromName,
        pe.citizen_lat AS lat,
        pe.citizen_lng AS lng,
        pe.citizen_address_snap AS address,
        pe.status,
        pe.created_at AS createdAt,
        pe.responded_at AS respondedAt,
        pe.resolved_at AS resolvedAt,
        pdt.distance_m AS distanceM
     FROM panic_events pe
     LEFT JOIN panic_dispatch_targets pdt
       ON pdt.panic_id = pe.id AND pdt.officer_id = ?
     WHERE pe.assigned_officer_id = ?
     ORDER BY pe.responded_at DESC, pe.created_at DESC
     LIMIT ?`,
    [officerId, officerId, Number(limit)]
  );

  return rows;
};

const getHistoryDetailForOfficer = async (officerId, panicId) => {
  const [rows] = await db.execute(
    `SELECT
        pe.id AS panicId,
        pe.citizen_id AS citizenId,
        pe.citizen_name_snap AS fromName,
        pe.citizen_lat AS lat,
        pe.citizen_lng AS lng,
        pe.citizen_address_snap AS address,
        pe.status,
        pe.created_at AS createdAt,
        pe.responded_at AS respondedAt,
        pe.resolved_at AS resolvedAt,
        pe.assigned_officer_id AS assignedOfficerId,
        pe.assigned_officer_name_snap AS assignedOfficerName,
        pdt.distance_m AS distanceM
     FROM panic_events pe
     LEFT JOIN panic_dispatch_targets pdt
       ON pdt.panic_id = pe.id AND pdt.officer_id = ?
     WHERE pe.id = ? AND pe.assigned_officer_id = ?
     LIMIT 1`,
    [officerId, Number(panicId), officerId]
  );

  return rows[0] || null;
};


module.exports = {
    createPanicEvent,
    findNearestOfficers,
    insertDispatchTarget,
    assignPanicToOfficerTx,
    getPanicById,
    getDispatchTargets,
    listOfferedPanicsForOfficer,
    resolvePanicForOfficer,
    getActivePanicByCitizenId,
    listHistoryForOfficer,
    getHistoryDetailForOfficer,
};
