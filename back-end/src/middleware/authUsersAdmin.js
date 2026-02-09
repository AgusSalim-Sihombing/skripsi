// src/middlewares/auth.js
const jwt = require("jsonwebtoken");
const db = require("../config/database");

const requireAuth = async (req, res, next) => {
    try {
        const h = req.headers.authorization || "";
        const token = h.startsWith("Bearer ") ? h.slice(7) : null;
        if (!token) return res.status(401).json({ message: "Token tidak ada" });

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        // minimal harus ada userId
        const userId = decoded.id || decoded.userId;
        if (!userId) return res.status(401).json({ message: "Token invalid" });

        // ambil role + status terbaru dari DB (biar aman)
        const [rows] = await db.execute(
            "SELECT id, username, role, status_verifikasi FROM users WHERE id = ? LIMIT 1",
            [userId]
        );
        if (rows.length === 0) return res.status(401).json({ message: "User tidak ditemukan" });

        req.user = rows[0];
        next();
    } catch (err) {
        return res.status(401).json({ message: "Unauthorized", error: err.message });
    }
};

const requireRole = (role) => (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: "Unauthorized" });
    if (req.user.role !== role) return res.status(403).json({ message: "Forbidden" });
    next();
};

// khusus masyarakat verified
const requireVerifiedMasyarakat = (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: "Unauthorized" });

    if (req.user.role !== "masyarakat") {
        return res.status(403).json({ message: "Khusus masyarakat" });
    }

    if (req.user.status_verifikasi !== "verified") {
        return res.status(403).json({ message: "Akun belum diverifikasi" });
    }

    next();
};




module.exports = { requireAuth, requireRole, requireVerifiedMasyarakat };
