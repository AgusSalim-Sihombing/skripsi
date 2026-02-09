const db = require("../config/database");

// ambil ringkasan data buat dashboard
const getDashboardSummary = async () => {
    // total semua laporan
    const [totalLaporanRows] = await db.execute(
        "SELECT COUNT(*) AS total_laporan FROM laporan_cepat"
    );

    // laporan yang dibuat hari ini
    const [laporanHariIniRows] = await db.execute(
        "SELECT COUNT(*) AS laporan_hari_ini FROM laporan_cepat WHERE DATE(created_at) = CURDATE()"
    );

    // total titik rawan / zona bahaya
    const [titikRawanRows] = await db.execute(
        "SELECT COUNT(*) AS total_titik_rawan FROM zona_bahaya"
    );

    // total aktivitas hari ini
    const [aktivitasHariIniRows] = await db.execute(
        "SELECT COUNT(*) AS aktivitas_hari_ini FROM aktivitas WHERE DATE(created_at) = CURDATE()"
    );

    return {
        total_laporan: totalLaporanRows[0].total_laporan || 0,
        laporan_hari_ini: laporanHariIniRows[0].laporan_hari_ini || 0,
        total_titik_rawan: titikRawanRows[0].total_titik_rawan || 0,
        aktivitas_hari_ini: aktivitasHariIniRows[0].aktivitas_hari_ini || 0,
    };
};

module.exports = {
    getDashboardSummary,
};
