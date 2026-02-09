// src/controllers/communityPublicController.js
const db = require("../config/database");


const safeJsonParse = (v, fallback) => {
    try { return JSON.parse(v); } catch { return fallback; }
};

// 1) Lobby list
exports.listCommunities = async (req, res) => {
    try {

        const userId = req.user.id;
        const search = (req.query.search || "").trim();
        const page = Math.max(parseInt(req.query.page || "1", 10), 1);
        const limit = Math.min(Math.max(parseInt(req.query.limit || "20", 10), 1), 50);
        const offset = (page - 1) * limit;

        // tampilkan hanya active ke user (takedown disembunyiin)
        const [rows] = await db.execute(
            ` 
      SELECT
        c.id,
        c.name,
        c.owner_user_id,
        u.username AS owner_username,
        c.status,
        (SELECT COUNT(*) FROM community_members cm2
           WHERE cm2.community_id = c.id AND cm2.status = 'approved') AS member_count,
        COALESCE(cm.status, 'none') AS my_status,
        (SELECT m.message FROM community_messages m
           WHERE m.community_id = c.id AND m.is_deleted = 0
           ORDER BY m.created_at DESC LIMIT 1) AS last_message,
        (SELECT m.created_at FROM community_messages m
           WHERE m.community_id = c.id AND m.is_deleted = 0
           ORDER BY m.created_at DESC LIMIT 1) AS last_message_at
      FROM communities c
      JOIN user u ON u.id = c.owner_user_id
      LEFT JOIN community_members cm
        ON cm.community_id = c.id AND cm.user_id = ?
      WHERE c.status = 'active'
        AND c.name LIKE CONCAT('%', ?, '%')
      ORDER BY last_message_at DESC, c.created_at DESC
      LIMIT ? OFFSET ?;
      `,
            [userId, search, limit, offset]
        );

        const data = rows.map((r) => ({
            ...r,
            icon_url: `/api/public/communities/${r.id}/icon`,
        }));

        res.json({ page, limit, data });
    } catch (err) {
        res.status(500).json({ message: "Gagal mengambil communities", error: err.message });
    }
};

// 2) search users by username (verified masyarakat only)
exports.searchUsers = async (req, res) => {
    try {
        const q = (req.query.username || "").trim();
        if (!q) return res.json([]);

        const [rows] = await db.execute(
            `
      SELECT id, username, nama
      FROM user
      WHERE role='masyarakat'
        AND status_verifikasi='verified'
        AND username LIKE CONCAT('%', ?, '%')
      LIMIT 20
      `,
            [q]
        );

        res.json(rows);
    } catch (err) {
        res.status(500).json({ message: "Gagal search user", error: err.message });
    }
};

// 3) create community + invite members (multipart)
exports.createCommunity = async (req, res) => {
    let conn;
    try {
        const ownerId = req.user.id;
        const name = (req.body.name || "").trim();
        const membersRaw = req.body.members || "[]"; // JSON string ["user1","user2"]

        if (!name) return res.status(400).json({ message: "Nama grup wajib" });

        const usernames = safeJsonParse(membersRaw, [])
            .filter((x) => typeof x === "string")
            .map((x) => x.trim())
            .filter(Boolean);

        const iconBuffer = req.file ? req.file.buffer : null;
        const iconMime = req.file ? req.file.mimetype : null;
        const iconFilename = req.file ? req.file.originalname : null;

        conn = await db.getConnection();
        await conn.beginTransaction();

        // insert community
        const [ins] = await conn.execute(
            `
      INSERT INTO communities (name, icon, icon_mime, icon_filename, owner_user_id)
      VALUES (?, ?, ?, ?, ?)
      `,
            [name, iconBuffer, iconMime, iconFilename, ownerId]
        );

        const communityId = ins.insertId;

        // owner jadi member approved
        await conn.execute(
            `
      INSERT INTO community_members (community_id, user_id, role, status, joined_at)
      VALUES (?, ?, 'owner', 'approved', NOW())
      `,
            [communityId, ownerId]
        );

        // invite member by username (yang verified)
        if (usernames.length > 0) {
            const placeholders = usernames.map(() => "?").join(",");
            const [urows] = await conn.execute(
                `
        SELECT id, username FROM user
        WHERE role='masyarakat' AND status_verifikasi='verified'
          AND username IN (${placeholders})
        `,
                usernames
            );

            for (const u of urows) {
                if (u.id === ownerId) continue;

                await conn.execute(
                    `
          INSERT INTO community_members (community_id, user_id, role, status, requested_at)
          VALUES (?, ?, 'member', 'invited', NOW())
          ON DUPLICATE KEY UPDATE
            status='invited',
            requested_at=NOW(),
            responded_at=NULL,
            joined_at=NULL
          `,
                    [communityId, u.id]
                );
            }
        }

        await conn.commit();
        conn.release();

        res.status(201).json({ message: "Komunitas berhasil dibuat", communityId });
    } catch (err) {
        if (conn) {
            try { await conn.rollback(); conn.release(); } catch { }
        }
        res.status(500).json({ message: "Gagal create komunitas", error: err.message });
    }
};

