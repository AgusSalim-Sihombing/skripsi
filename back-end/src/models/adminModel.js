const db = require("../config/database");

// cari admin berdasarkan username
const findAdminByUsername = async (username) => {
    const [rows] = await db.execute(
        "SELECT * FROM admin_users WHERE username = ? LIMIT 1",
        [username]
    );
    return rows[0];
};

// opsional: buat admin baru (buat seeding lewat API)
const createAdmin = async ({ nama, username, passwordHash, role = "admin" }) => {
    const [result] = await db.execute(
        "INSERT INTO admin_users (nama, username, password_hash, role) VALUES (?, ?, ?, ?)",
        [nama, username, passwordHash, role]
    );
    return result.insertId;
};

module.exports = {
    findAdminByUsername,
    createAdmin,
};
