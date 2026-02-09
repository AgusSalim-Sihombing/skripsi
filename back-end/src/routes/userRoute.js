

// src/routes/userRoute.js
const express = require("express");
const router = express.Router();
const userController = require("../controller/userController");

const multer = require("multer");
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
});

// GET semua user
router.get("/", userController.getAllUsers);

// GET user berdasarkan ID
router.get("/:id", userController.getUserById);

// REGISTER user + upload foto KTP + (opsional) bukti officer
// field file dari Flutter:
//  - "ktp_image"       → wajib (identitas)
//  - "bukti_officer"   → opsional, kalau role_request = 'officer'
router.post(
    "/register",
    upload.fields([
        { name: "ktp_image", maxCount: 1 },
        { name: "bukti_officer", maxCount: 1 },
    ]),
    userController.createUser
);

// PUT update user
router.put("/:id", userController.updateUser);

// DELETE hapus user
router.delete("/:id", userController.deleteUser);

// LOGIN (mobile)
router.post("/login", userController.loginUser);

module.exports = router;
