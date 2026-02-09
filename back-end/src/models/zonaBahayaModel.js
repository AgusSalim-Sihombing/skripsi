// src/models/zonaBahayaModel.js
const db = require("../config/database");
const { get } = require("../routes/adminUserRoute");

// Ambil semua zona bahaya
const getAllZonaBahaya = async () => {
  const [rows] = await db.execute(
    `SELECT 
      id_zona,
      id_laporan_sumber,
      nama_zona,
      deskripsi,
      latitude,
      longitude,
      radius_meter,
      warna_hex,
      tingkat_risiko,
      tanggal_kejadian,
      waktu_kejadian,
      status_zona,
      created_at
    FROM zona_bahaya
    ORDER BY created_at DESC`
  );
  return rows;
};

// Tambah zona bahaya
const createZonaBahaya = async (data) => {
  const {
    id_laporan_sumber,
    nama_zona,
    deskripsi,
    latitude,
    longitude,
    radius_meter,
    warna_hex,
    tingkat_risiko,
    tanggal_kejadian,
    waktu_kejadian,
    status_zona,
  } = data;

  const [result] = await db.execute(
    `INSERT INTO zona_bahaya 
     (id_laporan_sumber, nama_zona, deskripsi, latitude, longitude, radius_meter, warna_hex, tingkat_risiko, tanggal_kejadian, waktu_kejadian, status_zona)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id_laporan_sumber || null,
      nama_zona,
      deskripsi || null,
      latitude,
      longitude,
      radius_meter,
      warna_hex || "#FF0000",
      tingkat_risiko || "sedang",
      tanggal_kejadian || null,
      waktu_kejadian || null,
      status_zona || "pending",
    ]
  );

  return result.insertId;
};

// Update zona bahaya
const updateZonaBahaya = async (id_zona, data) => {
  const {
    id_laporan_sumber,
    nama_zona,
    deskripsi,
    latitude,
    longitude,
    radius_meter,
    warna_hex,
    tingkat_risiko,
    tanggal_kejadian,
    waktu_kejadian,
    status_zona,
  } = data;

  const [result] = await db.execute(
    `UPDATE zona_bahaya
     SET id_laporan_sumber = ?,
         nama_zona = ?, 
         deskripsi = ?, 
         latitude = ?, 
         longitude = ?, 
         radius_meter = ?, 
         warna_hex = ?, 
         tingkat_risiko = ?,
         tanggal_kejadian = ?,
         waktu_kejadian = ?, 
         status_zona = ?
     WHERE id_zona = ?`,
    [
      id_laporan_sumber || null,
      nama_zona,
      deskripsi || null,
      latitude,
      longitude,
      radius_meter,
      warna_hex || "#FF0000",
      tingkat_risiko || "sedang",
      tanggal_kejadian || null,
      waktu_kejadian || null,
      status_zona || "pending",
      id_zona,
    ]
  );

  return result.affectedRows;
};

const deleteZonaBahaya = async (id_zona) => {
  const [result] = await db.execute(
    "DELETE FROM zona_bahaya WHERE id_zona = ?",
    [id_zona]
  );
  return result.affectedRows;
};

const setZonaStatusByLaporan = async (id_laporan, status) => {
  await db.execute(
    "UPDATE zona_bahaya SET status_zona = ? WHERE id_laporan_sumber = ?",
    [status, id_laporan]
  );
};

const getVotesWithUser = async (idZona) => {
  const [rows] = await db.execute(
    `
    SELECT v.id_vote, v.id_zona, v.id_user, v.pilihan, v.created_at,
           u.nama, u.username
    FROM zona_bahaya_vote v
    JOIN users u ON u.id_user = v.id_user
    WHERE v.id_zona = ?
    ORDER BY v.created_at DESC
    `,
    [idZona]
  );
  return rows;
};


module.exports = {
  getAllZonaBahaya,
  createZonaBahaya,
  updateZonaBahaya,
  deleteZonaBahaya,
  setZonaStatusByLaporan,
  getVotesWithUser,
};
