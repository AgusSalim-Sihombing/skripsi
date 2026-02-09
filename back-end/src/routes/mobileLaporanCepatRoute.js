// src/routes/mobileLaporanCepatRoute.js
const express = require("express");
const router = express.Router();
const authUser = require("../middleware/authUser");
const uploadLaporanCepatFoto = require("../middleware/uploadLaporanCepatFoto");
const { createLaporanCepatMobile, getMyLaporanCepatMobile, } = require("../controller/mobile/laporanCepatMobileController");

// middleware auth user (kalau sudah ada)
// const authUser = require("../middleware/authUser");

// kalau sudah ada authUser:
router.post(
    "/laporan-cepat",
    authUser,           // ⬅️ sekarang akan pakai token dari loginUser
    uploadLaporanCepatFoto,
    createLaporanCepatMobile
);
router.get("/laporan-cepat/me", authUser, getMyLaporanCepatMobile);

// kalau BELUM ada authUser, sementara bisa:
//// router.post("/laporan-cepat", uploadLaporanCepatFoto, createLaporanCepatMobile);

module.exports = router;
