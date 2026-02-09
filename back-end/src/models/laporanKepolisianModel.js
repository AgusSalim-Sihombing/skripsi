const db = require("../config/database");

// =================== MOBILE (MASYARAKAT) ===================
const createReport = async (userId, data) => {
    const sql = `
    INSERT INTO laporan_kepolisian (
      pelapor_user_id, status,
      waktu_kejadian_hari, waktu_kejadian_tanggal, waktu_kejadian_jam,
      tempat_jalan, tempat_desa_kel, tempat_kecamatan, tempat_kab_kota,
      apa_terjadi,
      terlapor_nama, terlapor_jk, terlapor_alamat, terlapor_pekerjaan, terlapor_kontak,
      korban_nama, korban_jk, korban_alamat, korban_pekerjaan, korban_kontak,
      bagaimana_terjadi,
      dilaporkan_hari, dilaporkan_tanggal, dilaporkan_jam,
      tindak_pidana,
      saksi1_nama, saksi1_umur, saksi1_alamat, saksi1_pekerjaan,
      saksi2_nama, saksi2_umur, saksi2_alamat, saksi2_pekerjaan,
      barang_bukti, uraian_singkat, tindakan_dilakukan,
      mengetahui_kepala_jabatan, mengetahui_kepala_nama, mengetahui_kepala_pangkat_nrp,
      pelapor_nama, pelapor_pangkat_nrp, pelapor_kesatuan, pelapor_kontak
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
  `;

    const params = [
        userId, "pending",

        data.waktu_kejadian_hari || null,
        data.waktu_kejadian_tanggal || null,
        data.waktu_kejadian_jam || null,

        data.tempat_jalan || null,
        data.tempat_desa_kel || null,
        data.tempat_kecamatan || null,
        data.tempat_kab_kota || null,

        data.apa_terjadi || null,

        data.terlapor_nama || null,
        data.terlapor_jk || null,
        data.terlapor_alamat || null,
        data.terlapor_pekerjaan || null,
        data.terlapor_kontak || null,

        data.korban_nama || null,
        data.korban_jk || null,
        data.korban_alamat || null,
        data.korban_pekerjaan || null,
        data.korban_kontak || null,

        data.bagaimana_terjadi || null,

        data.dilaporkan_hari || null,
        data.dilaporkan_tanggal || null,
        data.dilaporkan_jam || null,

        data.tindak_pidana || null,

        data.saksi1_nama || null,
        data.saksi1_umur ?? null,
        data.saksi1_alamat || null,
        data.saksi1_pekerjaan || null,

        data.saksi2_nama || null,
        data.saksi2_umur ?? null,
        data.saksi2_alamat || null,
        data.saksi2_pekerjaan || null,

        data.barang_bukti || null,
        data.uraian_singkat || null,
        data.tindakan_dilakukan || null,

        data.mengetahui_kepala_jabatan || null,
        data.mengetahui_kepala_nama || null,
        data.mengetahui_kepala_pangkat_nrp || null,

        data.pelapor_nama || null,
        data.pelapor_pangkat_nrp || null,
        data.pelapor_kesatuan || null,
        data.pelapor_kontak || null,
    ];

    const [res] = await db.execute(sql, params);
    return res.insertId;
};

