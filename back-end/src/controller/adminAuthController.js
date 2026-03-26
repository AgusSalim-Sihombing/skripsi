const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { findAdminByUsername } = require("../models/adminModel");
const { success } = require("../utils/response");

const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_sigap"; // isi di .env di production

// POST /api/admin/login
const loginAdmin = async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username && !password) {
            return res
                .status(400)
                .json({ success: false, message: "Username dan password wajib diisi" });
        }

        if (!username) {
            return res
                .status(400)
                .json({ success: false, message: "Username wajib diIsi" })
        } else if (!password) {
            return res
                .status(400)
                .json({ success: false, message: "Password wajib diisi" })
        }

        const admin = await findAdminByUsername(username);
        if (!admin) {
            return res
                .status(401)
                .json({ success: false, message: "Username atau password salah" });
        }

        const isMatch = await bcrypt.compare(password, admin.password_hash);
        if (!isMatch) {
            return res
                .status(401)
                .json({ success: false, message: "Username atau password salah" });
        }

        const token = jwt.sign(
            {
                id: admin.id,
                role: admin.role,
                username: admin.username,
            },
            JWT_SECRET,
            { expiresIn: "1d" }
        );

        return res.json({
            success: true,
            message: "Login berhasil",
            data: {
                token,
                admin: {
                    id: admin.id,
                    nama: admin.nama,
                    username: admin.username,
                    role: admin.role,
                },
            },
        });
    } catch (err) {
        console.error("Error login admin:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

module.exports = {
    loginAdmin,
};
