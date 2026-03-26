// src/routes/communityPublicRoutes.js
const express = require("express");
const router = express.Router();

const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });

// ✅ PAKAI JWT middleware yang sama dengan login kamu
const authUser = require("../middleware/authUser");

// ✅ ambil hanya guard verifikasi (tanpa requireAuth lama)
const { requireVerifiedMasyarakat } = require("../middleware/authUsersAdmin");

const {
    mustCommunityActive,
    mustMemberApproved,
    mustOwner,
} = require("../middleware/comunityGuard"); // (tetap pakai nama file kamu)

const C = require("../controller/comunityPublicController");

// lobby list
router.get("/communities", authUser, requireVerifiedMasyarakat, C.listCommunities);

// search username (buat add member)
router.get("/users/search", authUser, requireVerifiedMasyarakat, C.searchUsers);

// create komunitas (multipart)
router.post(
    "/communities",
    authUser,
    requireVerifiedMasyarakat,
    upload.single("icon"),
    C.createCommunity
);

// icon fetch
router.get(
    "/communities/:id/icon",
    authUser,
    requireVerifiedMasyarakat,
    C.getCommunityIcon
);

// join request
router.post(
    "/communities/:id/join-request",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    C.requestJoin
);

// invite accept/decline
router.post(
    "/communities/:id/invite/accept",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    C.acceptInvite
);

router.post(
    "/communities/:id/invite/decline",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    C.declineInvite
);

// owner: list request join
router.get(
    "/communities/:id/requests",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    mustOwner,
    C.listJoinRequests
);

// owner: approve/reject request
router.patch(
    "/communities/:id/requests/:userId",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    mustOwner,
    C.respondJoinRequest
);

// owner: invite member (set invited)
router.post(
    "/communities/:id/invite",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    mustOwner,
    C.inviteMembers
);

// messages
// router.get(
//     "/communities/:id/messages",
//     authUser,
//     requireVerifiedMasyarakat,
//     mustCommunityActive,
//     mustMemberApproved,
//     C.getMessages
// );

router.get(
    "/communities/:id/messages",
    authUser,
    requireVerifiedMasyarakat,
    mustMemberApproved,
    C.getMessages
);

router.post(
    "/communities/:id/messages",
    authUser,
    requireVerifiedMasyarakat,
    mustCommunityActive,
    mustMemberApproved,
    C.sendMessage
);

module.exports = router;