// 4) get icon blob
exports.getCommunityIcon = async (req, res) => {
    try {
        const communityId = req.params.id;
        const [rows] = await db.execute(
            "SELECT icon, icon_mime FROM communities WHERE id = ? LIMIT 1",
            [communityId]
        );
        if (rows.length === 0) return res.status(404).end();

        const icon = rows[0].icon;
        if (!icon) return res.status(404).end();

        res.setHeader("Content-Type", rows[0].icon_mime || "image/jpeg");
        res.send(icon);
    } catch (err) {
        res.status(500).end();
    }
};

// 5) join request
exports.requestJoin = async (req, res) => {
    try {
        const communityId = req.params.id;
        const userId = req.user.id;

        // kalau owner ya skip
        const [ownerCheck] = await db.execute(
            "SELECT owner_user_id FROM communities WHERE id=? LIMIT 1",
            [communityId]
        );
        if (ownerCheck.length === 0) return res.status(404).json({ message: "Komunitas tidak ada" });
        if (ownerCheck[0].owner_user_id === userId) {
            return res.status(400).json({ message: "Kamu owner grup ini" });
        }

        // upsert ke pending_join (kecuali banned)
        const [current] = await db.execute(
            "SELECT status FROM community_members WHERE community_id=? AND user_id=? LIMIT 1",
            [communityId, userId]
        );

        if (current.length && current[0].status === "banned") {
            return res.status(403).json({ message: "Kamu dibanned dari grup ini" });
        }

        await db.execute(
            `
      INSERT INTO community_members (community_id, user_id, role, status, requested_at)
      VALUES (?, ?, 'member', 'pending_join', NOW())
      ON DUPLICATE KEY UPDATE
        status = CASE
          WHEN status IN ('approved','invited') THEN status
          ELSE 'pending_join'
        END,
        requested_at = NOW()
      `,
            [communityId, userId]
        );

        res.json({ message: "Request join terkirim" });
    } catch (err) {
        res.status(500).json({ message: "Gagal request join", error: err.message });
    }
};

// 6) accept invite
exports.acceptInvite = async (req, res) => {
    try {
        const communityId = req.params.id;
        const userId = req.user.id;

        const [rows] = await db.execute(
            "SELECT status FROM community_members WHERE community_id=? AND user_id=? LIMIT 1",
            [communityId, userId]
        );

        if (!rows.length || rows[0].status !== "invited") {
            return res.status(400).json({ message: "Tidak ada undangan" });
        }

        await db.execute(
            `
      UPDATE community_members
      SET status='approved', responded_at=NOW(), joined_at=NOW()
      WHERE community_id=? AND user_id=?
      `,
            [communityId, userId]
        );

        res.json({ message: "Invite diterima" });
    } catch (err) {
        res.status(500).json({ message: "Gagal accept invite", error: err.message });
    }
};

// 7) decline invite
exports.declineInvite = async (req, res) => {
    try {
        const communityId = req.params.id;
        const userId = req.user.id;

        await db.execute(
            `
      UPDATE community_members
      SET status='rejected', responded_at=NOW()
      WHERE community_id=? AND user_id=? AND status='invited'
      `,
            [communityId, userId]
        );

        res.json({ message: "Invite ditolak" });
    } catch (err) {
        res.status(500).json({ message: "Gagal decline invite", error: err.message });
    }
};

// 8) owner: list join requests
exports.listJoinRequests = async (req, res) => {
    try {
        const communityId = req.params.id;
        const [rows] = await db.execute(
            `
      SELECT cm.user_id, u.username, u.nama, cm.requested_at
      FROM community_members cm
      JOIN user u ON u.id = cm.user_id
      WHERE cm.community_id=? AND cm.status='pending_join'
      ORDER BY cm.requested_at ASC
      `,
            [communityId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ message: "Gagal ambil request", error: err.message });
    }
};

