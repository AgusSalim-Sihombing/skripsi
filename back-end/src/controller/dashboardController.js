const { getDashboardSummary } = require("../models/dashboardModel");

const getSummaryDashboard = async (req, res) => {
    try {
        const data = await getDashboardSummary();
        return res.json({
            success: true,
            message: "Berhasil mengambil ringkasan dashboard",
            data,
        });
    } catch (err) {
        console.error("Error getSummaryDashboard:", err);
        return res.status(500).json({
            success: false,
            message: "Terjadi kesalahan pada server",
        });
    }
};

module.exports = {
    getSummaryDashboard,
};
