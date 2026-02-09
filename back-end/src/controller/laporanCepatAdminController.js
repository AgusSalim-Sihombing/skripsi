// // src/controller/laporanCepatAdminController.js
// const db = require("../config/database");
// const {
//     getLaporanList,
//     getLaporanById,
//     getLaporanForZonaSelector,
//     updateStatusLaporan,
// } = require("../models/laporanCepatModel");

// const { setZonaStatusByLaporan } = require("../models/zonaBahayaModel");
// const { getVoteSummaryByLaporan } = require("../models/zonaBahayaVoteModel");

// // GET /api/admin/laporan-cepat
// const listLaporanAdmin = async (req, res) => {
//     try {
//         const { search, status, tanggal_from, tanggal_to } = req.query;

//         const data = await getLaporanList({
//             search: search || "",
//             status: status || "",
//             tanggalFrom: tanggal_from || "",
//             tanggalTo: tanggal_to || "",
//         });

//         return res.json({
//             success: true,
//             message: "Berhasil mengambil data laporan cepat",
//             data,
//         });
//     } catch (err) {
//         console.error("listLaporanAdmin error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan saat mengambil data laporan",
//         });
//     }
// };

// // GET /api/admin/laporan-cepat/:id
// const detailLaporanAdmin = async (req, res) => {
//     const { id } = req.params;

//     try {
//         // detail laporan + (opsional) data pelapor
//         const [rows] = await db.execute(
//             `
//       SELECT 
//         lc.*,
//         u.nama       AS nama_pelapor,
//         u.nik        AS nik_pelapor,
//         u.phone      AS phone_pelapor,
//         u.email      AS email_pelapor
//       FROM laporan_cepat lc
//       LEFT JOIN user u ON lc.id_user = u.id
//       WHERE lc.id_laporan = ?
//       `,
//             [id]
//         );

//         if (rows.length === 0) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Laporan tidak ditemukan",
//             });
//         }

//         const laporan = rows[0];

//         // ringkasan voting (kalau tabel voting belum ada, sementara bisa di-skip)
//         let voting = {
//             total_setuju: 0,
//             total_tidak: 0,
//             total_vote: 0,
//             persentase_setuju: 0,
//             persentase_tidak: 0,
//         };

//         try {
//             const [voteRows] = await db.execute(
//                 `
//         SELECT total_setuju, total_tidak
//         FROM laporan_voting
//         WHERE id_laporan = ?
//         `,
//                 [id]
//             );

//             if (voteRows.length > 0) {
//                 const v = voteRows[0];
//                 const total = (v.total_setuju || 0) + (v.total_tidak || 0);

//                 voting.total_setuju = v.total_setuju || 0;
//                 voting.total_tidak = v.total_tidak || 0;
//                 voting.total_vote = total;
//                 voting.persentase_setuju =
//                     total === 0 ? 0 : Math.round((v.total_setuju / total) * 100);
//                 voting.persentase_tidak =
//                     total === 0 ? 0 : Math.round((v.total_tidak / total) * 100);
//             }
//         } catch (e) {
//             // kalau tabel voting belum ada, jangan bikin error 500
//             console.error("load voting error:", e.message);
//         }

//         return res.json({
//             success: true,
//             data: {
//                 laporan,
//                 voting,
//             },
//         });
//     } catch (err) {
//         console.error("detailLaporanAdmin error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Gagal mengambil detail laporan",
//         });
//     }
// };

// // GET /api/admin/laporan-cepat/for-zona
// const listLaporanForZona = async (req, res) => {
//     try {
//         const data = await getLaporanForZonaSelector();
//         return res.json({
//             success: true,
//             message: "Berhasil mengambil list laporan untuk zona",
//             data,
//         });
//     } catch (err) {
//         console.error("listLaporanForZona error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan saat mengambil data laporan untuk zona",
//         });
//     }
// };

// // POST /api/admin/laporan-cepat/:id/approve
// const approveLaporanAdmin = async (req, res) => {
//     try {
//         const { id } = req.params;

//         // ubah status laporan
//         await updateStatusLaporan(id, "approved");
//         // zona yg terkait jadi approve
//         await setZonaStatusByLaporan(id, "approve");
//         // voting ditutup
//         await closeVotingForLaporan(id);

//         return res.json({
//             success: true,
//             message: "Laporan berhasil di-approve dan zona diaktifkan",
//         });
//     } catch (err) {
//         console.error("approveLaporanAdmin error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Gagal meng-approve laporan",
//         });
//     }
// };

// // POST /api/admin/laporan-cepat/:id/reject
// const rejectLaporanAdmin = async (req, res) => {
//     try {
//         const { id } = req.params;

//         await updateStatusLaporan(id, "rejected");
//         await closeVotingForLaporan(id);
//         // kalau mau, bisa sekalian hapus/nonaktifkan zona di sini

//         return res.json({
//             success: true,
//             message: "Laporan berhasil ditolak",
//         });
//     } catch (err) {
//         console.error("rejectLaporanAdmin error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Gagal menolak laporan",
//         });
//     }
// };

// const fotoLaporanAdmin = async (req, res) => {
//     try {
//         const { id } = req.params;
//         const laporan = await getLaporanById(id);

//         if (!laporan || !laporan.foto) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Foto laporan tidak ditemukan",
//             });
//         }

//         // untuk sekarang anggap JPEG, kalau nanti kamu simpan mime_type bisa dibuat dinamis
//         res.setHeader("Content-Type", "image/jpeg");
//         return res.send(laporan.foto);
//     } catch (err) {
//         console.error("fotoLaporanAdmin error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan saat mengambil foto laporan",
//         });
//     }
// };

