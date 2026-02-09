
const db = require("../config/database");

const getAllUsers = async () => {
  const [rows] = await db.execute("SELECT * FROM user");
  return rows;
};

const getUserById = async (id) => {
  const [rows] = await db.execute("SELECT * FROM user WHERE id = ?", [id]);
  return rows[0];
};

const createUser = async (data, ktpBuffer) => {
  const {
    nik,
    nama,
    alamat,
    username,
    password,       // sudah dalam bentuk HASH dari controller
    phone,
    tempat_lahir,
    tanggal_lahir,
    email,
    role,
  } = data;

  const [result] = await db.execute(
    `INSERT INTO user
      (nik, nama, alamat, username, password, phone, tempat_lahir, tanggal_lahir, email, ktp_image, role)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)`,
    [
      nik,
      nama,
      alamat,
      username,
      password,
      phone || null,
      tempat_lahir || null,
      tanggal_lahir || null,
      email || null,
      ktpBuffer || null,
      role || "masyarakat",
    ]
  );

  return result.insertId;
};

const updateUser = async (id, data) => {
  const { nama, email } = data;
  await db.execute("UPDATE user SET nama = ?, email = ? WHERE id = ?", [
    nama,
    email,
    id,
  ]);
};

const deleteUser = async (id) => {
  await db.execute("DELETE FROM user WHERE id = ?", [id]);
};

const getUsersAdmin = async ({ role, search, status_verifikasi }) => {
  let sql = `
    SELECT 
      id, nik, nama, username, phone, email, role,
      status_verifikasi, catatan_verifikasi, created_at
    FROM user
    WHERE 1=1
  `;
  const params = [];

  if (role) {
    sql += " AND role = ?";
    params.push(role);
  }

  if (status_verifikasi) {
    sql += " AND status_verifikasi = ?";
    params.push(status_verifikasi);
  }

  if (search) {
    sql +=
      " AND (nama LIKE ? OR nik LIKE ? OR username LIKE ? OR email LIKE ?)";
    const like = `%${search}%`;
    params.push(like, like, like, like);
  }

  sql += " ORDER BY created_at DESC";

  const [rows] = await db.execute(sql, params);
  return rows;
};

/**
 * Update fleksibel dari sisi admin
 * hanya field yang dikirim yang di-update.
 */
const updateUserAdmin = async (id, data) => {
  const fields = [];
  const params = [];

  const allowed = [
    "nik",
    "nama",
    "alamat",
    "username",
    "phone",
    "tempat_lahir",
    "tanggal_lahir",
    "email",
    "role",
    "status_verifikasi",
    "catatan_verifikasi",
    "password", // sudah dalam bentuk hash
  ];

  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      fields.push(`${key} = ?`);
      // kalau string kosong → simpan NULL
      const value =
        data[key] === "" || data[key] === undefined ? null : data[key];
      params.push(value);
    }
  }

  if (fields.length === 0) return;

  params.push(id);
  await db.execute(
    `UPDATE user SET ${fields.join(", ")} WHERE id = ?`,
    params
  );
};


const getUserMe = async (id) => {
  const [rows] = await db.execute(
    `
    SELECT 
      id, nik, nama, tempat_lahir, tanggal_lahir, alamat, phone, email,
      username, role,
      status_verifikasi, catatan_verifikasi,
      created_at, updated_at,
      (ktp_image IS NOT NULL) AS has_ktp_image,
      (foto IS NOT NULL) AS has_foto
    FROM user
    WHERE id = ?
    `,
    [id]
  );
  return rows[0];
};

const updateUserMe = async (id, data) => {
  const fields = [];
  const params = [];

  const allowed = ["nik", "nama", "tempat_lahir", "tanggal_lahir", "alamat", "phone", "email", "username"];

  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      fields.push(`${key} = ?`);
      const v = (data[key] === "" || data[key] === undefined) ? null : data[key];
      params.push(v);
    }
  }

  if (fields.length === 0) return;

  params.push(id);
  await db.execute(`UPDATE user SET ${fields.join(", ")} WHERE id = ?`, params);
};

const resubmitKtpMe = async (id, ktpBuffer) => {
  const [res] = await db.execute(
    `
    UPDATE user
    SET ktp_image = ?,
        status_verifikasi = 'pending',
        catatan_verifikasi = NULL
    WHERE id = ?
      AND status_verifikasi = 'rejected'
    `,
    [ktpBuffer, id]
  );
  return res.affectedRows;
};

const getMyKtpImage = async (id) => {
  const [rows] = await db.execute(`SELECT ktp_image FROM user WHERE id = ?`, [id]);
  return rows[0]?.ktp_image || null;
};

const updateFotoMe = async (id, fotoBuffer) => {
  await db.execute(`UPDATE user SET foto = ? WHERE id = ?`, [fotoBuffer, id]);
};

const getMyFoto = async (id) => {
  const [rows] = await db.execute(`SELECT foto FROM user WHERE id = ?`, [id]);
  return rows[0]?.foto || null;
};



module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getUsersAdmin,
  updateUserAdmin,

  
  // mobile profile
  getUserMe,
  updateUserMe,
  resubmitKtpMe,
  getMyKtpImage,
  updateFotoMe,
  getMyFoto,
};