// 9) owner: approve / reject request
exports.respondJoinRequest = async (req, res) => {
    try {
        const communityId = req.params.id;
        const targetUserId = req.params.userId;
        const action = (req.body.action || "").toLowerCase();

        if (!["approve", "reject"].includes(action)) {
            return res.status(400).json({ message: "action harus approve/reject" });
        }

        if (action === "approve") {
            await db.execute(
                `
        UPDATE community_members
        SET status='approved', responded_at=NOW(), joined_at=NOW()
        WHERE community_id=? AND user_id=? AND status='pending_join'
        `,
                [communityId, targetUserId]
            );
            return res.json({ message: "User di-approve" });
        }

        await db.execute(
            `
      UPDATE community_members
      SET status='rejected', responded_at=NOW()
      WHERE community_id=? AND user_id=? AND status='pending_join'
      `,
            [communityId, targetUserId]
        );
        res.json({ message: "User ditolak" });
    } catch (err) {
        res.status(500).json({ message: "Gagal respond request", error: err.message });
    }
};

// 10) owner: invite members setelah grup jadi
exports.inviteMembers = async (req, res) => {
    try {
        const communityId = req.params.id;
        const usernames = Array.isArray(req.body.usernames) ? req.body.usernames : [];

        const clean = usernames
            .filter((x) => typeof x === "string")
            .map((x) => x.trim())
            .filter(Boolean);

        if (clean.length === 0) return res.status(400).json({ message: "usernames kosong" });

        const placeholders = clean.map(() => "?").join(",");
        const [urows] = await db.execute(
            `
      SELECT id, username FROM user
      WHERE role='masyarakat' AND status_verifikasi='verified'
        AND username IN (${placeholders})
      `,
            clean
        );

        for (const u of urows) {
            if (u.id === req.user.id) continue;
            await db.execute(
                `
        INSERT INTO community_members (community_id, user_id, role, status, requested_at)
        VALUES (?, ?, 'member', 'invited', NOW())
        ON DUPLICATE KEY UPDATE
          status = CASE
            WHEN status='banned' THEN 'banned'
            WHEN status='approved' THEN 'approved'
            ELSE 'invited'
          END,
          requested_at=NOW(),
          responded_at=NULL
        `,
                [communityId, u.id]
            );
        }

        res.json({ message: "Invite terkirim", invited: urows.length });
    } catch (err) {
        res.status(500).json({ message: "Gagal invite", error: err.message });
    }
};

// 11) get messages (pagination)
exports.getMessages = async (req, res) => {
    try {
        const communityId = req.params.id;
        const limit = Math.min(Math.max(parseInt(req.query.limit || "50", 10), 1), 100);
        const before = req.query.before || null; // ISO time (optional)

        let sql = `
      SELECT m.id, m.sender_user_id, u.username, m.message, m.created_at, m.is_deleted
      FROM community_messages m
      JOIN user u ON u.id = m.sender_user_id
      WHERE m.community_id=?
    `;
        const params = [communityId];

        if (before) {
            sql += " AND m.created_at < ? ";
            params.push(before);
        }

        sql += " ORDER BY m.created_at DESC LIMIT ? ";
        params.push(limit);

        const [rows] = await db.execute(sql, params);

        // balikkan ascending biar gampang render chat
        res.json(rows.reverse());
    } catch (err) {
        res.status(500).json({ message: "Gagal ambil chat", error: err.message });
    }
};

// 12) send message
exports.sendMessage = async (req, res) => {
    try {
        const communityId = Number(req.params.id);
        const text = (req.body.message || "").trim();

        if (!text) {
            return res.status(400).json({ message: "Pesan tidak boleh kosong" });
        }

        // ✅ INSERT ke DB (sesuaikan nama tabel/kolom kamu)
        const [ins] = await db.execute(
            `INSERT INTO community_messages (community_id, sender_user_id, message)
       VALUES (?, ?, ?)`,
            [communityId, req.user.id, text]
        );

        const insertedId = ins.insertId;

        // ✅ ambil io DI DALAM handler
        const io = req.app.get("io");

        // ✅ emit realtime (kalau io ada)
        if (io) {
            io.to(`community:${communityId}`).emit("community:message", {
                id: insertedId,
                communityId,
                sender_user_id: req.user.id,
                username: req.user.username,
                message: text,
                created_at: new Date().toISOString(),
            });
        }

        return res.status(201).json({ message: "Terkirim", id: insertedId });
    } catch (err) {
        return res.status(500).json({ message: "Gagal kirim pesan", error: err.message });
    }
};
// 13) owner: get member list                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   