// src/routes/adminUserRoute.js
const express = require("express");
const router = express.Router();

const authAdmin = require("../middleware/authAdmin");
const {
  listUsersAdmin,
  detailUserAdmin,
  createUserAdmin,
  updateUserAdmin,
  deleteUserAdmin,
  fotoKtpUserAdmin,
  takedownUserAdmin,
  restoreUserAdmin
} = require("../controller/adminUserController");

// prefix global: /api/admin (lihat index.js)
router.get("/users", authAdmin, listUsersAdmin);
router.get("/users/:id", authAdmin, detailUserAdmin);
router.post("/users", authAdmin, createUserAdmin);
router.put("/users/:id", authAdmin, updateUserAdmin);
router.delete("/users/:id", authAdmin, deleteUserAdmin);
router.get("/users/:id/ktp", fotoKtpUserAdmin);
router.patch("/users/:id/takedown", authAdmin, takedownUserAdmin);
router.patch("/users/:id/restore", authAdmin, restoreUserAdmin);


module.exports = router;
