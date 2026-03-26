// src/controller/laporanCepatMobileController.js
const db = require("../../config/database");

// const createLaporanCepatMobile = async (req, res) => {
//     try {
//         // kalau sudah pakai JWT user, ambil dari req.user.id
//         // SESUAIKAN dengan middleware authUser milikmu
//         const idUser = req.user?.id || null;

//         const {
//             judul_laporan,
//             deskripsi,
//             latitude,
//             longitude,
//             tanggal_kejadian,
//             waktu_kejadian,
//             is_anonim, // "0" atau "1"
//         } = req.body;

//         if (!judul_laporan || !latitude || !longitude || !tanggal_kejadian || !waktu_kejadian) {
//             return res.status(400).json({
//                 success: false,
//                 message: "Judul, lokasi, tanggal dan waktu kejadian wajib diisi",
//             });
//         }

//         const fotoBuffer = req.file ? req.file.buffer : null;

//         const [result] = await db.execute(
//             `
//       INSERT INTO laporan_cepat
//       (
//         id_user,
//         judul_laporan,
//         deskripsi,
//         latitude,
//         longitude,
//         tanggal_kejadian,
//         waktu_kejadian,
//         foto,
//         is_anonim,
//         status_validasi
//       )
//       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
//       `,
//             [
//                 idUser,
//                 judul_laporan,
//                 deskripsi || null,
//                 Number(latitude),
//                 Number(longitude),
//                 tanggal_kejadian,
//                 waktu_kejadian,     // "HH:MM"
//                 fotoBuffer,
//                 is_anonim === "1" ? 1 : 0,
//                 "pending",          // default
//             ]
//         );

//         return res.status(201).json({
//             success: true,
//             message: "Laporan cepat berhasil dikirim",
//             data: {
//                 id_laporan: result.insertId,
//             },
//         });
//     } catch (err) {
//         console.error("createLaporanCepatMobile error:", err);
//         return res.status(500).json({
//             success: false,
//             message: "Terjadi kesalahan saat menyimpan laporan",
//         });
//     }
// };

// src/controller/laporanCepatMobileController.js
const createLaporanCepatMobile = async (req, res) => {
  try {
    // Ambil ID User dari middleware JWT
    const idUser = req.user?.id || null;

    const {
      judul_laporan,
      deskripsi,
      latitude,
      longitude,
      tanggal_kejadian,
      waktu_kejadian,
      is_anonim, // "0" atau "1"
    } = req.body;

    if (!judul_laporan || !latitude || !longitude || !tanggal_kejadian || !waktu_kejadian) {
      return res.status(400).json({
        success: false,
        message: "Judul, lokasi, tanggal dan waktu kejadian wajib diisi",
      });
    }

    const fotoBuffer = req.file ? req.file.buffer : null;

    // ========================================================
    // 1. CARI DATA USER DI DATABASE BERDASARKAN idUser
    // ========================================================
    let namaPelapor = null;
    let noHpPelapor = null;
    let emailPelapor = null;

    if (idUser) {
      // ⚠️ PENTING: Sesuaikan nama tabel (misal: users / masyarakat) 
      // dan nama kolom (nama, no_hp, email) sesuai struktur databasemu!
      const [userRows] = await db.execute(
        `SELECT nama, phone, email FROM user WHERE id = ?`,
        [idUser]
      );

      const user = userRows[0];

      // ========================================================
      // 2. CEK LOGIKA ANONIM
      // Jika BUKAN anonim, kita masukkan data aslinya.
      // Jika anonim, biarkan tetap null.
      // ========================================================
      if (user && is_anonim !== "1") {
        namaPelapor = user.nama;
        noHpPelapor = user.phone;
        emailPelapor = user.email;
      }
    }

    // ========================================================
    // 3. INSERT KE TABEL LAPORAN CEPAT
    // ========================================================
    const [result] = await db.execute(
      `
      INSERT INTO laporan_cepat
      (
        id_user,
        judul_laporan,
        deskripsi,
        latitude,
        longitude,
        tanggal_kejadian,
        waktu_kejadian,
        foto,
        is_anonim,
        status_validasi,
        nama_pelapor,    -- Kolom baru
        no_hp_pelapor,   -- Kolom baru
        email_pelapor    -- Kolom baru
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        idUser,
        judul_laporan,
        deskripsi || null,
        Number(latitude),
        Number(longitude),
        tanggal_kejadian,
        waktu_kejadian,     // "HH:MM"
        fotoBuffer,
        is_anonim === "1" ? 1 : 0,
        "pending",          // default
        namaPelapor,        // Berisi nama asli ATAU null
        noHpPelapor,        // Berisi no hp asli ATAU null
        emailPelapor        // Berisi email asli ATAU null
      ]
    );

    return res.status(201).json({
      success: true,
      message: "Laporan cepat berhasil dikirim",
      data: {
        id_laporan: result.insertId,
      },
    });
  } catch (err) {
    console.error("createLaporanCepatMobile error:", err);
    return res.status(500).json({
      success: false,
      message: "Terjadi kesalahan saat menyimpan laporan",
    });
  }
};

const getMyLaporanCepatMobile = async (req, res) => {
  try {
    const userId = req.user.id; // diisi dari authUser (JWT)

    const [rows] = await db.execute(
      `
      SELECT 
        id_laporan,
        judul_laporan,
        deskripsi,
        latitude,
        longitude,
        tanggal_kejadian,
        waktu_kejadian,
        status_validasi,
        created_at
      FROM laporan_cepat
      WHERE id_user = ?
      ORDER BY created_at DESC
      `,
      [userId]
    );

    return res.json({
      success: true,
      data: rows,
    });
  } catch (err) {
    console.error("[getMyLaporanCepatMobile] error:", err);
    return res.status(500).json({
      success: false,
      message: "Gagal mengambil daftar laporan",
    });
  }
};

const getLaporanCepatFotoMobile = async (req, res) => {
  try {
    const idLaporan = parseInt(req.params.id, 10);
    const [rows] = await db.execute(
      `SELECT foto FROM laporan_cepat WHERE id_laporan = ? LIMIT 1`,
      [idLaporan]
    );

    if (!rows.length || !rows[0].foto) {
      return res.status(404).json({ message: "Foto tidak ditemukan" });
    }
    res.setHeader("Content-Type", "image/jpeg");
    return res.send(rows[0].foto);
  } catch (err) {
    return res.status(500).json({ message: "Server error" });
  }
};
module.exports = {
  createLaporanCepatMobile,
  getMyLaporanCepatMobile,
  getLaporanCepatFotoMobile,
};
