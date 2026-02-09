const M = require("../models/panicAdminModel");

exports.list = async (req, res) => {
    try {
        const { status, search } = req.query;
        const page = Number(req.query.page || 1);
        const limit = Number(req.query.limit || 20);

        const rows = await M.adminList({ status, search, page, limit });
        return res.json({ success: true, data: rows, page, limit });
    } catch (e) {
        console.error("[admin panic list] error:", e);
        return res.status(500).json({ success: false, message: e.message });
    }
};

exports.detail = async (req, res) => {
    try {
        const id = Number(req.params.id);
        const panic = await M.adminDetail(id);
        if (!panic) return res.status(404).json({ success: false, message: "Panic tidak ditemukan" });

        const targets = await M.adminDispatchTargets(id);

        return res.json({
            success: true,
            data: {
                panic,
                dispatchTargets: targets,
            },
        });
    } catch (e) {
        console.error("[admin panic detail] error:", e);
        return res.status(500).json({ success: false, message: e.message });
    }
};
