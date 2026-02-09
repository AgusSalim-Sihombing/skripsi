const userModel = require("../../models/userModel");

exports.me = async (req, res) => {
    try {
        const userId = req.user.id;
        const u = await userModel.getUserMe(userId);
        if (!u) return res.status(404).json({ message: "User tidak ditemukan" });
        return res.json({ data: u });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil profil", error: e.message });
    }
};

exports.updateMe = async (req, res) => {
    try {
        const userId = req.user.id;

        // hanya field yang boleh diupdate dari mobile
        const allowed = [
            "nik",
            "nama",
            "tempat_lahir",
            "tanggal_lahir",
            "alamat",
            "phone",
            "email",
            "username",
        ];

        const payload = {};
        for (const k of allowed) {
            if (Object.prototype.hasOwnProperty.call(req.body, k)) {
                payload[k] = req.body[k];
            }
        }

        if (Object.keys(payload).length === 0) {
            return res.status(400).json({ message: "Tidak ada field yang dikirim untuk update" });
        }

        await userModel.updateUserMe(userId, payload);

        const updated = await userModel.getUserMe(userId);
        return res.json({ message: "Profil berhasil diupdate", data: updated });
    } catch (e) {
        return res.status(500).json({ message: "Gagal update profil", error: e.message });
    }
};

exports.resubmitKtp = async (req, res) => {
    try {
        const userId = req.user.id;
        const buf = req.file?.buffer;
        if (!buf) return res.status(400).json({ message: "ktp_image wajib diupload" });

        const affected = await userModel.resubmitKtpMe(userId, buf);

        if (affected === 0) {
            return res.status(403).json({
                message: "Tidak bisa upload ulang KTP. Pastikan status_verifikasi = rejected.",
            });
        }

        const updated = await userModel.getUserMe(userId);
        return res.json({ message: "KTP berhasil dikirim ulang (status: pending)", data: updated });
    } catch (e) {
        return res.status(500).json({ message: "Gagal kirim ulang KTP", error: e.message });
    }
};

exports.getMyKtpImage = async (req, res) => {
    try {
        const userId = req.user.id;
        const buf = await userModel.getMyKtpImage(userId);
        if (!buf) return res.status(404).json({ message: "KTP tidak ditemukan" });

        res.setHeader("Content-Type", "application/octet-stream");
        return res.send(buf);
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil KTP", error: e.message });
    }
};

// ====== FOTO PROFIL (opsional) ======
exports.uploadFoto = async (req, res) => {
    try {
        const userId = req.user.id;
        const buf = req.file?.buffer;
        if (!buf) return res.status(400).json({ message: "foto wajib diupload" });

        await userModel.updateFotoMe(userId, buf);
        return res.json({ message: "Foto profil berhasil diupdate" });
    } catch (e) {
        return res.status(500).json({ message: "Gagal upload foto", error: e.message });
    }
};

exports.getMyFoto = async (req, res) => {
    try {
        const userId = req.user.id;
        const buf = await userModel.getMyFoto(userId);
        if (!buf) return res.status(404).json({ message: "Foto tidak ditemukan" });

        res.setHeader("Content-Type", "application/octet-stream");
        return res.send(buf);
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil foto", error: e.message });
    }
};
