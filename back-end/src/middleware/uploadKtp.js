const multer = require("multer");

const storage = multer.memoryStorage(); // ⬅️ file ada di req.file.buffer
const uploadKtp = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // max 5MB
  },
});

module.exports = uploadKtp;
