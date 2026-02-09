const db = require("../config/database");

const addImage = async (req, res) => {
    try {
        const gambar = req.file ? req.file.buffer : null;

        if (!gambar) {
            return res.status(400).json({ message: "Gambar wajib diupload" });
        }

        await db.execute(
            "INSERT INTO testing (gambar) VALUES (?)",
            [gambar]
        );
            
        res.status(201).json({ message: "Gambar berhasil ditambahkan" });
    } catch (err) {
        console.error("Gagal insert gambar:", err);
        res.status(500).json({ message: "Gagal menambahkan gambar", error: err.message }); 
    }
};

module.exports = {
    addImage,
};