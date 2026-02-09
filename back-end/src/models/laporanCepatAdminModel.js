// SESUAIKAN path ke koneksi database kamu
const pool = require("../config/database");

// 1) Ambil lokasi laporan untuk keperluan peta admin
//    misal: hanya yang status_validasi = 'pending' atau semua (tergantung kebutuhan)
const getLaporanLocationsForMap = async () => {
    const [rows] = await pool.execute(
        `
    SELECT 
      id_laporan,
      judul_laporan,
      latitude,
      longitude,
      status_validasi,
      tanggal_kejadian,
      waktu_kejadian
    FROM laporan_cepat
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
    `
    );

    return rows;
};

// 2) Ambil detail laporan + (opsional) info voting
const getLaporanDetailWithVoting = async (id_laporan) => {
    const [[laporan]] = await pool.execute(
        `
    SELECT 
      id_laporan,
      judul_laporan,
      deskripsi,
      foto_path,
      latitude,
      longitude,
      tanggal_kejadian,
      waktu_kejadian,
      status_validasi,
      nama_pelapor,
      is_anon,
      created_at
    FROM laporan_cepat
    WHERE id_laporan = ?
    `,
        [id_laporan]
    );

    if (!laporan) return null;

    const [votingRows] = await pool.execute(
        `
    SELECT 
      id_voting,
      pertanyaan,
      total_setuju,
      total_tidak_setuju,
      status_voting,
      created_at
    FROM laporan_voting
    WHERE id_laporan = ?
    ORDER BY created_at DESC
    LIMIT 1
    `,
        [id_laporan]
    );

    const voting = votingRows[0] || null;

    return { laporan, voting };
};

module.exports = {
    getLaporanLocationsForMap,
    getLaporanDetailWithVoting,
};
