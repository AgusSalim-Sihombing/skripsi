const db = require("../../config/database");
const {
    getVoteSummary,
    getUserVote,
    upsertVote,
} = require("../../models/zonaBahayaVoteModel");
const { success, error } = require("../../utils/response");

const {
    getAllZonaBahaya,
} = require("../../models/zonaBahayaModel");


const voteZonaBahaya = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id_zona, 10);
        const userId = req.user && req.user.id; // dari authUser
        const { pilihan } = req.body;

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({ message: "ID zona tidak valid" });
        }

        if (!["setuju", "tidak"].includes(pilihan)) {
            return res
                .status(400)
                .json({ message: "Pilihan voting harus 'setuju' atau 'tidak'" });
        }

        // cek zona exist + masih pending
        const [zonaRows] = await db.execute(
            "SELECT id_zona, status_zona FROM zona_bahaya WHERE id_zona = ?",
            [idZona]
        );

        const zona = zonaRows[0];
        if (!zona) {
            return res.status(404).json({ message: "Zona bahaya tidak ditemukan" });
        }

        if (zona.status_zona !== "pending") {
            return res
                .status(400)
                .json({ message: "Zona ini sudah tidak bisa divoting lagi" });
        }

        // cek apakah user sudah pernah vote
        const existingVote = await findUserVote(idZona, userId);
        if (existingVote) {
            return res.status(400).json({
                message: "Kamu sudah pernah memberikan vote untuk zona ini",
                alreadyVoted: true,
                pilihan: existingVote.pilihan,
            });
        }

        const idVote = await createVote(idZona, userId, pilihan);
        const summary = await getVoteSummary(idZona);

        return res.status(201).json({
            success: true,
            message: "Vote berhasil disimpan",
            data: {
                id_vote: idVote,
                summary,
            },
        });
    } catch (err) {
        console.error("voteZonaBahaya error:", err);
        return res.status(500).json({
            message: "Terjadi kesalahan pada server",
            error: err.message,
        });
    }
};

// GET /api/mobile/zona-bahaya/:id_zona/vote-status
// -> summary + info apakah user ini sudah vote
const getZonaBahayaVoteStatus = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id_zona, 10);
        const userId = req.user && req.user.id;

        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({ message: "ID zona tidak valid" });
        }

        const summary = await getVoteSummary(idZona);
        const myVote = await findUserVote(idZona, userId);

        return res.json({
            success: true,
            data: {
                summary,
                myVote: myVote
                    ? {
                        pilihan: myVote.pilihan,
                        created_at: myVote.created_at,
                    }
                    : null,
            },
        });
    } catch (err) {
        console.error("getZonaBahayaVoteStatus error:", err);
        return res.status(500).json({
            message: "Terjadi kesalahan pada server",
            error: err.message,
        });
    }
};

const voteZonaBahayaMobile = async (req, res) => {
    try {
        const { id_zona } = req.params;
        let { vote, pilihan } = req.body;
        const userId = req.user.id; // dari authMobile

        const idZonaInt = parseInt(id_zona, 10);
        if (!idZonaInt || Number.isNaN(idZonaInt)) {
            return error(res, "ID zona tidak valid", 400);
        }

        // 🔽 Ambil nilai dari vote / pilihan (kalau frontend beda-beda)
        let rawVote = vote ?? pilihan;
        if (!rawVote || typeof rawVote !== "string") {
            return error(res, "Vote harus 'setuju' atau 'tidak'", 400);
        }

        rawVote = rawVote.toLowerCase();

        // 🔽 Normalisasi ke nilai ENUM di DB: 'setuju' / 'tidak'
        let finalPilihan;
        if (rawVote === "setuju") {
            finalPilihan = "setuju";
        } else if (rawVote === "tidak_setuju" || rawVote === "tidak") {
            finalPilihan = "tidak";
        } else {
            return error(res, "Vote harus 'setuju' atau 'tidak'", 400);
        }

        // Cek zona ada & masih pending
        const [zonaRows] = await db.execute(
            "SELECT id_zona, status_zona FROM zona_bahaya WHERE id_zona = ?",
            [idZonaInt]
        );

        if (zonaRows.length === 0) {
            return error(res, "Zona bahaya tidak ditemukan", 404);
        }

        if (zonaRows[0].status_zona !== "pending") {
            return error(
                res,
                "Zona ini sudah tidak dalam tahap voting (status bukan pending)",
                400
            );
        }

        // Simpan / update vote
        const idVote = await upsertVote(idZonaInt, userId, finalPilihan);

        // Ambil summary terbaru
        const summary = await getVoteSummary(idZonaInt);

        return success(
            res,
            {
                id_vote: idVote,
                summary,
            },
            "Vote berhasil disimpan"
        );
    } catch (err) {
        console.error("voteZonaBahayaMobile error:", err);
        return error(res, "Gagal menyimpan vote zona bahaya", 500);
    }
};


