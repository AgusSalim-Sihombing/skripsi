// src/middleware/uploadLaporanCepatFoto.js
const multer = require("multer");

const storage = multer.memoryStorage();

const uploadLaporanCepatFoto = multer({
    storage,
    limits: {
        fileSize: 5 * 1024 * 1024, // max 5MB, bebas sesuaikan
    },
}).single("foto"); // field name: 'foto'

module.exports = uploadLaporanCepatFoto;
