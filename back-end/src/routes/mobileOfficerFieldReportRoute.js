const express = require("express");
const router = express.Router();

const authUser = require("../middleware/authUser");
const requireVerifiedOfficer = require("../middleware/requireVerifiedOfficer");

const C = require("../controller/mobile/officeFieldReportController");

router.get("/field-reports/pending", authUser, requireVerifiedOfficer, C.listPending);
router.get("/field-reports/mine", authUser, requireVerifiedOfficer, C.listMine);

router.get("/field-reports/:id", authUser, requireVerifiedOfficer, C.detail);
router.post("/field-reports/:id/respond", authUser, requireVerifiedOfficer, C.respond);
router.post("/field-reports/:id/finish", authUser, requireVerifiedOfficer, C.finish);

module.exports = router;
