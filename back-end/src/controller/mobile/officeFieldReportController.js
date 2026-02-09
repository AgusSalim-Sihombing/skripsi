const M = require("../../models/laporanKepolisianModel");

exports.listPending = async (req, res) => {
    try {
        const page = Number(req.query.page || 1);
        const limit = Number(req.query.limit || 20);

        const rows = await M.listPending({ page, limit });
        return res.json({ data: rows, page, limit });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil pending", error: e.message });
    }
};

exports.listMine = async (req, res) => {
    try {
        const officerId = req.user.id;
        const status = req.query.status; // optional: on_process / selesai
        const page = Number(req.query.page || 1);
        const limit = Number(req.query.limit || 20);

        const rows = await M.listMineAsOfficer(officerId, { status, page, limit });
        return res.json({ data: rows, page, limit });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil report officer", error: e.message });
    }
};

exports.detail = async (req, res) => {
    try {
        const officerId = req.user.id;
        const id = Number(req.params.id);

        const row = await M.officerGetDetail(officerId, id);
        if (!row) return res.status(404).json({ message: "Laporan tidak ditemukan / tidak bisa diakses" });

        // kalau sudah diambil officer lain, block
        if (row.assigned_officer_user_id && row.assigned_officer_user_id !== officerId && row.status !== "pending") {
            return res.status(403).json({ message: "Laporan sedang ditangani officer lain" });
        }

        return res.json({ data: row });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil detail", error: e.message });
    }
};

exports.respond = async (req, res) => {
    try {
        const officerId = req.user.id;
        const id = Number(req.params.id);

        const affected = await M.respond(officerId, id);

        if (affected === 0) {
            return res.status(409).json({ message: "Gagal respond. Laporan mungkin sudah diambil officer lain / bukan pending." });
        }

        return res.json({ message: "Berhasil respond", status: "on_process", assigned_officer_user_id: officerId });
    } catch (e) {
        return res.status(500).json({ message: "Gagal respond", error: e.message });
    }
};

exports.finish = async (req, res) => {
    try {
        const officerId = req.user.id;
        const id = Number(req.params.id);

        const affected = await M.finish(officerId, id);
        if (affected === 0) {
            return res.status(409).json({ message: "Gagal selesai. Pastikan laporan sedang on_process dan kamu yang menangani." });
        }

        return res.json({ message: "Laporan selesai", status: "selesai" });
    } catch (e) {
        return res.status(500).json({ message: "Gagal selesai", error: e.message });
    }
};
