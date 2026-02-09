const testing = require("../models/testing")

const addImage = async (req, res) => {
  try {
    await testing.addImage(req, res); // kirim req & res, biar model yang handle response
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Gagal menambahkan gambar" });
  }
};

module.exports = {
  addImage
}
