// const jwt = require("jsonwebtoken");

// // 🔥 HARUS SAMA DENGAN DI userController.js
// const USER_JWT_SECRET = process.env.USER_JWT_SECRET || "dev_user_secret_123";

// const authUser = (req, res, next) => {
//     try {
//         const authHeader = req.headers.authorization || req.headers.Authorization;

//         if (!authHeader) {
//             return res.status(401).json({ message: "Token tidak ditemukan" });
//         }

//         const parts = authHeader.split(" ");
//         if (parts.length !== 2 || parts[0] !== "Bearer") {
//             return res.status(401).json({ message: "Format token tidak valid" });
//         }

//         const token = parts[1];

//         const decoded = jwt.verify(token, USER_JWT_SECRET);
//         // decoded: { id, username, role, iat, exp }
//         req.user = decoded;

//         next();
//     } catch (err) {
//         console.error("[authUser] error:", err);
//         return res.status(401).json({ message: "Token tidak valid" });
//     }
// };

// module.exports = authUser;

// src/middleware/authUser.js
const jwt = require("jsonwebtoken");

const USER_JWT_SECRET = process.env.USER_JWT_SECRET || "user-secret-dev";

const authUser = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization || req.headers.Authorization;

        if (!authHeader) {
            return res.status(401).json({ message: "Token tidak ditemukan" });
        }

        const parts = authHeader.split(" ");
        if (parts.length !== 2 || parts[0] !== "Bearer") {
            return res.status(401).json({ message: "Format token tidak valid" });
        }

        const token = parts[1];

        const decoded = jwt.verify(token, USER_JWT_SECRET);
        // decoded: { id, username, role, iat, exp }
        req.user = decoded;

        next();
    } catch (err) {
        console.error("[authUser] error:", err);
        return res.status(401).json({ message: "Token tidak valid" });
    }
};

module.exports = authUser;
