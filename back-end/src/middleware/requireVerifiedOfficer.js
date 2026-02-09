module.exports = (req, res, next) => {
    const role = req.user?.role;
    const status = req.user?.status_verifikasi;

    if (role !== "officer") {
        return res.status(403).json({ message: "Khusus officer" });
    }
    if (status !== "verified") {
        return res.status(403).json({ message: "Akun officer belum diverifikasi admin" });
    }
    next();
};
