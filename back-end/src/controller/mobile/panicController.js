const userModel = require("../../models/userModel");
const officerLiveModel = require("../../models/officerLiveModel");
const panicModel = require("../../models/panicModel");

// OFFICER: update lokasi + duty
// OFFICER: update lokasi + duty
const updateOfficerLocation = async (req, res) => {
    try {
        const io = req.app.get("io");
        const userId = req.user.id;
        const { lat, lng, isOnDuty, speed } = req.body;

        if (typeof lat !== "number" || typeof lng !== "number") {
            return res.status(400).json({ message: "lat/lng wajib number" });
        }

        // ✅ update dulu
        await officerLiveModel.upsertOfficerLive(userId, !!isOnDuty, lat, lng);

        // ✅ ambil live terbaru
        const live = await officerLiveModel.getOfficerLiveByUserId(userId);

        if (live?.is_busy === 1 && live.current_panic_id) {
            const panicId = live.current_panic_id;

            const payload = {
                panicId,
                officerId: userId,
                lat,
                lng,
                speed: typeof speed === "number" ? speed : null,
                updatedAt: new Date().toISOString(),
            };

            // ✅ kirim ke panic room
            io.to(`panic:${panicId}`).emit("officer:location", payload);

            // ✅ kirim juga ke citizen room
            const panic = await panicModel.getPanicById(panicId);
            if (panic?.citizen_id) {
                io.to(`citizen:${panic.citizen_id}`).emit("officer:location", payload);
            }
        }

        return res.json({ message: "Lokasi officer updated" });
    } catch (err) {
        console.error("[updateOfficerLocation] error:", err);
        return res.status(500).json({ message: err.message });
    }
};



// MASYARAKAT: create panic + dispatch realtime ke officer
// MASYARAKAT: create panic + dispatch realtime ke officer
const createPanic = async (req, res) => {
    try {
        const io = req.app.get("io");
        const citizenId = req.user.id;
        const { lat, lng, address } = req.body;

        if (typeof lat !== "number" || typeof lng !== "number") {
            return res.status(400).json({ message: "lat/lng wajib number" });
        }

        const citizen = await userModel.getUserById(citizenId);
        if (!citizen) return res.status(404).json({ message: "User tidak ditemukan" });

        // ✅ (opsional tapi recommended) blok kalau masih ada panic aktif
        const active = await panicModel.getActivePanicByCitizenId(citizenId);
        if (active) {
            return res.status(409).json({
                message: "Kamu masih punya panic aktif. Menunggu respon.",
                panicId: active.id,
                status: active.status,
            });
        }

        // ✅ PENTING: panicId didefinisikan di sini sebelum dipakai
        const panicId = await panicModel.createPanicEvent({
            citizenId,
            citizenName: citizen.nama,
            lat,
            lng,
            address,
        });

        const officers = await panicModel.findNearestOfficers({ lat, lng, limit: 3 });

        if (!officers.length) {
            return res.status(200).json({
                message: "Panic tercatat, tapi belum ada officer online terdekat",
                panicId,              // ✅ aman
                dispatchedTo: 0,
            });
        }

        for (const o of officers) {
            const distanceM = Math.round(Number(o.dist_m || 0));

            await panicModel.insertDispatchTarget(panicId, o.id, distanceM);

            io.to(`officer:${o.id}`).emit("panic:new", {
                panicId,
                title: "PANGGILAN DARURAT!!",
                fromName: citizen.nama,
                lat,
                lng,
                address: address ?? null,
                distanceM,
                createdAt: new Date().toISOString(),
            });
        }

        return res.status(201).json({
            message: "Panic terkirim",
            panicId,                 // ✅ aman
            dispatchedTo: officers.length,
        });
    } catch (err) {
        console.error("[createPanic] error:", err);
        return res.status(500).json({ message: err.message });
    }
};


