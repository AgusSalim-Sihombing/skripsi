// src/controller/adminUserController.js
const bcrypt = require("bcrypt");
const userModel = require("../models/userModel");

// GET /api/admin/users
const listUsersAdmin = async (req, res) => {
  try {
    const { role, search, status_verifikasi } = req.query;

    const users = await userModel.getUsersAdmin({
      role: role || "",
      search: search || "",
      status_verifikasi: status_verifikasi || "",
    });

    return res.json({
      success: true,
      message: "Berhasil mengambil data user",
      data: users,
    });
  } catch (err) {
    console.error("listUsersAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Terjadi kesalahan saat mengambil data user",
    });
  }
};

// GET /api/admin/users/:id
const detailUserAdmin = async (req, res) => {
  try {
    const user = await userModel.getUserById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User tidak ditemukan",
      });
    }

    return res.json({
      success: true,
      data: user,
    });
  } catch (err) {
    console.error("detailUserAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Gagal mengambil detail user",
    });
  }
};

// POST /api/admin/users
// Admin bikin akun baru (bisa masyarakat / officer / admin)
const createUserAdmin = async (req, res) => {
  try {
    const {
      nik,
      nama,
      alamat,
      username,
      password,
      phone,
      tempat_lahir,
      tanggal_lahir,
      email,
      role = "masyarakat",
      status_verifikasi = "verified", // default: admin sudah verifikasi
      catatan_verifikasi,
    } = req.body;

    if (!nik || !nama || !username || !password) {
      return res.status(400).json({
        success: false,
        message: "NIK, nama, username, dan password wajib diisi",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUserData = {
      nik,
      nama,
      alamat: alamat || null,
      username,
      password: hashedPassword,
      phone,
      tempat_lahir,
      tanggal_lahir,
      email,
      role,
    };

    const id = await userModel.createUser(newUserData, null);

    // set status_verifikasi & catatan kalau dikirim
    await userModel.updateUserAdmin(id, {
      status_verifikasi,
      catatan_verifikasi: catatan_verifikasi || null,
    });

    return res.status(201).json({
      success: true,
      message: "User berhasil dibuat",
      data: { id },
    });
  } catch (err) {
    console.error("createUserAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Gagal membuat user",
    });
  }
};

// PUT /api/admin/users/:id
// Edit data user/officer, termasuk ganti role & verifikasi
const updateUserAdmin = async (req, res) => {
  try {
    const { id } = req.params;

    const {
      nik,
      nama,
      alamat,
      username,
      phone,
      tempat_lahir,
      tanggal_lahir,
      email,
      role,
      status_verifikasi,
      catatan_verifikasi,
      newPassword, // optional: kalau diisi → ganti password
    } = req.body;

    const updateData = {
      nik,
      nama,
      alamat,
      username,
      phone,
      tempat_lahir,
      tanggal_lahir,
      email,
      role,
      status_verifikasi,
      catatan_verifikasi,
    };

    if (newPassword && newPassword.trim() !== "") {
      updateData.password = await bcrypt.hash(newPassword, 10);
    }

    await userModel.updateUserAdmin(id, updateData);

    return res.json({
      success: true,
      message: "User berhasil diupdate",
    });
  } catch (err) {
    console.error("updateUserAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Gagal mengupdate user",
    });
  }
};

// DELETE /api/admin/users/:id
const deleteUserAdmin = async (req, res) => {
  try {
    await userModel.deleteUser(req.params.id);
    return res.json({
      success: true,
      message: "User berhasil dihapus",
    });
  } catch (err) {
    console.error("deleteUserAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Gagal menghapus user",
    });
  }
};

const fotoKtpUserAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await userModel.getUserById(id);

    if (!user || !user.ktp_image) {
      return res.status(404).json({
        success: false,
        message: "Foto KTP tidak ditemukan",
      });
    }

    res.setHeader("Content-Type", "image/jpeg");
    return res.send(user.ktp_image);
  } catch (err) {
    console.error("fotoKtpUserAdmin error:", err);
    return res.status(500).json({
      success: false,
      message: "Terjadi kesalahan saat mengambil foto KTP",
    });
  }
};

module.exports = {
  listUsersAdmin,
  detailUserAdmin,
  createUserAdmin,
  updateUserAdmin,
  deleteUserAdmin,
  fotoKtpUserAdmin,
};
