// const {
//     getAllZonaBahaya,
//     createZonaBahaya,
//     updateZonaBahaya,
//     deleteZonaBahaya,
// } = require("../models/zonaBahayaModel");

// const {
//     getVoteSummary,
//     getVotesWithUser,
// } = require("../models/zonaBahayaVoteModel");

// const listZonaBahaya = async (req, res) => {
//     try {
//         const data = await getAllZonaBahaya();
//         return res.json({
//             success: true,
//             message: "Berhasil mengambil data zona bahaya",
//             data,
//         });
//     } catch (err) {
//         console.error("listZonaBahaya error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan pada server",
//         });
//     }
// };

// const createZonaBahayaController = async (req, res) => {
//     try {
//         const {
//             id_laporan_sumber,
//             nama_zona,
//             deskripsi,
//             latitude,
//             longitude,
//             radius_meter,
//             warna_hex,
//             tingkat_risiko,
//             tanggal_kejadian,
//             waktu_kejadian,
//             status_zona,
//         } = req.body;

//         if (!nama_zona || !latitude || !longitude || !radius_meter) {
//             return res.status(400).json({
//                 success: false,
//                 message: "nama_zona, latitude, longitude, radius_meter wajib diisi",
//             });
//         }

//         const id = await createZonaBahaya({
//             id_laporan_sumber: id_laporan_sumber ? Number(id_laporan_sumber) : null,
//             nama_zona,
//             deskripsi,
//             latitude,
//             longitude,
//             radius_meter,
//             warna_hex,
//             tingkat_risiko,
//             tanggal_kejadian,
//             waktu_kejadian,
//             status_zona,
//         });

//         return res.status(201).json({
//             success: true,
//             message: "Zona bahaya berhasil ditambahkan",
//             data: { id_zona: id },
//         });
//     } catch (err) {
//         console.error("createZonaBahaya error:", err);
//         return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
//     }
// };

// const updateZonaBahayaController = async (req, res) => {
//     try {
//         const { id } = req.params;
//         const {
//             nama_zona,
//             deskripsi,
//             latitude,
//             longitude,
//             radius_meter,
//             warna_hex,
//             tingkat_risiko,
//             tanggal_kejadian,
//             waktu_kejadian,
//             status_zona
//         } = req.body;

//         if (!nama_zona || !latitude || !longitude || !radius_meter) {
//             return res.status(400).json({
//                 success: false,
//                 message: "nama_zona, latitude, longitude, radius_meter wajib diisi",
//             });
//         }

//         const affected = await updateZonaBahaya(id, {
//             nama_zona,
//             deskripsi,
//             latitude,
//             longitude,
//             radius_meter,
//             warna_hex,
//             tingkat_risiko,
//             tanggal_kejadian,
//             waktu_kejadian,
//             status_zona,
//         });

//         if (!affected) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Zona bahaya tidak ditemukan",
//             });
//         }

//         return res.json({
//             success: true,
//             message: "Zona bahaya berhasil diperbarui",
//         });
//     } catch (err) {
//         console.error("updateZonaBahaya error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan pada server",
//         });
//     }
// };

// const deleteZonaBahayaController = async (req, res) => {
//     try {
//         const { id } = req.params;

//         const affected = await deleteZonaBahaya(id);
//         if (!affected) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Zona bahaya tidak ditemukan",
//             });
//         }

//         return res.json({
//             success: true,
//             message: "Zona bahaya berhasil dihapus",
//         });
//     } catch (err) {
//         console.error("deleteZonaBahaya error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan pada server",
//         });
//     }
// };

// const getZonaBahayaVoteSummaryAdmin = async (req, res) => {
//     try {
//         const idZona = parseInt(req.params.id_zona, 10);

//         if (!idZona || Number.isNaN(idZona)) {
//             return res.status(400).json({ message: "ID zona tidak valid" });
//         }

//         const summary = await getVoteSummary(idZona);
//         return res.json({
//             success: true,
//             data: summary,
//         });
//     } catch (err) {
//         console.error("getZonaBahayaVoteSummaryAdmin error:", err);
//         return res.status(500).json({
//             message: "Gagal mengambil data voting",
//             error: err.message,
//         });
//     }
// };

// // GET /api/admin/zona-bahaya/:id_zona/votes
// // kalau kamu mau lihat list voter + siapa saja di admin
// const getZonaBahayaVotesAdmin = async (req, res) => {
//     try {
//         const idZona = parseInt(req.params.id_zona, 10);

//         if (!idZona || Number.isNaN(idZona)) {
//             return res.status(400).json({ message: "ID zona tidak valid" });
//         }

//         const votes = await getVotesWithUser(idZona);
//         return res.json({
//             success: true,
//             data: votes,
//         });
//     } catch (err) {
//         console.error("getZonaBahayaVotesAdmin error:", err);
//         return res.status(500).json({
//             message: "Gagal mengambil daftar voting",
//             error: err.message,
//         });
//     }
// };


// module.exports = {
//     listZonaBahaya,
//     createZonaBahayaController,
//     updateZonaBahayaController,
//     deleteZonaBahayaController,
//     getZonaBahayaVoteSummaryAdmin,
//     getZonaBahayaVotesAdmin,
// };

const {
    getAllZonaBahaya,
    getZonaBahayaById,
    createZonaBahaya,
    updateZonaBahaya,
    updateZonaStatus,
    deleteZonaBahaya,
} = require("../models/zonaBahayaModel");