const getMineList = async (userId, { page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;
    const [rows] = await db.execute(
        `
    SELECT id, status, tindak_pidana, tempat_kab_kota, created_at,
           assigned_officer_user_id, responded_at, completed_at
    FROM laporan_kepolisian
    WHERE pelapor_user_id = ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
    `,
        [userId, Number(limit), Number(offset)]
    );
    return rows;
};

const getMineDetail = async (userId, id) => {
    const [rows] = await db.execute(
        `SELECT * FROM laporan_kepolisian WHERE id = ? AND pelapor_user_id = ?`,
        [id, userId]
    );
    return rows[0];
};

// =================== OFFICER ===================
const listPending = async ({ page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;
    const [rows] = await db.execute(
        `
    SELECT lk.id, lk.status, lk.tindak_pidana, lk.tempat_kab_kota, lk.created_at,
           u.username AS pelapor_username, u.nama AS pelapor_nama
    FROM laporan_kepolisian lk
    JOIN user u ON u.id = lk.pelapor_user_id
    WHERE lk.status = 'pending'
      AND lk.assigned_officer_user_id IS NULL
    ORDER BY lk.created_at ASC
    LIMIT ? OFFSET ?
    `,
        [Number(limit), Number(offset)]
    );
    return rows;
};

const listMineAsOfficer = async (officerId, { status, page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;

    let sql = `
    SELECT id, status, tindak_pidana, tempat_kab_kota, created_at, responded_at, completed_at
    FROM laporan_kepolisian
    WHERE assigned_officer_user_id = ?
  `;
    const params = [officerId];

    if (status) {
        sql += ` AND status = ?`;
        params.push(status);
    }

    sql += ` ORDER BY responded_at DESC, created_at DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit), Number(offset));

    const [rows] = await db.execute(sql, params);
    return rows;
};

const officerGetDetail = async (officerId, id) => {
    const [rows] = await db.execute(
        `
    SELECT *
    FROM laporan_kepolisian
    WHERE id = ?
      AND (
        status = 'pending'
        OR assigned_officer_user_id = ?
      )
    `,
        [id, officerId]
    );
    return rows[0];
};

// ✅ ATOMIC TAKE: biar 2 officer gak bisa rebutan
const respond = async (officerId, id) => {
    const [res] = await db.execute(
        `
    UPDATE laporan_kepolisian
    SET status = 'on_process',
        assigned_officer_user_id = ?,
        responded_at = NOW()
    WHERE id = ?
      AND status = 'pending'
      AND assigned_officer_user_id IS NULL
    `,
        [officerId, id]
    );
    return res.affectedRows; // 1 = sukses ambil, 0 = udah diambil orang / bukan pending
};

const finish = async (officerId, id) => {
    const [res] = await db.execute(
        `
    UPDATE laporan_kepolisian
    SET status = 'selesai',
        completed_at = NOW()
    WHERE id = ?
      AND status = 'on_process'
      AND assigned_officer_user_id = ?
    `,
        [id, officerId]
    );
    return res.affectedRows;
};

const cancelMine = async (userId, id) => {
  const [res] = await db.execute(
    `
    UPDATE laporan_kepolisian
    SET status = 'dibatalkan'
    WHERE id = ?
      AND pelapor_user_id = ?
      AND status = 'pending'
      AND assigned_officer_user_id IS NULL
    `,
    [id, userId]
  );
  return res.affectedRows;
};

// =================== ADMIN WEB ===================
const adminList = async ({ status, search, page = 1, limit = 20 }) => {
  const offset = (page - 1) * limit;

  let sql = `
    SELECT
      lk.id,
      lk.status,
      lk.tindak_pidana,
      lk.tempat_kab_kota,
      lk.created_at,
      lk.responded_at,
      lk.completed_at,

      pelapor.id AS pelapor_id,
      pelapor.username AS pelapor_username,
      pelapor.nama AS pelapor_nama,

      officer.id AS officer_id,
      officer.username AS officer_username,
      officer.nama AS officer_nama

    FROM laporan_kepolisian lk
    JOIN \`user\` pelapor ON pelapor.id = lk.pelapor_user_id
    LEFT JOIN \`user\` officer ON officer.id = lk.assigned_officer_user_id
    WHERE 1=1
  `;

  const params = [];

  if (status) {
    sql += ` AND lk.status = ?`;
    params.push(status);
  }

  if (search) {
    sql += `
      AND (
        pelapor.username LIKE ?
        OR pelapor.nama LIKE ?
        OR officer.username LIKE ?
        OR officer.nama LIKE ?
        OR lk.tindak_pidana LIKE ?
        OR lk.tempat_kab_kota LIKE ?
      )
    `;
    const s = `%${search}%`;
    params.push(s, s, s, s, s, s);
  }

  sql += ` ORDER BY lk.created_at DESC LIMIT ? OFFSET ?`;
  params.push(Number(limit), Number(offset));

  const [rows] = await db.execute(sql, params);
  return rows;
};

const getById = async (id) => {
  const [rows] = await db.execute(
    `
    SELECT
      lk.*,

      pelapor.id AS pelapor_id,
      pelapor.username AS pelapor_username,
      pelapor.nama AS pelapor_nama,

      officer.id AS officer_id,
      officer.username AS officer_username,
      officer.nama AS officer_nama

    FROM laporan_kepolisian lk
    JOIN \`user\` pelapor ON pelapor.id = lk.pelapor_user_id
    LEFT JOIN \`user\` officer ON officer.id = lk.assigned_officer_user_id
    WHERE lk.id = ?
    LIMIT 1
    `,
    [id]
  );
  return rows[0] || null;
};

const adminUpdateStatus = async (id, { status }) => {
  const [res] = await db.execute(
    `
    UPDATE laporan_kepolisian
    SET
      status = ?,
      responded_at = IF(? = 'on_process' AND responded_at IS NULL, NOW(), responded_at),
      completed_at = IF(? = 'selesai' AND completed_at IS NULL, NOW(), completed_at)
    WHERE id = ?
    `,
    [status, status, status, id]
  );
  return res.affectedRows;
};

module.exports = {
    createReport,
    getMineList,
    getMineDetail,

    listPending,
    listMineAsOfficer,
    officerGetDetail,
    respond,
    finish,
    cancelMine,
    adminList,
    getById,
    adminUpdateStatus,
};
