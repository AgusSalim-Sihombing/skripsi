// src/routes/mobileZonaBahayaRoute.js
const express = require("express");
const router = express.Router();

const authUser = require("../middleware/authUser");
const {
    voteZonaBahayaMobile,
    getZonaBahayaVoteSummaryMobile,
    listZonaBahayaMobile,
    getZonaBahayaFotoMobile,
} = require("../controller/mobile/zonaBahayaMobileController");

// user kirim vote
router.post(
    "/zona-bahaya/:id_zona/vote",
    authUser,
    voteZonaBahayaMobile
);

// user lihat ringkasan voting + vote dia sendiri 
router.get(
    "/zona-bahaya/:id_zona/votes-summary",
    authUser,
    getZonaBahayaVoteSummaryMobile
);

router.get("/zona-bahaya", authUser, listZonaBahayaMobile);
router.get("/zona-bahaya/:id_zona/foto", authUser, getZonaBahayaFotoMobile);

module.exports = router;
