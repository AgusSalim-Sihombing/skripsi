const express = require("express");
const router = express.Router();
const authUser = require("../middleware/authUser");

const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

const C = require("../controller/mobile/profleController");

// ambil profil sendiri
router.get("/me", authUser, C.me);

// update profil sendiri (tanpa file)
router.put("/me", authUser, C.updateMe);

// ambil foto ktp sendiri (bytes)
router.get("/me/ktp", authUser, C.getMyKtpImage);

// upload ulang ktp (khusus rejected)
router.post("/me/ktp", authUser, upload.single("ktp_image"), C.resubmitKtp);

// (opsional) foto profil
router.get("/me/foto", authUser, C.getMyFoto);
router.post("/me/foto", authUser, upload.single("foto"), C.uploadFoto);

module.exports = router;