// module.exports = {
//     listLaporanAdmin,
//     detailLaporanAdmin,
//     listLaporanForZona,
//     approveLaporanAdmin,
//     rejectLaporanAdmin,
//     fotoLaporanAdmin,
// };
// src/controller/laporanCepatAdminController.js
const { getVoteSummaryByLaporan } = require("../models/zonaBahayaVoteModel");
// atau path sesuai project kamu

const db = require("../config/database");
const {
    getLaporanList,
    getLaporanById,
    getLaporanForZonaSelector,
    updateStatusLaporan,
} = require("../models/laporanCepatModel");

const { setZonaStatusByLaporan } = require("../models/zonaBahayaModel");

// GET /api/admin/laporan-cepat
const listLaporanAdmin = async (req, res) => {
    try {
        const { search, status, tanggal_from, tanggal_to } = req.query;

        const data = await getLaporanList({
            search: search || "",
            status: status || "",
            tanggalFrom: tanggal_from || "",
            tanggalTo: tanggal_to || "",
        });

        return res.json({
            success: true,
            message: "Berhasil mengambil data laporan cepat",
            data,
        });
    } catch (err) {
        console.error("listLaporanAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan saat mengambil data laporan",
        });
    }
};

// GET /api/admin/laporan-cepat/:id
const detailLaporanAdmin = async (req, res) => {
    const { id } = req.params;

    try {
        // detail laporan + (opsional) data pelapor
        const [rows] = await db.execute(
            `
      SELECT 
        lc.*,
        u.nama  AS nama_pelapor,
        u.nik   AS nik_pelapor,
        u.phone AS phone_pelapor,
        u.email AS email_pelapor
      FROM laporan_cepat lc
      LEFT JOIN user u ON lc.id_user = u.id
      WHERE lc.id_laporan = ?
      `,
            [id]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Laporan tidak ditemukan",
            });
        }

        const laporan = rows[0];

        // 🔥 Ringkasan voting dari zona_bahaya_vote (via id_laporan_sumber)
        let voting = {
            total_setuju: 0,
            total_tidak: 0,
            total_vote: 0,
            persentase_setuju: 0,
            persentase_tidak: 0,
        };

        try {
            voting = await getVoteSummaryByLaporan(id);
        } catch (e) {
            console.error("getVoteSummaryByLaporan error:", e.message);
        }

        console.log("voting summary for laporan", id, "=>", voting);

        return res.json({
            success: true,
            data: {
                laporan,
                voting,
            },
        });
    } catch (err) {
        console.error("detailLaporanAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal mengambil detail laporan",
        });
    }
};

// GET /api/admin/laporan-cepat/for-zona
const listLaporanForZona = async (req, res) => {
    try {
        const data = await getLaporanForZonaSelector();
        return res.json({
            success: true,
            message: "Berhasil mengambil list laporan untuk zona",
            data,
        });
    } catch (err) {
        console.error("listLaporanForZona error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan saat mengambil data laporan untuk zona",
        });
    }
};

// POST /api/admin/laporan-cepat/:id/approve
const approveLaporanAdmin = async (req, res) => {
    try {
        const { id } = req.params;

        // ubah status laporan
        await updateStatusLaporan(id, "approved");
        // zona yang terkait laporan ini jadi "approve"
        await setZonaStatusByLaporan(id, "approve");
        // voting otomatis "berhenti" karena zona tidak lagi berstatus pending

        return res.json({
            success: true,
            message: "Laporan berhasil di-approve dan zona diaktifkan",
        });
    } catch (err) {
        console.error("approveLaporanAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal meng-approve laporan",
        });
    }
};

// POST /api/admin/laporan-cepat/:id/reject
const rejectLaporanAdmin = async (req, res) => {
    try {
        const { id } = req.params;

        await updateStatusLaporan(id, "rejected");
        // kalau mau: di sini bisa tambahkan logika nonaktifkan/hapus zona

        return res.json({
            success: true,
            message: "Laporan berhasil ditolak",
        });
    } catch (err) {
        console.error("rejectLaporanAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal menolak laporan",
        });
    }
};

const fotoLaporanAdmin = async (req, res) => {
    try {
        const { id } = req.params;
        const laporan = await getLaporanById(id);

        if (!laporan || !laporan.foto) {
            return res.status(404).json({
                success: false,
                message: "Foto laporan tidak ditemukan",
            });
        }

        // untuk sekarang anggap JPEG, kalau nanti kamu simpan mime_type bisa dibuat dinamis
        res.setHeader("Content-Type", "image/jpeg");
        return res.send(laporan.foto);
    } catch (err) {
        console.error("fotoLaporanAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan saat mengambil foto laporan",
        });
    }
};

const getAdminLaporanDetailController = async (req, res) => {
    try {
        const idLaporan = parseInt(req.params.id, 10);

        // (punyamu) ambil laporan + pelapor + dll
        const laporan = await getAdminLaporanDetailFromDb(idLaporan); // sesuaikan
        if (!laporan) {
            return res.status(404).json({ success: false, message: "Laporan tidak ditemukan" });
        }

        // ✅ ini inti fix-nya
        const voting = await getVoteSummaryByLaporan(idLaporan);

        return res.json({
            success: true,
            data: {
                laporan,
                voting, // <--- web kamu butuh ini
            },
        });
    } catch (err) {
        console.error("getAdminLaporanDetailController error:", err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
};


module.exports = {
    listLaporanAdmin,
    detailLaporanAdmin,
    listLaporanForZona,
    approveLaporanAdmin,
    rejectLaporanAdmin,
    fotoLaporanAdmin,
    getAdminLaporanDetailController,
};
