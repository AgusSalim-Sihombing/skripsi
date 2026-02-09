// src/models/laporanCepatModel.js
const db = require("../config/database");

// list untuk halaman "Semua Laporan Cepat" (dengan filter)
const getLaporanList = async (filters = {}) => {
    let sql = `
    SELECT lc.*,
           u.nama AS nama_user,
           u.nik,
           u.phone,
           u.email
    FROM laporan_cepat lc
    LEFT JOIN user u ON lc.id_user = u.id
    WHERE 1=1
  `;
    const params = [];

    if (filters.search) {
        sql += " AND lc.judul_laporan LIKE ?";
        params.push(`%${filters.search}%`);
    }

    if (filters.status) {
        sql += " AND lc.status_validasi = ?";
        params.push(filters.status);
    }

    if (filters.tanggalFrom) {
        sql += " AND lc.tanggal_kejadian >= ?";
        params.push(filters.tanggalFrom);
    }

    if (filters.tanggalTo) {
        sql += " AND lc.tanggal_kejadian <= ?";
        params.push(filters.tanggalTo);
    }

    sql += " ORDER BY lc.created_at DESC";

    const [rows] = await db.execute(sql, params);
    return rows;
};

// detail satu laporan
const getLaporanById = async (id) => {
    const [rows] = await db.execute(
        `
    SELECT lc.*,
           u.nama  AS nama_user,
           u.nik   AS nik_user,
           u.phone AS phone_user,
           u.email AS email_user
    FROM laporan_cepat lc
    LEFT JOIN user u ON lc.id_user = u.id
    WHERE lc.id_laporan = ?
    `,
        [id]
    );
    return rows[0] || null;
};

// list ringan buat dropdown "Ambil dari Laporan" di Zona Bahaya
const getLaporanForZonaSelector = async () => {
    const [rows] = await db.execute(`
    SELECT id_laporan,
           judul_laporan,
           latitude,
           longitude,
           tanggal_kejadian,
           waktu_kejadian,
           status_validasi
    FROM laporan_cepat
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
    ORDER BY created_at DESC
    LIMIT 100
  `);
    return rows;
};

// update status_validasi (approve / reject)
const updateStatusLaporan = async (id_laporan, status) => {
    await db.execute(
        "UPDATE laporan_cepat SET status_validasi = ? WHERE id_laporan = ?",
        [status, id_laporan]
    );
};

const fotoLaporanAdmin = async (req, res) => {
    const { id } = req.params;

    try {
        const [rows] = await db.execute(
            "SELECT foto FROM laporan_cepat WHERE id_laporan = ?",
            [id]
        );

        if (rows.length === 0 || !rows[0].foto) {
            return res.status(404).end();
        }

        // kalau kamu simpan selalu JPEG, ini aman. Kalau campur, perlu column mime_type.
        res.setHeader("Content-Type", "image/jpeg");
        res.send(rows[0].foto);
    } catch (err) {
        console.error("fotoLaporanAdmin error:", err);
        return res.status(500).end();
    }
};

module.exports = {
    getLaporanList,
    getLaporanById,
    getLaporanForZonaSelector,
    updateStatusLaporan,
    fotoLaporanAdmin,
};
