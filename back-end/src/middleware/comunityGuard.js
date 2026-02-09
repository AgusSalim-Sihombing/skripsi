// src/middlewares/communityGuard.js
const db = require("../config/database");

const mustCommunityActive = async (req, res, next) => {
    const communityId = req.params.id;
    const [rows] = await db.execute(
        "SELECT id, status, owner_user_id FROM communities WHERE id = ? LIMIT 1",
        [communityId]
    );
    if (rows.length === 0) return res.status(404).json({ message: "Komunitas tidak ditemukan" });
    if (rows[0].status !== "active") return res.status(403).json({ message: "Komunitas sedang ditakedown" });

    req.community = rows[0];
    next();
};

const mustMemberApproved = async (req, res, next) => {
    const communityId = req.params.id;
    const userId = req.user.id;

    const [rows] = await db.execute(
        "SELECT status, role FROM community_members WHERE community_id = ? AND user_id = ? LIMIT 1",
        [communityId, userId]
    );

    if (rows.length === 0 || rows[0].status !== "approved") {
        return res.status(403).json({ message: "Kamu belum jadi member approved" });
    }

    req.member = rows[0];
    next();
};

const mustOwner = async (req, res, next) => {
    const communityId = req.params.id;
    const userId = req.user.id;

    const [rows] = await db.execute(
        "SELECT role, status FROM community_members WHERE community_id = ? AND user_id = ? LIMIT 1",
        [communityId, userId]
    );

    if (rows.length === 0) return res.status(403).json({ message: "Bukan member" });
    if (rows[0].status !== "approved") return res.status(403).json({ message: "Status belum approved" });
    if (rows[0].role !== "owner") return res.status(403).json({ message: "Hanya owner" });

    next();
};

module.exports = { mustCommunityActive, mustMemberApproved, mustOwner };
