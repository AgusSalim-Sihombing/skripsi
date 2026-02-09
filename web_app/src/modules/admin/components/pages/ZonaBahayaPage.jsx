import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";

import AdminLayout from "../../../shared/layout/AdminLayout";
import {
    fetchZonaBahaya,
    createZonaBahaya,
    updateZonaBahaya,
    deleteZonaBahaya,
} from "../../../../services/zonaBahayaService";

import { getAdminLaporanDetail } from "../../../../services/laporanCepatService";

import {
    MapContainer,
    TileLayer,
    Marker,
    Circle,
    useMapEvents,
    Tooltip,
    Popup,
} from "react-leaflet";
import L from "leaflet";

import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;


delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: markerIcon2x,
    iconUrl: markerIcon,
    shadowUrl: markerShadow,
});
const defaultZonaIcon = new L.Icon.Default();

const pendingZonaIcon = new L.DivIcon({
    html: `
      <div style="
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: #ffffff;
        border: 2px solid #ef4444;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 2px 6px rgba(0,0,0,0.3);
      ">
        <span style="
          color: #ef4444;
          font-weight: 700;
          font-size: 18px;
        ">?</span>
      </div>
    `,
    className: "",
    iconSize: [32, 32],
    iconAnchor: [16, 32],
    popupAnchor: [0, -28],
});

