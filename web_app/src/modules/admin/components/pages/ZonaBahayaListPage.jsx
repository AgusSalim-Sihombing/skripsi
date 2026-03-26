import React, { useEffect, useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import { fetchZonaBahaya } from "../../../../services/zonaBahayaService";

const ZonaBahayaListPage = () => {
    const [zones, setZones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");

    const [search, setSearch] = useState("");
    const [risiko, setRisiko] = useState("semua");

    const navigate = useNavigate();

    const loadZones = async () => {
        setLoading(true);
        setErrorMsg("");
        try {
            const res = await fetchZonaBahaya();
            if (res.success) {
                setZones(res.data || []);
            } else {
                setErrorMsg(res.message || "Gagal memuat data zona bahaya");
            }
        } catch (err) {
            console.error("fetchZonaBahaya list error:", err);
            setErrorMsg("Terjadi kesalahan saat memuat data zona bahaya");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadZones();
    }, []);

    const filteredZones = useMemo(() => {
        return zones.filter((z) => {
            const matchNama =
                !search ||
                z.nama_zona?.toLowerCase().includes(search.toLowerCase());

            const matchRisiko =
                risiko === "semua" || z.tingkat_risiko === risiko;

            return matchNama && matchRisiko;
        });
    }, [zones, search, risiko]);

    const formatTanggal = (tgl) => {
        if (!tgl) return "-";
        try {
            return new Date(tgl).toLocaleDateString("id-ID");
        } catch {
            return tgl;
        }
    };

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>Semua Zona Bahaya</h1>
                <p>
                    Daftar lengkap zona bahaya yang telah ditandai. Gunakan
                    pencarian dan filter untuk mempermudah pengecekan.
                </p>
            </div>

            <form
                className="laporan-filter-form"
                onSubmit={(e) => e.preventDefault()}
            >
                <div className="form-row">
                    <div className="form-group">
                        <label>Cari Nama Zona</label>
                        <input
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            placeholder="Contoh: Zona Rawan Pencurian"
                        />
                    </div>

                    <div className="form-group">
                        <label>Filter Risiko</label>
                        <select
                            value={risiko}
                            onChange={(e) => setRisiko(e.target.value)}
                        >
                            <option value="semua">Semua</option>
                            <option value="rendah">Rendah</option>
                            <option value="sedang">Sedang</option>
                            <option value="tinggi">Tinggi</option>
                        </select>
                    </div>
                </div>
            </form>

            <div style={{ marginTop: "1rem" }}>
                {loading ? (
                    <p>Memuat data zona bahaya...</p>
                ) : errorMsg ? (
                    <p style={{ color: "red", fontSize: "0.9rem" }}>{errorMsg}</p>
                ) : filteredZones.length === 0 ? (
                    <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
                        Tidak ada zona bahaya yang cocok dengan filter.
                    </p>
                ) : (
                    <div className="zona-table-wrapper">
                        <table className="zona-table">
                            <thead>
                                <tr>
                                    <th>Nama Zona</th>
                                    <th>Risiko</th>
                                    <th>Status</th>
                                    <th>Radius (m)</th>
                                    <th>Koordinat</th>
                                    <th>Tanggal Kejadian</th>
                                    <th>Warna</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredZones.map((z) => (
                                    <tr key={z.id_zona}>
                                        <td>{z.nama_zona}</td>
                                        <td>{z.tingkat_risiko}</td>
                                        <td>{z.status || "-"}</td>
                                        <td>{z.radius_meter}</td>
                                        <td>
                                            {Number(z.latitude).toFixed(5)},{" "}
                                            {Number(z.longitude).toFixed(5)}
                                        </td>
                                        <td>
                                            {z.tanggal_kejadian
                                                ? formatTanggal(z.tanggal_kejadian)
                                                : "-"}
                                        </td>
                                        <td>
                                            <span
                                                style={{
                                                    display: "inline-block",
                                                    width: 18,
                                                    height: 18,
                                                    borderRadius: "999px",
                                                    backgroundColor: z.warna_hex || "#FF0000",
                                                    border: "1px solid #e5e7eb",
                                                }}
                                            />
                                        </td>
                                        <td>
                                            <button
                                                type="button"
                                                onClick={() => navigate(`/admin/zona-bahaya/semua/${z.id_zona}`)}
                                                style={{
                                                    border: "none",
                                                    backgroundColor: "#2563eb",
                                                    color: "white",
                                                    padding: "8px 14px",
                                                    borderRadius: "8px",
                                                    cursor: "pointer",
                                                    fontWeight: 600,
                                                }}
                                            >
                                                Detail
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
};

export default ZonaBahayaListPage;