// GET /api/mobile/zona-bahaya/:id_zona/votes-summary
// dipakai di detail zona (untuk bar persentase + status vote user)
const getZonaBahayaVoteSummaryMobile = async (req, res) => {
    try {
        const { id_zona } = req.params;
        const userId = req.user.id;

        const idZonaInt = parseInt(id_zona, 10);
        if (!idZonaInt || Number.isNaN(idZonaInt)) {
            return error(res, "ID zona tidak valid", 400);
        }

        const summary = await getVoteSummary(idZonaInt);
        const userVoteRow = await getUserVote(idZonaInt, userId);

        const total = summary.total_vote || 0;
        let persenSetuju = 0;
        let persenTidakSetuju = 0;

        if (total > 0) {
            persenSetuju = Math.round((summary.total_setuju / total) * 100);
            persenTidakSetuju = Math.round((summary.total_tidak / total) * 100);
        }

        return success(res, {
            total_setuju: summary.total_setuju,
            total_tidak: summary.total_tidak,
            total_vote: summary.total_vote,
            persen_setuju: persenSetuju,
            persen_tidak_setuju: persenTidakSetuju,
            my_vote: userVoteRow ? userVoteRow.pilihan : null,
        });
    } catch (err) {
        console.error("getZonaBahayaVoteSummaryMobile error:", err);
        return error(res, "Gagal mengambil data voting zona", 500);
    }
};

const listZonaBahayaMobile = async (req, res) => {
    try {
        // kalau mau cuma zona yang sudah approve:
        // const data = await getApprovedZonaBahaya();
        const data = await getAllZonaBahaya();

        console.log("Data yang dikirim ke Mobile:", JSON.stringify(data, null, 2));

        return res.json({
            success: true,
            data,
        });
    } catch (err) {
        console.error("listZonaBahayaMobile error:", err);
        return res.status(500).json({
            success: false,
            message: "Gagal mengambil data zona bahaya",
        });
    }
};

const getZonaBahayaFotoMobile = async (req, res) => {
    try {
        const idZona = parseInt(req.params.id_zona, 10);
        if (!idZona || Number.isNaN(idZona)) {
            return res.status(400).json({ success: false, message: "ID zona tidak valid" });
        }

        const [rows] = await db.execute(
            `
      SELECT lc.foto
      FROM zona_bahaya zb
      JOIN laporan_cepat lc ON lc.id_laporan = zb.id_laporan_sumber
      WHERE zb.id_zona = ?
      LIMIT 1
      `,
            [idZona]
        );

        if (!rows.length || !rows[0].foto) {
            return res.status(404).json({ success: false, message: "Foto tidak ditemukan" });
        }

        // BLOB -> kirim bytes
        res.setHeader("Content-Type", "image/jpeg"); // (aman praktis)
        return res.send(rows[0].foto);
    } catch (err) {
        console.error("getZonaBahayaFotoMobile error:", err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
};



module.exports = {
    voteZonaBahaya,
    getZonaBahayaVoteStatus,
    voteZonaBahayaMobile,
    getZonaBahayaVoteSummaryMobile,
    listZonaBahayaMobile,
    getZonaBahayaFotoMobile,
};