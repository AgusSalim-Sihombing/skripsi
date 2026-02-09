// src/models/officerApplicationModel.js
const db = require("../config/database");

// bikin pengajuan officer baru
const createOfficerApplication = async (userId, data, buktiBuffer) => {
    const { nrp, pangkat, satuan } = data;

    const [result] = await db.execute(
        `INSERT INTO officer_applications
       (user_id, nrp, pangkat, satuan, bukti_image, status)
     VALUES (?, ?, ?, ?, ?, 'pending')`,
        [
            userId,
            nrp || null,
            pangkat || null,
            satuan || null,
            buktiBuffer || null,
        ]
    );

    return result.insertId;
};

// kalau nanti perlu cek status pengajuan per user
const getOfficerApplicationByUserId = async (userId) => {
    const [rows] = await db.execute(
        "SELECT * FROM officer_applications WHERE user_id = ? LIMIT 1",
        [userId]
    );
    return rows[0] || null;
};

module.exports = {
    createOfficerApplication,
    getOfficerApplicationByUserId,
};
