// src/middleware/requireRole.js
const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        const user = req.user;

        if (!user || !user.role) {
            return res
                .status(403)
                .json({ message: "Role pengguna tidak ditemukan pada token" });
        }

        if (!allowedRoles.includes(user.role)) {
            return res
                .status(403)
                .json({ message: "Akses ditolak untuk role ini" });
        }

        next();
    };
};

module.exports = requireRole;
