const express = require("express");
const router = express.Router();
const userController = require("../controller/userController");

// GET semua user
router.get("/", userController.getAllUsers);

// GET user berdasarkan ID
router.get("/:id", userController.getUserById);

// POST tambah user
router.post("/", userController.createUser);

// PUT update user
router.put("/:id", userController.updateUser);

// DELETE hapus user
router.delete("/:id", userController.deleteUser);

router.post("/login", userController.loginUser);

module.exports = router;
