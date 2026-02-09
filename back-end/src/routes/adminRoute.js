const express = require("express");
const router = express.Router();

const { loginAdmin } = require("../controller/adminAuthController");
const { getSummaryDashboard } = require("../controller/dashboardController");
const authAdmin = require("../middleware/authAdmin");

// ====== ZONA BAHAYA CRUD ======
const {
    listZonaBahaya,
    createZonaBahayaController,
    updateZonaBahayaController,
    deleteZonaBahayaController,
    getZonaBahayaVoteSummaryAdmin,
    getZonaBahayaVotesAdmin
} = require("../controller/zonaBahayaController");


// ========== AUTH & DASHBOARD ==========
router.post("/login", loginAdmin);
router.get("/dashboard/summary", authAdmin, getSummaryDashboard);

// ========== ZONA BAHAYA CRUD ==========
router.get("/zona-bahaya", authAdmin, listZonaBahaya);
router.post("/zona-bahaya", authAdmin, createZonaBahayaController);
router.put("/zona-bahaya/:id", authAdmin, updateZonaBahayaController);
router.delete("/zona-bahaya/:id", authAdmin, deleteZonaBahayaController);

// ========== VOTING ZONA BAHAYA (ADMIN VIEW) ==========
// ringkasan: total setuju / tidak setuju / persentase
router.get(
    "/zona-bahaya/:id_zona/votes-summary",
    authAdmin,
    getZonaBahayaVoteSummaryAdmin
);

// list detail semua vote (kalau mau ditampilkan di modal / halaman detail)
router.get(
    "/zona-bahaya/:id_zona/votes",
    authAdmin,
    getZonaBahayaVotesAdmin
);

// ========== COMMUNITY ADMIN ROUTES ==========
const { requireAuth, requireRole } = require("../middleware/authUsersAdmin");
const A = require("../controller/comunityAdminController");

router.get("/communities",authAdmin, A.listAllCommunities);
router.get("/communities/:id/messages", authAdmin, A.getCommunityMessages);
router.patch("/communities/:id/takedown", authAdmin, A.takedownCommunity);
router.patch("/communities/:id/restore", authAdmin, A.restoreCommunity);
router.patch("/messages/:messageId/delete", authAdmin, A.deleteMessage);
router.get("/communities/:id", authAdmin, A.getCommunityDetail);


//laporan kepolisian admin

const C = require("../controller/adminLaporanKepolisianController");
router.get("/laporan-kepolisian", authAdmin, C.list);
router.get("/laporan-kepolisian/:id", authAdmin, C.detail);
router.patch("/laporan-kepolisian/:id/status", authAdmin, C.updateStatus);

const AdminPanicAlert = require("../controller/adminPanicAlertController");

// Panic Alert Admin
router.get("/panic-alert", authAdmin, AdminPanicAlert.list);
router.get("/panic-alert/:id", authAdmin, AdminPanicAlert.detail);


module.exports = router;
