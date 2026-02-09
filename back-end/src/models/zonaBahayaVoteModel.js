const db = require("../config/database");

// Ringkasan vote per zona
const getVoteSummary = async (idZona) => {
  const [rows] = await db.execute(
    `
      SELECT
        COALESCE(SUM(CASE WHEN pilihan = 'setuju' THEN 1 ELSE 0 END), 0) AS total_setuju,
        COALESCE(
          SUM(
            CASE 
              WHEN pilihan = 'tidak_setuju' THEN 1
              WHEN pilihan = 'tidak' THEN 1
              ELSE 0
            END
          ), 
          0
        ) AS total_tidak,
        COUNT(*) AS total_vote
      FROM zona_bahaya_vote
      WHERE id_zona = ?
    `,
    [idZona]
  );

  if (!rows || rows.length === 0) {
    return {
      total_setuju: 0,
      total_tidak: 0,
      total_vote: 0,
    };
  }

  const row = rows[0];

  return {
    total_setuju: row.total_setuju || 0,
    total_tidak: row.total_tidak || 0,
    total_vote: row.total_vote || 0,
  };
};

// Ambil vote user tertentu di zona tertentu
const getUserVote = async (idZona, idUser) => {
  const [rows] = await db.execute(
    `
      SELECT id_vote, id_zona, id_user, pilihan, created_at
      FROM zona_bahaya_vote
      WHERE id_zona = ? AND id_user = ?
      LIMIT 1
    `,
    [idZona, idUser]
  );

  if (!rows || rows.length === 0) {
    return null;
  }
  return rows[0];
};

// Insert / update vote user
const upsertVote = async (idZona, idUser, pilihan) => {
  // cek sudah pernah vote atau belum
  const [rows] = await db.execute(
    `
      SELECT id_vote
      FROM zona_bahaya_vote
      WHERE id_zona = ? AND id_user = ?
      LIMIT 1
    `,
    [idZona, idUser]
  );

  if (rows.length > 0) {
    const idVote = rows[0].id_vote;
    await db.execute(
      `
        UPDATE zona_bahaya_vote
        SET pilihan = ?
        WHERE id_vote = ?
      `,
      [pilihan, idVote]
    );
    return idVote;
  } else {
    const [result] = await db.execute(
      `
        INSERT INTO zona_bahaya_vote (id_zona, id_user, pilihan)
        VALUES (?, ?, ?)
      `,
      [idZona, idUser, pilihan]
    );
    return result.insertId;
  }
};

// Rekap vote berdasarkan ID laporan (gabung zona_bahaya + zona_bahaya_vote)
const getVoteSummaryByLaporan = async (idLaporan) => {
  const [rows] = await db.execute(
    `
    SELECT
      COALESCE(SUM(CASE WHEN v.pilihan = 'setuju' THEN 1 ELSE 0 END), 0) AS total_setuju,
      COALESCE(
        SUM(
          CASE 
            WHEN v.pilihan = 'tidak_setuju' THEN 1
            WHEN v.pilihan = 'tidak' THEN 1
            ELSE 0
          END
        ), 
        0
      ) AS total_tidak,
      COALESCE(COUNT(v.id_vote), 0) AS total_vote
    FROM zona_bahaya_vote v
    JOIN zona_bahaya z ON v.id_zona = z.id_zona
    WHERE z.id_laporan_sumber = ?
    `,
    [idLaporan]
  );

  const row = rows[0] || {};
  const total_setuju = row.total_setuju || 0;
  const total_tidak = row.total_tidak || 0;
  const total_vote = row.total_vote || 0;

  const persentase_setuju =
    total_vote === 0 ? 0 : Math.round((total_setuju * 100) / total_vote);
  const persentase_tidak =
    total_vote === 0 ? 0 : Math.round((total_tidak * 100) / total_vote);

  return {
    total_setuju,
    total_tidak,
    total_vote,
    persentase_setuju,
    persentase_tidak,
  };
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
  getVoteSummary,
  getUserVote,
  upsertVote,
  getVoteSummaryByLaporan
}; 
