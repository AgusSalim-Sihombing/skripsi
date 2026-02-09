const M = require("../../models/laporanKepolisianModel");
const must = (v) => v !== undefined && v !== null && String(v).trim() !== "";

const requireFields = (body) => {
    const errors = {};

    // ===== WAKTU KEJADIAN =====
    if (!must(body.waktu_kejadian_hari)) errors.waktu_kejadian_hari = "Wajib diisi";
    if (!must(body.waktu_kejadian_tanggal)) errors.waktu_kejadian_tanggal = "Wajib diisi";
    if (!must(body.waktu_kejadian_jam)) errors.waktu_kejadian_jam = "Wajib diisi";

    // ===== TEMPAT KEJADIAN =====
    if (!must(body.tempat_jalan)) errors.tempat_jalan = "Wajib diisi";
    if (!must(body.tempat_desa_kel)) errors.tempat_desa_kel = "Wajib diisi";
    if (!must(body.tempat_kecamatan)) errors.tempat_kecamatan = "Wajib diisi";
    if (!must(body.tempat_kab_kota)) errors.tempat_kab_kota = "Wajib diisi";

    // ===== PERISTIWA =====
    if (!must(body.apa_terjadi)) errors.apa_terjadi = "Wajib diisi";
    if (!must(body.bagaimana_terjadi)) errors.bagaimana_terjadi = "Wajib diisi";
    if (!must(body.tindak_pidana)) errors.tindak_pidana = "Wajib diisi";
    if (!must(body.uraian_singkat)) errors.uraian_singkat = "Wajib diisi";

    // ===== TERLAPOR =====
    if (!must(body.terlapor_nama)) errors.terlapor_nama = "Wajib diisi";
    if (!must(body.terlapor_jk)) errors.terlapor_jk = "Wajib diisi";
    if (!must(body.terlapor_alamat)) errors.terlapor_alamat = "Wajib diisi";
    if (!must(body.terlapor_pekerjaan)) errors.terlapor_pekerjaan = "Wajib diisi";
    if (!must(body.terlapor_kontak)) errors.terlapor_kontak = "Wajib diisi";

    // ===== KORBAN =====
    if (!must(body.korban_nama)) errors.korban_nama = "Wajib diisi";
    if (!must(body.korban_jk)) errors.korban_jk = "Wajib diisi";
    if (!must(body.korban_alamat)) errors.korban_alamat = "Wajib diisi";
    if (!must(body.korban_pekerjaan)) errors.korban_pekerjaan = "Wajib diisi";
    if (!must(body.korban_kontak)) errors.korban_kontak = "Wajib diisi";

    // ===== SAKSI (minimal 1 saksi lengkap) =====
    const saksi1Lengkap =
        must(body.saksi1_nama) && must(body.saksi1_umur) && must(body.saksi1_alamat) && must(body.saksi1_pekerjaan);

    const saksi2Lengkap =
        must(body.saksi2_nama) && must(body.saksi2_umur) && must(body.saksi2_alamat) && must(body.saksi2_pekerjaan);

    if (!saksi1Lengkap && !saksi2Lengkap) {
        errors.saksi = "Minimal isi Saksi 1 atau Saksi 2 (nama, umur, alamat, pekerjaan)";
    }

    // ===== BARANG BUKTI =====
    if (!must(body.barang_bukti)) errors.barang_bukti = "Wajib diisi";

    return errors;
};

exports.create = async (req, res) => {
    try {
        const userId = req.user.id;

        const errors = requireFields(req.body || {});
        if (Object.keys(errors).length > 0) {
            return res.status(400).json({
                message: "Validasi gagal",
                errors,
            });
        }

        const id = await M.createReport(userId, req.body || {});
        return res.status(201).json({ message: "Laporan dibuat (pending)", id, status: "pending" });
    } catch (e) {
        return res.status(500).json({ message: "Gagal membuat laporan", error: e.message });
    }
};

exports.mineList = async (req, res) => {
    try {
        const userId = req.user.id;
        const page = Number(req.query.page || 1);
        const limit = Number(req.query.limit || 20);

        const rows = await M.getMineList(userId, { page, limit });
        return res.json({ data: rows, page, limit });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil data", error: e.message });
    }
};

exports.mineDetail = async (req, res) => {
    try {
        const userId = req.user.id;
        const id = Number(req.params.id);

        const row = await M.getMineDetail(userId, id);
        if (!row) return res.status(404).json({ message: "Laporan tidak ditemukan" });

        return res.json({ data: row });
    } catch (e) {
        return res.status(500).json({ message: "Gagal ambil detail", error: e.message });
    }
};

exports.cancelMine = async (req, res) => {
    try {
        const userId = req.user.id;
        const id = Number(req.params.id);

        const affected = await M.cancelMine(userId, id);

        if (affected === 0) {
            return res.status(409).json({
                message: "Gagal cancel. Laporan mungkin sudah diproses / diambil officer / bukan milikmu.",
            });
        }

        return res.json({ message: "Pengajuan dibatalkan", status: "dibatalkan" });
    } catch (e) {
        return res.status(500).json({ message: "Gagal cancel", error: e.message });
    }
};

