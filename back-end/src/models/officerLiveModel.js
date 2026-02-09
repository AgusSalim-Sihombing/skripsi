const db = require("../config/database");

const upsertOfficerLive = async (userId, isOnDuty, lat, lng) => {
    await db.execute(
        `INSERT INTO officer_live (user_id, is_on_duty, last_lat, last_lng, last_loc_updated_at)
     VALUES (?, ?, ?, ?, NOW())
     ON DUPLICATE KEY UPDATE
       is_on_duty = VALUES(is_on_duty),
       last_lat = VALUES(last_lat),
       last_lng = VALUES(last_lng),
       last_loc_updated_at = NOW(),
       -- kalau off duty, reset busy biar gak nyangkut
       is_busy = IF(VALUES(is_on_duty)=0, 0, is_busy),
       current_panic_id = IF(VALUES(is_on_duty)=0, NULL, current_panic_id),
       busy_since = IF(VALUES(is_on_duty)=0, NULL, busy_since)`,
        [userId, isOnDuty ? 1 : 0, lat, lng]
    );
};

// ✅ UPSERT biar gak gagal kalau row officer_live belum ada
const setOfficerBusy = async (userId, isBusy, panicId) => {
    await db.execute(
        `INSERT INTO officer_live (user_id, is_on_duty, is_busy, current_panic_id, busy_since, last_loc_updated_at)
     VALUES (?, 1, ?, ?, IF(?, NOW(), NULL), NOW())
     ON DUPLICATE KEY UPDATE
       is_busy = VALUES(is_busy),
       current_panic_id = VALUES(current_panic_id),
       busy_since = VALUES(busy_since)`,
        [userId, isBusy ? 1 : 0, panicId || null, isBusy ? 1 : 0]
    );
};

const getOfficerLiveByUserId = async (userId) => {
    const [rows] = await db.execute(`SELECT * FROM officer_live WHERE user_id=?`, [userId]);
    return rows[0] || null;
};

module.exports = {
    upsertOfficerLive,
    setOfficerBusy,
    getOfficerLiveByUserId,
};
