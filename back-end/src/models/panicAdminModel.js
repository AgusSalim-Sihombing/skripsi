const db = require("../config/database");

// List panic untuk admin (filter + search + pagination)
const adminList = async ({ status, search, page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;

    let where = `WHERE 1=1`;
    const params = [];

    if (status) {
        where += ` AND pe.status = ?`;
        params.push(status);
    }

    if (search) {
        where += ` AND (
      pe.id LIKE ?
      OR pe.citizen_name_snap LIKE ?
      OR pe.assigned_officer_name_snap LIKE ?
      OR cu.username LIKE ?
      OR ou.username LIKE ?
    )`;
        const s = `%${search}%`;
        params.push(s, s, s, s, s);
    }

    const sql = `
    SELECT
      pe.id AS panicId,
      pe.status,
      pe.created_at,
      pe.responded_at,
      pe.resolved_at,

      pe.citizen_id,
      pe.citizen_name_snap AS citizenName,
      cu.username AS citizenUsername,

      pe.assigned_officer_id AS officerId,
      pe.assigned_officer_name_snap AS officerName,
      ou.username AS officerUsername,

      pe.citizen_lat AS lat,
      pe.citizen_lng AS lng,
      pe.citizen_address_snap AS address
    FROM panic_events pe
    LEFT JOIN \`user\` cu ON cu.id = pe.citizen_id
    LEFT JOIN \`user\` ou ON ou.id = pe.assigned_officer_id
    ${where}
    ORDER BY pe.created_at DESC
    LIMIT ? OFFSET ?
  `;

    params.push(Number(limit), Number(offset));
    const [rows] = await db.execute(sql, params);
    return rows;
};

// Detail panic + info citizen + officer + lokasi officer_live + dispatch targets
const adminDetail = async (panicId) => {
    const [rows] = await db.execute(
        `
    SELECT
      pe.*,

      cu.username AS citizenUsername,
      cu.nama AS citizenNama,
      cu.phone AS citizenPhone,
      cu.alamat as citizenAlamat,

      ou.username AS officerUsername,
      ou.nama AS officerNama,
      ou.phone AS officerPhone,
      ou.alamat as officerAlamat,

      ol.last_lat AS officerLastLat,
      ol.last_lng AS officerLastLng,
      ol.last_loc_updated_at AS officerLastUpdatedAt
    FROM panic_events pe
    LEFT JOIN \`user\` cu ON cu.id = pe.citizen_id
    LEFT JOIN \`user\` ou ON ou.id = pe.assigned_officer_id
    LEFT JOIN officer_live ol ON ol.user_id = pe.assigned_officer_id
    WHERE pe.id = ?
    LIMIT 1
    `,
        [panicId]
    );

    return rows[0] || null;
};

const adminDispatchTargets = async (panicId) => {
    const [rows] = await db.execute(
        `
    SELECT
      pdt.officer_id AS officerId,
      pdt.distance_m AS distanceM,
      u.username,
      u.nama
    FROM panic_dispatch_targets pdt
    JOIN \`user\` u ON u.id = pdt.officer_id
    WHERE pdt.panic_id = ?
    ORDER BY pdt.distance_m ASC
    `,
        [panicId]
    );
    return rows;
};

module.exports = {
    adminList,
    adminDetail,
    adminDispatchTargets,
};
