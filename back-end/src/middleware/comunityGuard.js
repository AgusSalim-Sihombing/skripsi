// src/middlewares/communityGuard.js
const db = require("../config/database");

const mustCommunityActive = async (req, res, next) => {
  try {
    const communityId = Number(req.params.id);

    if (!communityId) {
      return res.status(400).json({
        success: false,
        message: "ID komunitas tidak valid",
      });
    }

    const [rows] = await db.execute(
      `
      SELECT id, name, status, takedown_reason
      FROM communities
      WHERE id = ?
      LIMIT 1
      `,
      [communityId]
    );

    if (!rows.length) {
      return res.status(404).json({
        success: false,
        message: "Komunitas tidak ditemukan",
      });
    }

    const community = rows[0];
    req.community = community;

    if (community.status !== "active") {
      return res.status(403).json({
        success: false,
        code: "COMMUNITY_TAKEDOWN",
        message: "Komunitas ini sedang dinonaktifkan oleh admin",
        community_status: community.status,
        takedown_reason: community.takedown_reason || "Tidak ada alasan",
      });
    }

    next();
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Gagal memeriksa status komunitas",
      error: err.message,
    });
  }
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