const {
    getVoteSummary,
    getVotesWithUser,
} = require("../models/zonaBahayaVoteModel");

const listZonaBahaya = async (req, res) => {
    try {
        const data = await getAllZonaBahaya();
        return res.json({
            success: true,
            message: "Berhasil mengambil data zona bahaya",
            data,
        });
    } catch (err) {
        console.error("listZonaBahaya error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const getZonaBahayaDetailAdmin = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id, 10);

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({
                success: false,
                message: "ID zona tidak valid",
            });
        }

        const data = await getZonaBahayaById(idZona);

        if (!data) {
            return res.status(404).json({
                success: false,
                message: "Zona bahaya tidak ditemukan",
            });
        }

        return res.json({
            success: true,
            message: "Berhasil mengambil detail zona bahaya",
            data,
        });
    } catch (err) {
        console.error("getZonaBahayaDetailAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const createZonaBahayaController = async (req, res) => {
    try {
        const {
            id_laporan_sumber,
            nama_zona,
            deskripsi,
            latitude,
            longitude,
            radius_meter,
            warna_hex,
            tingkat_risiko,
            tanggal_kejadian,
            waktu_kejadian,
            status_zona,
        } = req.body;

        if (!nama_zona || !latitude || !longitude || !radius_meter) {
            return res.status(400).json({
                success: false,
                message: "nama_zona, latitude, longitude, radius_meter wajib diisi",
            });
        }

        const id = await createZonaBahaya({
            id_laporan_sumber: id_laporan_sumber ? Number(id_laporan_sumber) : null,
            nama_zona,
            deskripsi,
            latitude,
            longitude,
            radius_meter,
            warna_hex,
            tingkat_risiko,
            tanggal_kejadian,
            waktu_kejadian,
            status_zona,
        });

        return res.status(201).json({
            success: true,
            message: "Zona bahaya berhasil ditambahkan",
            data: { id_zona: id },
        });
    } catch (err) {
        console.error("createZonaBahaya error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const updateZonaBahayaController = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            nama_zona,
            deskripsi,
            latitude,
            longitude,
            radius_meter,
            warna_hex,
            tingkat_risiko,
            tanggal_kejadian,
            waktu_kejadian,
            status_zona
        } = req.body;

        if (!nama_zona || !latitude || !longitude || !radius_meter) {
            return res.status(400).json({
                success: false,
                message: "nama_zona, latitude, longitude, radius_meter wajib diisi",
            });
        }

        const affected = await updateZonaBahaya(id, {
            nama_zona,
            deskripsi,
            latitude,
            longitude,
            radius_meter,
            warna_hex,
            tingkat_risiko,
            tanggal_kejadian,
            waktu_kejadian,
            status_zona,
        });

        if (!affected) {
            return res.status(404).json({
                success: false,
                message: "Zona bahaya tidak ditemukan",
            });
        }

        return res.json({
            success: true,
            message: "Zona bahaya berhasil diperbarui",
        });
    } catch (err) {
        console.error("updateZonaBahaya error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const updateZonaBahayaStatusController = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id, 10);
        const { status } = req.body;

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({
                success: false,
                message: "ID zona tidak valid",
            });
        }

        const allowedStatus = ["pending", "approve", "rejected"];
        if (!status || !allowedStatus.includes(status)) {
            return res.status(400).json({
                success: false,
                message: "Status harus salah satu dari: pending, approved, rejected",
            });
        }

        const affected = await updateZonaStatus(idZona, status);

        if (!affected) {
            return res.status(404).json({
                success: false,
                message: "Zona bahaya tidak ditemukan",
            });
        }

        return res.json({
            success: true,
            message: `Status zona berhasil diubah menjadi ${status}`,
        });
    } catch (err) {
        console.error("updateZonaBahayaStatusController error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const deleteZonaBahayaController = async (req, res) => {
    try {
        const { id } = req.params;

        const affected = await deleteZonaBahaya(id);
        if (!affected) {
            return res.status(404).json({
                success: false,
                message: "Zona bahaya tidak ditemukan",
            });
        }

        return res.json({
            success: true,
            message: "Zona bahaya berhasil dihapus",
        });
    } catch (err) {
        console.error("deleteZonaBahaya error:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

const getZonaBahayaVoteSummaryAdmin = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id, 10);

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({
                success: false,
                message: "ID zona tidak valid",
            });
        }

        const summary = await getVoteSummary(idZona);

        return res.json({
            success: true,
            message: "Berhasil mengambil ringkasan voting",
            data: summary,
        });
    } catch (err) {
        console.error("getZonaBahayaVoteSummaryAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal mengambil data voting",
            error: err.message,
        });
    }
};

const getZonaBahayaVotesAdmin = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id, 10);

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({
                success: false,
                message: "ID zona tidak valid",
            });
        }

        const votes = await getVotesWithUser(idZona);

        return res.json({
            success: true,
            message: "Berhasil mengambil daftar voting",
            data: votes,
        });
    } catch (err) {
        console.error("getZonaBahayaVotesAdmin error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal mengambil daftar voting",
            error: err.message,
        });
    }
};

module.exports = {
    listZonaBahaya,
    getZonaBahayaDetailAdmin,
    createZonaBahayaController,
    updateZonaBahayaController,
    updateZonaBahayaStatusController,
    deleteZonaBahayaController,
    getZonaBahayaVoteSummaryAdmin,
    getZonaBahayaVotesAdmin,
};