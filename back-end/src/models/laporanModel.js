const db = require("../config/database");

const getAllLaporan = async () => {
    const [rows] = await db.execute("SELECT * FROM laporan");
    return rows;
};


const getLaporanById = async (id) => {
    const [rows] = await db.execute("SELECT * FROM laporan WHERE id = ?", [id]);
    return rows[0];
};

const createLaporan = async (data) => { 
    const { judul_kejahatan, deskripsi, lokasi_kejahatan, foto } = data;
    const [result] = await db.execute(
        "INSERT INTO laporan (judul_kejahatan,deskripsi , lokasi_kejahatan, foto) VALUES (?, ?, ?,?)",
        [judul_kejahatan, deskripsi, lokasi_kejahatan, foto]
    );
    return result.insertId;
};

const updateLaporan = async (id, data) => {
    const { judul_kejahatan, deskripsi, lokasi_kejahatan, foto } = data;
    await db.execute("UPDATE laporan SET judul_kejahatan = ?,  deskripsi = ?,lokasi_kejahatan = ?, foto = ?  WHERE id = ?", [
        judul_kejahatan,
        deskripsi,
        lokasi_kejahatan,
        foto,
        id,
    ]);
};

const deleteLaporan = async (id) => {
    await db.execute("DELETE FROM laporan WHERE id = ?", [id]);
};

module.exports = {
    getAllLaporan,
    getLaporanById,
    createLaporan,
    updateLaporan,
    deleteLaporan,
}