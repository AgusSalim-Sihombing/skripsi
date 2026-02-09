
const express = require("express");
const router = express.Router();
const testingController = require("../controller/testingController");
// const uploadKtp = require("../middleware/uploadKtp");
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });


router.post("/testing-upload", upload.single("gambar"), testingController.addImage);

module.exports = router;