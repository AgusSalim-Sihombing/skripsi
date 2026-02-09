const laporanModel = require("../models/laporanModel");
const db = require("../config/database");


const { success, error } = require("../utils/response");

const getAllLaporan = async (req, res) => {
    try {
        const laporan = await userModel.getAllLaporan();
        success(res, laporan);
    } catch (err) {
        error(res, err.message);
    }
};

const getLaporanById = async (req, res) => {
    try {
        const laporan = await laporanModel.getLaporanById(req.params.id);
        if (!laporan) return error(res, "Laporan not found", 404);
        success(res, laporan);
    } catch (err) {
        error(res, err.message);
    }
}

const createLaporan = async (req, res) => {
    try {
        const id = await laporanModel.createLaporan(req.body);
        success(res, { id }, "Laporan created successfully");
    } catch (error) {
        error(res, err.message);
    }
}