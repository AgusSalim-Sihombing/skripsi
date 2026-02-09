// src/controllers/communityAdminController.js
const db = require("../config/database");

exports.listAllCommunities = async (req, res) => {
  try {
    const search = (req.query.search || "").trim();
    const status = (req.query.status || "").trim(); // active/takedown
    const page = Math.max(parseInt(req.query.page || "1", 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || "20", 10), 1), 50);
    const offset = (page - 1) * limit;

    let where = "WHERE c.name LIKE CONCAT('%', ?, '%')";
    const params = [search];

    if (status === "active" || status === "takedown") {
      where += " AND c.status = ? ";
      params.push(status);
    }

    const [rows] = await db.execute(
      `
      SELECT
        c.id, c.name, c.status, c.takedown_reason,
        c.owner_user_id, u.username AS owner_username,
        (SELECT COUNT(*) FROM community_members cm2
          WHERE cm2.community_id=c.id AND cm2.status='approved') AS member_count,
        (SELECT m.created_at FROM community_messages m
          WHERE m.community_id=c.id ORDER BY m.created_at DESC LIMIT 1) AS last_message_at
      FROM communities c
      JOIN user u ON u.id=c.owner_user_id
      ${where}
      ORDER BY last_message_at DESC, c.created_at DESC
      LIMIT ? OFFSET ?
      `,
      [...params, limit, offset]
    );

    res.json({ page, limit, data: rows });
  } catch (err) {
    res.status(500).json({ message: "Gagal list komunitas", error: err.message });
  }
};

exports.getCommunityMessages = async (req, res) => {
  try {
    const communityId = req.params.id;
    const page = Math.max(parseInt(req.query.page || "1", 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || "50", 10), 1), 200);
    const offset = (page - 1) * limit;

    const [rows] = await db.execute(
      `
      SELECT m.id, m.community_id, m.sender_user_id, u.username, m.message, m.created_at,
             m.is_deleted, m.deleted_by, m.deleted_reason, m.deleted_at
      FROM community_messages m
      JOIN user u ON u.id=m.sender_user_id
      WHERE m.community_id=?
      ORDER BY m.created_at DESC
      LIMIT ? OFFSET ?
      `,
      [communityId, limit, offset]
    );

    res.json({ page, limit, data: rows });
  } catch (err) {
    res.status(500).json({ message: "Gagal ambil chat admin", error: err.message });
  }
};

exports.takedownCommunity = async (req, res) => {
  let conn;
  try {
    const communityId = req.params.id;
    const reason = (req.body.reason || "").trim() || "Pelanggaran aturan";

    conn = await db.getConnection();
    await conn.beginTransaction();

    await conn.execute(
      "UPDATE communities SET status='takedown', takedown_reason=? WHERE id=?",
      [reason, communityId]
    );

    await conn.execute(
      `
      INSERT INTO community_moderation_logs (admin_id, action, community_id, reason)
      VALUES (?, 'takedown_community', ?, ?)
      `,
      [req.user.id, communityId, reason]
    );

    await conn.commit();
    conn.release();

    res.json({ message: "Komunitas ditakedown" });
  } catch (err) {
    if (conn) { try { await conn.rollback(); conn.release(); } catch { } }
    res.status(500).json({ message: "Gagal takedown", error: err.message });
  }
};

exports.restoreCommunity = async (req, res) => {
  let conn;
  try {
    const communityId = req.params.id;

    conn = await db.getConnection();
    await conn.beginTransaction();

    await conn.execute(
      "UPDATE communities SET status='active', takedown_reason=NULL WHERE id=?",
      [communityId]
    );

    await conn.execute(
      `
      INSERT INTO community_moderation_logs (admin_id, action, community_id)
      VALUES (?, 'restore_community', ?)
      `,
      [req.user.id, communityId]
    );

    await conn.commit();
    conn.release();

    res.json({ message: "Komunitas direstore" });
  } catch (err) {
    if (conn) { try { await conn.rollback(); conn.release(); } catch { } }
    res.status(500).json({ message: "Gagal restore", error: err.message });
  }
};

exports.deleteMessage = async (req, res) => {
  let conn;
  try {
    const messageId = req.params.messageId;
    const reason = (req.body.reason || "").trim() || "Melanggar aturan";

    conn = await db.getConnection();
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      "SELECT community_id FROM community_messages WHERE id=? LIMIT 1",
      [messageId]
    );
    if (!rows.length) {
      await conn.rollback(); conn.release();
      return res.status(404).json({ message: "Message tidak ditemukan" });
    }

    await conn.execute(
      `
      UPDATE community_messages
      SET is_deleted=1, deleted_by='admin', deleted_reason=?, deleted_at=NOW()
      WHERE id=?
      `,
      [reason, messageId]
    );

    await conn.execute(
      `
      INSERT INTO community_moderation_logs (admin_id, action, community_id, message_id, reason)
      VALUES (?, 'delete_message', ?, ?, ?)
      `,
      [req.user.id, rows[0].community_id, messageId, reason]
    );

    await conn.commit();
    conn.release();

    res.json({ message: "Message dihapus admin" });
  } catch (err) {
    if (conn) { try { await conn.rollback(); conn.release(); } catch { } }
    res.status(500).json({ message: "Gagal delete message", error: err.message });
  }
};

exports.getCommunityDetail = async (req, res) => {
  try {
    const communityId = req.params.id;

    const [rows] = await db.execute(
      `
      SELECT
        c.id, c.name, c.status, c.takedown_reason,
        c.owner_user_id, u.username AS owner_username,
        (SELECT COUNT(*) FROM community_members cm2
          WHERE cm2.community_id=c.id AND cm2.status='approved') AS member_count,
        (SELECT m.created_at FROM community_messages m
          WHERE m.community_id=c.id ORDER BY m.created_at DESC LIMIT 1) AS last_message_at
      FROM communities c
      JOIN user u ON u.id=c.owner_user_id
      WHERE c.id=?
      LIMIT 1
      `,
      [communityId]
    );

    if (!rows.length) return res.status(404).json({ message: "Komunitas tidak ditemukan" });

    return res.json({ data: rows[0] });
  } catch (err) {
    return res.status(500).json({ message: "Gagal ambil detail komunitas", error: err.message });
  }
};



