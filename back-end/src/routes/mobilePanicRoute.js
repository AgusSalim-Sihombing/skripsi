const express = require("express");
const router = express.Router();

const panicController = require("../controller/mobile/panicController");
const authUser = require("../middleware/authUser");
const requireRole = require("../middleware/requireRole");

// masyarakat kirim panic
router.post("/panic", authUser, requireRole("masyarakat"), panicController.createPanic);

// officer update lokasi (wajib biar bisa dihitung nearest)
router.post("/officer/location", authUser, requireRole("officer"), panicController.updateOfficerLocation);

// officer respon panic
router.post("/officer/panic/:id/respond", authUser, requireRole("officer"), panicController.respondPanic);

// optional: list offered panic untuk page dispatch
router.get("/officer/panic/offered", authUser, requireRole("officer"), panicController.listOfferedPanics);
router.post("/officer/panic/:id/resolve", authUser, requireRole("officer"), panicController.resolvePanic);
router.get("/panic/:id", authUser, requireRole("masyarakat"), panicController.getPanicStatus);
router.post(
    "/officer/panic/:id/resolve",
    authUser,
    requireRole("officer"),
    panicController.resolvePanic
);

// RIWAYAT PANIC (OFFICER)
router.get(
    "/officer/panic/history",
    authUser,
    requireRole("officer"),
    panicController.listPanicHistory
);

router.get(
    "/officer/panic/history/:id",
    authUser,
    requireRole("officer"),
    panicController.getPanicHistoryDetail
);

module.exports = router;
