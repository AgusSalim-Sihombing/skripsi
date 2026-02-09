const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_sigap";

const authAdmin = (req, res, next) => {
    const authHeader = req.headers["authorization"];

    if (!authHeader) {
        return res
            .status(401)
            .json({ success: false, message: "Token tidak ditemukan" });
    }

    const token = authHeader.split(" ")[1]; // "Bearer token"

    if (!token) {
        return res
            .status(401)
            .json({ success: false, message: "Token tidak valid" });
    }

    try {   
        const decoded = jwt.verify(token, JWT_SECRET);
        req.admin = decoded; // { id, role, username }
        next();
    } catch (err) {
        console.error("JWT error:", err);
        return res
            .status(401)
            .json({ success: false, message: "Token tidak valid / kadaluarsa" });
    }
};

module.exports = authAdmin;
