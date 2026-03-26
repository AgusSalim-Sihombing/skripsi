// src/routes/adminLaporanRoute.js
const express = require("express");
const router = express.Router();

// middleware auth admin
const authAdmin = require("../middleware/authAdmin");

const {
    listLaporanAdmin,
    detailLaporanAdmin,
    listLaporanForZona,
    approveLaporanAdmin,
    rejectLaporanAdmin,
    fotoLaporanAdmin,
    deleteLaporanAdmin,
} = require("../controller/laporanCepatAdminController");

router.get("/laporan-cepat", authAdmin, listLaporanAdmin);
router.get("/laporan-cepat/for-zona", authAdmin, listLaporanForZona);
router.get("/laporan-cepat/:id", authAdmin, detailLaporanAdmin);
router.post("/laporan-cepat/:id/approve", authAdmin, approveLaporanAdmin);
router.post("/laporan-cepat/:id/reject", authAdmin, rejectLaporanAdmin);
router.get("/laporan-cepat/:id/foto", fotoLaporanAdmin);
router.delete("/laporan-cepat/:id", authAdmin, deleteLaporanAdmin);

module.exports = router;