const ZonaBahayaPage = () => {
    const [zones, setZones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [selectedId, setSelectedId] = useState(null);
    const [errorMsg, setErrorMsg] = useState("");
    const [clickMode, setClickMode] = useState("MARK");

    const [laporanFotoUrl, setLaporanFotoUrl] = useState(null);
    const [fotoLoading, setFotoLoading] = useState(false);
    const [fotoError, setFotoError] = useState("");
    const warna = ["red", "yellow", "black"]


    const navigate = useNavigate();
    const location = useLocation();

    const [form, setForm] = useState({
        nama_zona: "",
        deskripsi: "",
        latitude: "",
        longitude: "",
        radius_meter: 100,
        // warna_hex: "#FF0000",
        warna_hex: warna,
        tingkat_risiko: "sedang",
        tanggal_kejadian: "",
        waktu_kejadian: "",
        status_zona: "pending",
        id_laporan_sumber: null, // ⬅️ untuk menandai zona ini berasal dari laporan mana
    });

    // ================== LOAD ZONA ==================
    const loadZones = async () => {
        setLoading(true);
        try {
            const res = await fetchZonaBahaya();
            if (res.success) {
                setZones(res.data || []);
            }
        } catch (err) {
            console.error("fetchZonaBahaya error:", err);
            setErrorMsg("Gagal memuat data zona bahaya");
        } finally {
            setLoading(false);
        }
    };

    // ================== PREFILL DARI LAPORAN ==================
    const prefillFromLaporan = async (laporanId) => {
        try {
            const res = await getAdminLaporanDetail(laporanId);
            if (!res.success) {
                console.error("prefillFromLaporan error:", res.message);
                return;
            }

            const lap = res.data.laporan;

            setSelectedId(null); // pastikan mode nya "tambah", bukan edit zona lama

            setForm((prev) => ({
                ...prev,
                nama_zona: lap.judul_laporan
                    ? `Zona: ${lap.judul_laporan}`
                    : prev.nama_zona,
                deskripsi: lap.deskripsi || "",
                latitude: lap.latitude ? String(lap.latitude) : "",
                longitude: lap.longitude ? String(lap.longitude) : "",
                tanggal_kejadian: lap.tanggal_kejadian
                    ? String(lap.tanggal_kejadian).slice(0, 10) // YYYY-MM-DD
                    : "",
                waktu_kejadian: lap.waktu_kejadian
                    ? String(lap.waktu_kejadian).slice(0, 5)     // HH:MM
                    : "",
                id_laporan_sumber: lap.id_laporan,
                status_zona: "pending",
            }));
        } catch (err) {
            console.error("prefillFromLaporan error:", err);
        }
    };

    // ================== EFFECT AWAL: LOAD ZONA + CEK fromLaporan ==================

    useEffect(() => {
        let tempUrl;

        const idLaporan = form.id_laporan_sumber;
        if (!idLaporan) {
            setLaporanFotoUrl(null);
            setFotoError("");
            return;
        }

        const token = localStorage.getItem("sigap_admin_token");
        if (!token) {
            setLaporanFotoUrl(null);
            setFotoError("Token admin tidak ditemukan.");
            return;
        }

        const loadFoto = async () => {
            setFotoLoading(true);
            setFotoError("");

            try {
                const res = await fetch(
                    `${API_BASE_URL}/admin/laporan-cepat/${idLaporan}/foto?t=${Date.now()}`,
                    {
                        headers: {
                            Authorization: `Bearer ${token}`,
                        },
                    }
                );

                if (!res.ok) {
                    throw new Error(`HTTP ${res.status}`);
                }

                const blob = await res.blob();
                tempUrl = URL.createObjectURL(blob);
                setLaporanFotoUrl(tempUrl);
            } catch (e) {
                console.log("load foto laporan error:", e);
                setLaporanFotoUrl(null);
                setFotoError("Foto laporan tidak tersedia / endpoint butuh akses.");
            } finally {
                setFotoLoading(false);
            }
        };

        loadFoto();

        return () => {
            if (tempUrl) URL.revokeObjectURL(tempUrl);
        };
    }, [form.id_laporan_sumber]);

    useEffect(() => {
        loadZones();

        const params = new URLSearchParams(location.search);
        const fromLaporan = params.get("fromLaporan");

        if (fromLaporan) {
            // kalau datang dari tombol "Buat zona bahaya dari laporan ini"
            prefillFromLaporan(fromLaporan);
        } else {
            // kalau buka langsung halaman zona tanpa dari laporan
            resetForm(false);
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [location.search]);

    const mapCenter = useMemo(() => {
        if (form.latitude && form.longitude) {
            return [Number(form.latitude), Number(form.longitude)];
        }
        if (zones.length > 0) {
            return [Number(zones[0].latitude), Number(zones[0].longitude)];
        }
        return [3.5952, 98.6722]; // Medan fallback
    }, [form.latitude, form.longitude, zones]);

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({
            ...prev,
            [name]:
                name === "radius_meter"
                    ? Number(value) || 0
                    : value,
        }));
    };

    const handleMapClick = (e) => {
        const { lat, lng } = e.latlng;

        setForm((prev) => ({
            ...prev,
            latitude: lat.toFixed(6),
            longitude: lng.toFixed(6),
        }));
    };

    const resetForm = (clearLaporanSource = true) => {
        setSelectedId(null);
        setForm((prev) => ({
            nama_zona: "",
            deskripsi: "",
            latitude: "",
            longitude: "",
            radius_meter: 100,
            warna_hex: "#FF0000",
            tingkat_risiko: "sedang",
            tanggal_kejadian: "",
            waktu_kejadian: "",
            status_zona: "pending",
            id_laporan_sumber: clearLaporanSource ? null : prev.id_laporan_sumber,
        }));
        setErrorMsg("");
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setErrorMsg("");

        try {
            const payload = {
                ...form,
                latitude: Number(form.latitude),
                longitude: Number(form.longitude),
                radius_meter: Number(form.radius_meter),
            };

            if (
                !payload.nama_zona ||
                !payload.latitude ||
                !payload.longitude ||
                !payload.radius_meter
            ) {
                setErrorMsg("Nama, posisi (klik peta), dan radius wajib diisi.");
                setSaving(false);
                return;
            }

            if (selectedId) {
                await updateZonaBahaya(selectedId, payload);
            } else {
                await createZonaBahaya(payload);
            }

            await loadZones();
            resetForm();
        } catch (err) {
            console.error("save zona error:", err);
            setErrorMsg("Gagal menyimpan zona bahaya");
        } finally {
            setSaving(false);
        }
    };

    const handleEdit = (zone) => {
        setSelectedId(zone.id_zona);
        setForm({
            nama_zona: zone.nama_zona || "",
            deskripsi: zone.deskripsi || "",
            latitude: String(zone.latitude),
            longitude: String(zone.longitude),
            radius_meter: zone.radius_meter,
            warna_hex: zone.warna_hex || "#FF0000",
            tingkat_risiko: zone.tingkat_risiko || "sedang",
            tanggal_kejadian: zone.tanggal_kejadian
                ? String(zone.tanggal_kejadian).slice(0, 10)
                : "",
            waktu_kejadian: zone.waktu_kejadian
                ? String(zone.waktu_kejadian).slice(0, 5)
                : "",
            status_zona: zone.status_zona || "pending",
            id_laporan_sumber: zone.id_laporan_sumber || null,
        });
    };


    const handleDelete = async (id) => {
        if (!window.confirm("Yakin ingin menghapus zona bahaya ini?")) return;
        try {
            await deleteZonaBahaya(id);
            if (selectedId === id) {
                resetForm();
            }
            await loadZones();
        } catch (err) {
            console.error("delete zona error:", err);
            setErrorMsg("Gagal menghapus zona bahaya");
        }
    };

    const ZonaClickHandler = ({ enabled, onMapClick }) => {
        useMapEvents({
            click(e) {
                if (enabled) {
                    onMapClick(e);
                }
            },
        });
        return null;
    };

    const clearMarkedLocation = () => {
        setForm((prev) => ({
            ...prev,
            latitude: "",
            longitude: "",
        }));
    };

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>Zona Bahaya</h1>
                <p>
                    Kelola titik zona bahaya dan jangkauan radiusnya. Data ini digunakan di
                    aplikasi mobile untuk memberi peringatan saat pengguna memasuki area
                    berbahaya.
                </p>
            </div>

            <div className="zona-bahaya-layout">
                <div className="zona-bahaya-map">
                    <div className="zona-bahaya-map-inner">
                        <MapContainer
                            center={mapCenter}
                            zoom={13}
                            style={{ height: "100%", width: "100%" }}
                        >
                            <ZonaClickHandler
                                enabled={clickMode === "MARK"}
                                onMapClick={handleMapClick}
                            />

                            <TileLayer
                                attribution="&copy; OpenStreetMap contributors"
                                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            />

                            {zones.map((z) => (
                                <React.Fragment key={z.id_zona}>
                                    <Circle
                                        center={[Number(z.latitude), Number(z.longitude)]}
                                        radius={Number(z.radius_meter)}
                                        pathOptions={{
                                            color: z.warna_hex || "#FF0000",
                                            fillColor: z.warna_hex || "#FF0000",
                                            fillOpacity: 0.2,
                                        }}
                                    />

                                    <Marker
                                        position={[Number(z.latitude), Number(z.longitude)]}
                                        icon={z.status_zona === "pending" ? pendingZonaIcon : defaultZonaIcon}
                                    >
                                        <Tooltip permanent direction="top" offset={[0, -10]}>
                                            <div
                                                style={{ fontSize: "0.8rem", fontWeight: 600 }}
                                            >
                                                {z.nama_zona}
                                            </div>
                                        </Tooltip>

                                        <Popup>
                                            <div style={{ maxWidth: 220 }}>
                                                <strong>{z.nama_zona}</strong>
                                                <br />
                                                <span>
                                                    Status: <b>{z.status_zona}</b>
                                                </span>
                                                <br />
                                                <span>
                                                    Risiko: <b>{z.tingkat_risiko}</b>
                                                </span>
                                                <br />
                                                <span>Radius: {z.radius_meter} m</span>
                                                <br />
                                                {z.tanggal_kejadian && (
                                                    <>
                                                        <span>
                                                            Tanggal kejadian: {z.tanggal_kejadian}
                                                        </span>
                                                        <br />
                                                    </>
                                                )}
                                                {z.waktu_kejadian && (
                                                    <>
                                                        <span>
                                                            Waktu kejadian:{" "}
                                                            {z.waktu_kejadian.slice(0, 5)}
                                                        </span>
                                                        <br />
                                                    </>
                                                )}
                                                <span>
                                                    Koordinat: {Number(z.latitude).toFixed(5)},{" "}
                                                    {Number(z.longitude).toFixed(5)}
                                                </span>

                                                {z.deskripsi && (
                                                    <>
                                                        <hr />
                                                        <div style={{ fontSize: "0.8rem" }}>
                                                            {z.deskripsi}
                                                        </div>
                                                    </>
                                                )}
                                            </div>
                                        </Popup>
                                    </Marker>
                                </React.Fragment>
                            ))}

                            {!selectedId && form.latitude && form.longitude && (
                                <Circle
                                    center={[
                                        Number(form.latitude),
                                        Number(form.longitude),
                                    ]}
                                    radius={Number(form.radius_meter) || 0}
                                    pathOptions={{
                                        color: form.warna_hex || "#00BFFF",
                                        fillColor: form.warna_hex || "#00BFFF",
                                        fillOpacity: 0.2,
                                    }}
                                />
                            )}
                        </MapContainer>
                    </div>

                    <div className="zona-map-modes">
                        <button
                            type="button"
                            className={
                                clickMode === "MARK" ? "btn btn-primary" : "btn btn-outline"
                            }
                            onClick={() => setClickMode("MARK")}
                        >
                            Mode Tandai Lokasi
                        </button>

                        <button
                            type="button"
                            className={
                                clickMode === "PAN" ? "btn btn-primary" : "btn btn-outline"
                            }
                            onClick={() => setClickMode("PAN")}
                        >
                            Mode Geser Map
                        </button>

                        <button
                            type="button"
                            className="btn btn-secondary"
                            onClick={clearMarkedLocation}
                            disabled={!form.latitude && !form.longitude}
                            style={{ marginLeft: "0.25rem" }}
                        >
                            Hapus Tanda Lokasi
                        </button>

                        <span className="zona-map-modes__hint">
                            Mode aktif:{" "}
                            {clickMode === "MARK"
                                ? "Tandai lokasi (klik map mengisi lat & long)"
                                : "Geser map saja"}
                        </span>
                    </div>

                    <div className="zona-map-bottom-actions">
                        <button
                            type="button"
                            className="btn btn-secondary"
                            onClick={() => navigate("/admin/zona-bahaya/semua")}
                        >
                            Lihat Semua Zona Bahaya
                        </button>
                    </div>
                </div>

                <div className="zona-bahaya-form">
                    <h2>{selectedId ? "Edit Zona Bahaya" : "Tambah Zona Bahaya"}</h2>
                    <p style={{ fontSize: "0.85rem", color: "#6b7280" }}>
                        Klik pada peta untuk memilih posisi tengah zona.
                        {form.id_laporan_sumber &&
                            " (Zona ini sedang diisi dari data laporan kejahatan)"}
                    </p>

                    {errorMsg && <div className="login-error">{errorMsg}</div>}

                    {form.id_laporan_sumber && (
                        <div
                            className="card"
                            style={{
                                padding: "1rem",
                                marginBottom: "1rem",
                                border: "1px solid #e5e7eb",
                                borderRadius: "12px",
                                background: "#fff",
                            }}
                        >
                            <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
                                <div>
                                    <h3 style={{ margin: 0, fontSize: "1rem" }}>Preview Foto Laporan</h3>
                                    <p style={{ margin: "6px 0 0", color: "#6b7280", fontSize: "0.85rem" }}>
                                        Sumber laporan: <b>#{form.id_laporan_sumber}</b>
                                    </p>
                                </div>

                                <button
                                    type="button"
                                    className="btn btn-outline"
                                    onClick={() => navigate(`/admin/laporan-cepat/${form.id_laporan_sumber}`)}
                                >
                                    Buka Detail
                                </button>
                            </div>

                            <div style={{ marginTop: 12 }}>
                                {fotoLoading ? (
                                    <p style={{ color: "#6b7280", margin: 0 }}>Memuat foto...</p>
                                ) : laporanFotoUrl ? (
                                    <img
                                        src={laporanFotoUrl}
                                        alt="Foto laporan"
                                        style={{
                                            width: "100%",
                                            maxHeight: 260,
                                            objectFit: "contain",
                                            borderRadius: 12,
                                            border: "1px solid #e5e7eb",
                                            background: "#f9fafb",
                                        }}
                                    />
                                ) : (
                                    <div
                                        style={{
                                            padding: "14px",
                                            borderRadius: 12,
                                            border: "1px dashed #d1d5db",
                                            color: "#6b7280",
                                            background: "#f9fafb",
                                        }}
                                    >
                                        {fotoError || "Foto tidak ditemukan pada laporan ini."}
                                    </div>
                                )}
                            </div>
                        </div>
                    )}


                    <form onSubmit={handleSubmit} className="zona-form">
                        <div className="form-group">
                            <label>Nama Zona</label>
                            <input
                                name="nama_zona"
                                value={form.nama_zona}
                                onChange={handleFormChange}
                                placeholder="Contoh: Zona Rawan Pencurian"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Deskripsi (opsional)</label>
                            <textarea
                                name="deskripsi"
                                value={form.deskripsi}
                                onChange={handleFormChange}
                                rows={2}
                                placeholder="Keterangan singkat area ini..."
                            />
                        </div>

                        <div className="form-row">
                            <div className="form-group">
                                <label>Latitude</label>
                                <input
                                    name="latitude"
                                    value={form.latitude}
                                    onChange={handleFormChange}
                                    placeholder="Klik peta atau input manual"
                                />
                            </div>
                            <div className="form-group">
                                <label>Longitude</label>
                                <input
                                    name="longitude"
                                    value={form.longitude}
                                    onChange={handleFormChange}
                                    placeholder="Klik peta atau input manual"
                                />
                            </div>
                        </div>

                        <div className="form-row">
                            <div className="form-group">
                                <label>Tanggal Kejadian (opsional)</label>
                                <input
                                    type="date"
                                    name="tanggal_kejadian"
                                    value={form.tanggal_kejadian}
                                    onChange={handleFormChange}
                                />
                            </div>

                            <div className="form-group">
                                <label>Waktu Kejadian (opsional)</label>
                                <input
                                    type="time"
                                    name="waktu_kejadian"
                                    value={form.waktu_kejadian}
                                    onChange={handleFormChange}
                                />
                            </div>
                        </div>

                        <div className="form-row">
                            <div className="form-group">
                                <label>Radius (meter)</label>
                                <input
                                    type="number"
                                    name="radius_meter"
                                    value={form.radius_meter}
                                    min={10}
                                    step={10}
                                    onChange={handleFormChange}
                                />
                            </div>

                            <div className="form-group">
                                <label>Warna Zona</label>
                                {/* <input
                                    type="color"
                                    name="warna_hex"
                                    value={form.warna_hex}
                                    onChange={handleFormChange}
                                    style={{ padding: 0, height: "36px" }}
                                /> */}
                                <select
                                    name="warna_hex"
                                    value={form.warna_hex}
                                    onChange={handleFormChange}
                                >
                                    <option value="red">Merah</option>
                                    <option value="yellow">Kuning</option>
                                    <option value="black">Hitam</option>
                                </select>
                            </div>
                        </div>

                        <div className="form-group">
                            <label>Tingkat Risiko</label>
                            <select
                                name="tingkat_risiko"
                                value={form.tingkat_risiko}
                                onChange={handleFormChange}
                            >
                                <option value="rendah">Rendah</option>
                                <option value="sedang">Sedang</option>
                                <option value="tinggi">Tinggi</option>
                            </select>
                        </div>

                        <div className="form-group">
                            <label>Status Zona</label>
                            <select
                                name="status_zona"
                                value={form.status_zona}
                                onChange={handleFormChange}
                            >
                                <option value="pending">Pending</option>
                                <option value="approve">Approve</option>
                            </select>
                        </div>

                        <div className="zona-form-actions">
                            <button type="submit" className="btn btn-primary" disabled={saving}>
                                {saving
                                    ? "Menyimpan..."
                                    : selectedId
                                        ? "Update Zona"
                                        : "Simpan Zona"}
                            </button>
                            <button
                                type="button"
                                className="btn btn-outline"
                                onClick={() => resetForm()}
                                disabled={saving}
                            >
                                Reset
                            </button>
                        </div>
                    </form>

                    <hr style={{ margin: "1rem 0" }} />

                    <h3 style={{ marginBottom: "0.5rem" }}>Daftar Zona</h3>
                    {loading ? (
                        <p>Memuat data...</p>
                    ) : zones.length === 0 ? (
                        <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
                            Belum ada zona bahaya yang terdaftar.
                        </p>
                    ) : (
                        <div className="zona-table-wrapper">
                            <table className="zona-table">
                                <thead>
                                    <tr>
                                        <th>Nama Zona</th>
                                        <th>Risiko</th>
                                        <th>Radius (m)</th>
                                        <th>Warna</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {zones.map((z) => (
                                        <tr key={z.id_zona}>
                                            <td>{z.nama_zona}</td>
                                            <td>{z.tingkat_risiko}</td>
                                            <td>{z.radius_meter}</td>
                                            <td>
                                                <span
                                                    style={{
                                                        display: "inline-block",
                                                        width: 16,
                                                        height: 16,
                                                        borderRadius: "999px",
                                                        backgroundColor: z.warna_hex || "#FF0000",
                                                        border: "1px solid #e5e7eb",
                                                    }}
                                                />
                                            </td>
                                            <td style={{ textTransform: "capitalize" }}>
                                                {z.status_zona || "pending"}
                                            </td>
                                            <td>
                                                <button
                                                    type="button"
                                                    className="btn btn-outline"
                                                    style={{
                                                        padding: "0.2rem 0.5rem",
                                                        fontSize: "0.8rem",
                                                    }}
                                                    onClick={() => handleEdit(z)}
                                                >
                                                    Edit
                                                </button>
                                                <button
                                                    type="button"
                                                    className="btn btn-secondary"
                                                    style={{
                                                        padding: "0.2rem 0.5rem",
                                                        fontSize: "0.8rem",
                                                        marginLeft: "0.3rem",
                                                    }}
                                                    onClick={() => handleDelete(z.id_zona)}
                                                >
                                                    Hapus
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </AdminLayout>
    );
};

export default ZonaBahayaPage;
