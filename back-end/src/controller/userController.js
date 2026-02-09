const userModel = require("../models/userModel");
const officerAppModel = require("../models/officerApplicationModel");
const db = require("../config/database");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { success, error } = require("../utils/response");

const USER_JWT_SECRET = process.env.USER_JWT_SECRET || "user-secret-dev";


// ========== GET ALL ==========
const getAllUsers = async (req, res) => {
  try {
    const users = await userModel.getAllUsers();
    success(res, users);
  } catch (err) {
    error(res, err.message);
  }
};

// ========== GET BY ID ==========
const getUserById = async (req, res) => {
  try {
    const user = await userModel.getUserById(req.params.id);
    if (!user) return error(res, "User not found", 404);
    success(res, user);
  } catch (err) {
    error(res, err.message);
  }
};

const getFileBuffer = (files, fieldName) => {
  if (!files) return null;
  const arr = files[fieldName];
  if (arr && arr[0] && arr[0].buffer) return arr[0].buffer;
  return null;
};

const createUser = async (req, res) => {
  try {
    console.log("[/register] body:", req.body);
    console.log("[/register] files:", req.files);

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
      role_request, // 'masyarakat' / 'officer'
      nrp,
      pangkat,
      satuan,
    } = req.body;

    if (!nik || !nama || !username || !password) {
      return res
        .status(400)
        .json({ message: "Field wajib masih ada yang kosong" });
    }

    // hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // KTP image (dari upload.fields atau single)
    let ktpBuffer = getFileBuffer(req.files, "ktp_image");
    if (!ktpBuffer && req.file) {
      // fallback kalau masih pakai upload.single
      ktpBuffer = req.file.buffer;
    }

    // bukti officer (opsional)
    const buktiOfficerBuffer = getFileBuffer(req.files, "bukti_officer");

    // semua user baru default role 'masyarakat'
    const baseRole = "masyarakat";

    const newUserData = {
      nik,
      nama,
      alamat,
      username,
      password: hashedPassword,
      phone,
      tempat_lahir,
      tanggal_lahir,
      email,
      role: baseRole,
    };

    // 1) simpan user
    const userId = await userModel.createUser(newUserData, ktpBuffer);

    // 2) kalau dia daftar sebagai officer → simpan ke officer_applications
    if (role_request === "officer") {
      await officerAppModel.createOfficerApplication(
        userId,
        { nrp, pangkat, satuan },
        buktiOfficerBuffer
      );
    }

    return res.status(201).json({
      success: true,
      message:
        role_request === "officer"
          ? "Registrasi berhasil. Pengajuan officer akan direview admin."
          : "User created successfully",
      data: {
        id: userId,
        role: baseRole,
        role_request: role_request || "masyarakat",
      },
    });
  } catch (err) {
    console.error("[/register] error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ========== UPDATE ==========
const updateUser = async (req, res) => {
  try {
    await userModel.updateUser(req.params.id, req.body);
    success(res, null, "User updated successfully");
  } catch (err) {
    error(res, err.message);
  }
};

// ========== DELETE ==========
const deleteUser = async (req, res) => {
  try {
    await userModel.deleteUser(req.params.id);
    success(res, null, "User deleted successfully");
  } catch (err) {
    error(res, err.message);
  }
};


// ========== LOGIN (mobile) ==========
const loginUser = async (req, res) => {
  try {
    const { username, password } = req.body;

    console.log("[loginUser] body:", req.body);

    if (!username || !password) {
      return res
        .status(400)
        .json({ message: "Username dan password wajib diisi" });
    }

    const [rows] = await db.execute(
      "SELECT * FROM user WHERE username = ?",
      [username]
    );

    console.log("[loginUser] rows:", rows);

    if (rows.length === 0) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const user = rows[0];

    // ====== CEK PASSWORD (hash / plain) ======
    let isValid = false;
    if (user.password && user.password.startsWith("$2b$")) {
      isValid = await bcrypt.compare(password, user.password);
    } else {
      isValid = user.password === password;
    }

    if (!isValid) {
      console.log(
        "[loginUser] password mismatch. input:",
        password,
        "stored:",
        user.password
      );
      return res.status(401).json({ message: "Password salah" });
    }

    // ====== GENERATE JWT (PAKAI ROLE) ======
    const payload = {
      id: user.id,
      username: user.username,
      role: user.role || "masyarakat",
      status_verifikasi: user.status_verifikasi || "pending",
    };

    const token = jwt.sign(payload, USER_JWT_SECRET, {
      expiresIn: "7d",
    });

    return res.json({
      message: "Login berhasil",
      token,
      user: {
        id: user.id,
        username: user.username,
        nama: user.nama,
        nik: user.nik,
        phone: user.phone,
        email: user.email,
        role: user.role || "masyarakat",
        status_verifikasi: user.status_verifikasi || "pending",
      },
    });
  } catch (err) {
    console.error("[loginUser] error:", err);
    return res.status(500).json({ message: err.message });
  }
};



module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  loginUser,
};