// OFFICER: respond panic (first accept wins)
const respondPanic = async (req, res) => {
    try {
        const io = req.app.get("io");
        const officerId = req.user.id;
        const panicId = Number(req.params.id);

        const officer = await userModel.getUserById(officerId);
        if (!officer) return res.status(404).json({ message: "Officer tidak ditemukan" });

        const result = await panicModel.assignPanicToOfficerTx({
            panicId,
            officerId,
            officerName: officer.nama,
        });

        if (!result.ok) {
            return res.status(result.code).json({ message: result.message });
        }
        await officerLiveModel.setOfficerBusy(officerId, true, panicId);


        const panic = await panicModel.getPanicById(panicId);
        const officerLive = await officerLiveModel.getOfficerLiveByUserId(officerId);
        // setelah const officerLive = await officerLiveModel.getOfficerLiveByUserId(officerId);

        if (officerLive?.last_lat != null && officerLive?.last_lng != null) {
            const locPayload = {
                panicId,
                officerId,
                lat: officerLive.last_lat,
                lng: officerLive.last_lng,
                speed: null,
                updatedAt: new Date().toISOString(),
            };

            // ✅ kirim ke citizen room (paling penting)
            io.to(`citizen:${panic.citizen_id}`).emit("officer:location", locPayload);

            // ✅ kirim juga ke panic room (optional tapi bagus)
            io.to(`panic:${panicId}`).emit("officer:location", locPayload);
        }

        io.in(`citizen:${panic.citizen_id}`).socketsJoin(`panic:${panicId}`);
        io.in(`officer:${officerId}`).socketsJoin(`panic:${panicId}`);

        // ✅ emit SEKALI aja
        io.to(`citizen:${panic.citizen_id}`).emit("panic:responded", {
            panicId,
            officer: {
                id: officer.id,
                nama: officer.nama,
                lastLat: officerLive?.last_lat ?? null,
                lastLng: officerLive?.last_lng ?? null,
            },
            message: "Panic kamu sudah direspon officer",
        });

        // notif ke officer lain yang ditawari: panic sudah di-assign
        const targets = await panicModel.getDispatchTargets(panicId);
        for (const t of targets) {
            io.to(`officer:${t.officer_id}`).emit("panic:assigned", {
                panicId,
                assignedOfficerId: officerId,
            });
        }

        return res.json({
            message: "Berhasil merespon panic",
            panicId,
            citizen: {
                id: panic.citizen_id,
                nama: panic.citizen_name_snap,
                lat: panic.citizen_lat,
                lng: panic.citizen_lng,
                address: panic.citizen_address_snap,
            },
        });
    } catch (err) {
        console.error("[respondPanic] error:", err);
        return res.status(500).json({ message: err.message });
    }
};

// OFFICER: list offered panics (buat halaman Panic Dispatch)
const listOfferedPanics = async (req, res) => {
    try {
        const officerId = req.user.id;
        const rows = await panicModel.listOfferedPanicsForOfficer(officerId);
        return res.json(rows);
    } catch (err) {
        console.error("[listOfferedPanics] error:", err);
        return res.status(500).json({ message: err.message });
    }
};

const resolvePanic = async (req, res) => {
    try {
        const io = req.app.get("io");
        const officerId = req.user.id;
        const panicId = Number(req.params.id);

        const affected = await panicModel.resolvePanicForOfficer({ panicId, officerId });
        if (!affected) {
            return res.status(409).json({ message: "Panic tidak bisa diselesaikan (bukan milikmu / status bukan ASSIGNED)" });
        }

        await officerLiveModel.setOfficerBusy(officerId, false, null);

        // notif citizen kalau
        const panic = await panicModel.getPanicById(panicId);
        if (panic?.citizen_id) {
            io.to(`citizen:${panic.citizen_id}`).emit("panic:resolved", {
                panicId,
                message: "Penanganan panic sudah diselesaikan.",
            });

            io.to(`panic:${panicId}`).emit("panic:resolved", {
                panicId,
                message: "Penanganan panic sudah diselesaikan.",
            });
        }

        return res.json({ message: "Panic selesai. Officer kembali available." });
    } catch (err) {
        console.error("[resolvePanic] error:", err);
        return res.status(500).json({ message: err.message });
    }
};

const getPanicStatus = async (req, res) => {
    try {
        const citizenId = req.user.id;
        const panicId = Number(req.params.id);

        const panic = await panicModel.getPanicById(panicId);
        if (!panic) return res.status(404).json({ message: "Panic tidak ditemukan" });

        if (panic.citizen_id !== citizenId) {
            return res.status(403).json({ message: "Tidak boleh akses panic ini" });
        }

        let officerLive = null;
        if (panic.status === "ASSIGNED" && panic.assigned_officer_id) {
            officerLive = await officerLiveModel.getOfficerLiveByUserId(panic.assigned_officer_id);
        }

        return res.json({
            panicId: panic.id,
            status: panic.status,
            assignedOfficerId: panic.assigned_officer_id,
            assignedOfficerName: panic.assigned_officer_name_snap,

            // ✅ tambahan penting
            officerLastLat: officerLive?.last_lat ?? null,
            officerLastLng: officerLive?.last_lng ?? null,
            officerLocUpdatedAt: officerLive?.last_loc_updated_at ?? null,
        });
    } catch (err) {
        console.error("[getPanicStatus] error:", err);
        return res.status(500).json({ message: err.message });
    }
};

const listPanicHistory = async (req, res) => {
    try {
        const officerId = req.user.id;
        const rows = await panicModel.listHistoryForOfficer(officerId, 100);
        return res.json(rows);
    } catch (err) {
        console.error("[listPanicHistory] error:", err);
        return res.status(500).json({ message: err.message });
    }
};

const getPanicHistoryDetail = async (req, res) => {
    try {
        const officerId = req.user.id;
        const panicId = Number(req.params.id);

        const row = await panicModel.getHistoryDetailForOfficer(officerId, panicId);
        if (!row) return res.status(404).json({ message: "Riwayat panic tidak ditemukan" });

        return res.json(row);
    } catch (err) {
        console.error("[getPanicHistoryDetail] error:", err);
        return res.status(500).json({ message: err.message });
    }
};



module.exports = {
    updateOfficerLocation,
    createPanic,
    respondPanic,
    listOfferedPanics,
    resolvePanic,
    getPanicStatus,
    listPanicHistory,
    getPanicHistoryDetail,
};
