// // src/models/laporanVotingModel.js
// const db = require("../config/database");

// const getVotingByLaporanId = async (id_laporan) => {
//     const [rows] = await db.execute(
//         "SELECT * FROM laporan_voting WHERE id_laporan = ?",
//         [id_laporan]
//     );
//     return rows[0] || null;
// };

// const closeVotingForLaporan = async (id_laporan) => {
//     await db.execute(
//         "UPDATE laporan_voting SET status_voting = 'selesai' WHERE id_laporan = ?",
//         [id_laporan]
//     );
// };

// module.exports = {
//     getVotingByLaporanId,
//     closeVotingForLaporan,
// };
