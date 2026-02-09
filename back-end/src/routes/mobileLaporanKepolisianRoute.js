const express = require("express");
const router = express.Router();

const authUser = require("../middleware/authUser");
const { requireVerifiedMasyarakat } = require("../middleware/authUsersAdmin");

const C = require("../controller/mobile/laporanKepolisianController");

router.post("/laporan-kepolisian", authUser, requireVerifiedMasyarakat, C.create);
router.get("/laporan-kepolisian/mine", authUser, requireVerifiedMasyarakat, C.mineList);
router.get("/laporan-kepolisian/mine/:id", authUser, requireVerifiedMasyarakat, C.mineDetail);
router.post(
  "/laporan-kepolisian/mine/:id/cancel",
  authUser,
  requireVerifiedMasyarakat,
  C.cancelMine
);

module.exports = router;
