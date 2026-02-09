const M = require("../models/laporanKepolisianModel");

exports.list = async (req, res) => {
    try {
        const { status, search } = req.query;
        const page = Number(req.query.page || 1);
        const limit = Number(req.query.limit || 20);

        const rows = await M.adminList({ status, search, page, limit });
        return res.json({ data: rows, page, limit });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil data admin", error: e.message });
    }
};

exports.detail = async (req, res) => {
    try {
        const id = Number(req.params.id);
        const row = await M.getById(id);
        if (!row) return res.status(404).json({ message: "Laporan tidak ditemukan" });
        return res.json({ data: row });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil detail", error: e.message });
    }
};

exports.updateStatus = async (req, res) => {
    try {
        const id = Number(req.params.id);
        const { status } = req.body || {};

        const allowed = ["pending", "on_process", "selesai", "dibatalkan"];
        if (!allowed.includes(status)) {
            return res.status(400).json({ message: "Status tidak valid" });
        }

        const ok = await M.adminUpdateStatus(id, { status });
        if (!ok) return res.status(404).json({ message: "Laporan tidak ditemukan" });

        return res.json({ message: "Status laporan diupdate" });
    } catch (e) {
        return res.status(500).json({ message: "Gagal update status", error: e.message });
    }
};

