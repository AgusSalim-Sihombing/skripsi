import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import { getDashboardSummary } from "../../../../services/dashboardService";
import { fetchZonaBahaya } from "../../../../services/zonaBahayaService";

import { MapContainer, TileLayer, Circle, CircleMarker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";

const normalizeStatus = (s) => {
    const x = (s || "").toString().toLowerCase();
    if (x === "approve") return "approved";
    return x || "pending";
};

const computeCenter = (zones) => {
    const valid = (zones || [])
        .map((z) => ({ lat: Number(z.latitude), lng: Number(z.longitude) }))
        .filter((p) => Number.isFinite(p.lat) && Number.isFinite(p.lng));

    if (!valid.length) return [-6.2, 106.816666]; // fallback center
    const avgLat = valid.reduce((a, b) => a + b.lat, 0) / valid.length;
    const avgLng = valid.reduce((a, b) => a + b.lng, 0) / valid.length;
    return [avgLat, avgLng];
};

const AdminDashboardPage = () => {
    const navigate = useNavigate();

    const [summary, setSummary] = useState({
        total_laporan: 0,
        laporan_hari_ini: 0,
        total_titik_rawan: 0,
        aktivitas_hari_ini: 0,
    });

    const [loading, setLoading] = useState(true);

    const [zones, setZones] = useState([]);
    const [zonesLoading, setZonesLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem("sigap_admin_token");
        if (!token) {
            navigate("/login-admin");
            return;
        }

        const fetchAll = async () => {
            try {
                const res = await getDashboardSummary();
                if (res?.success) setSummary(res.data);

                const zRes = await fetchZonaBahaya(); // { success, data: [...] }
                if (zRes?.success) setZones(zRes.data || []);
                else setZones([]);
            } catch (err) {
                console.error("Error fetch dashboard:", err);
                if (err?.response?.status === 401) {
                    localStorage.removeItem("sigap_admin_token");
                    localStorage.removeItem("sigap_admin_info");
                    navigate("/login-admin");
                }
            } finally {
                setLoading(false);
                setZonesLoading(false);
            }
        };

        fetchAll();
    }, [navigate]);

    const mapCenter = useMemo(() => computeCenter(zones), [zones]);

    const statusCount = useMemo(() => {
        const c = { pending: 0, approved: 0, rejected: 0, other: 0 };
        zones.forEach((z) => {
            const st = normalizeStatus(z.status_zona);
            if (st === "pending") c.pending++;
            else if (st === "approved") c.approved++;
            else if (st === "rejected") c.rejected++;
            else c.other++;
        });
        return c;
    }, [zones]);

    const zoneStyle = (z) => {
        const st = normalizeStatus(z.status_zona);
        const color = (z.warna_hex || "#FF0000").toString();

        // pending dibuat beda biar keliatan
        if (st === "pending") {
            return { color, fillColor: color, fillOpacity: 0.12, dashArray: "6 8" };
        }
        return { color, fillColor: color, fillOpacity: 0.22 };
    };

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>Beranda</h1>
                <p>Ringkasan aktivitas aplikasi SIGAP.</p>
            </div>

            {loading ? (
                <p>Memuat ringkasan...</p>
            ) : (
                <>
                    <div className="dashboard-cards">
                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Total Laporan</span>
                            <span className="dashboard-card__value">{summary.total_laporan}</span>
                        </div>

                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Laporan Hari Ini</span>
                            <span className="dashboard-card__value">{summary.laporan_hari_ini}</span>
                        </div>

                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Titik Rawan</span>
                            <span className="dashboard-card__value">{summary.total_titik_rawan}</span>
                        </div>

                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Aktivitas Hari Ini</span>
                            <span className="dashboard-card__value">{summary.aktivitas_hari_ini}</span>
                        </div>
                    </div>

                    {/* MAP LANGSUNG DI DASHBOARD */}
                    <div className="dashboard-map-card" style={{ marginTop: 24, color: "black" }}>
                        <div className="dashboard-map-card__header">
                            <div>
                                <h3>Map Zona Bahaya</h3>
                                <p className="dashboard-map-card__sub">
                                    Menampilkan semua zona (pending & approved).
                                </p>
                            </div>

                            <div className="dashboard-map-card__badges">
                                <span className="badge">Total: {zones.length}</span>
                                <span className="badge badge--pending">Pending: {statusCount.pending}</span>
                                <span className="badge badge--approved">Approved: {statusCount.approved}</span>
                            </div>
                        </div>

                        <div className="dashboard-map-wrapper">
                            {zonesLoading ? (
                                <div className="dashboard-map-loading">Memuat peta zona...</div>
                            ) : (
                                <MapContainer
                                    center={mapCenter}
                                    zoom={13}
                                    scrollWheelZoom
                                    className="dashboard-map"
                                >
                                    <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

                                    {zones
                                        .map((z) => ({
                                            ...z,
                                            lat: Number(z.latitude),
                                            lng: Number(z.longitude),
                                            radius: Number(z.radius_meter || 0),
                                            statusNorm: normalizeStatus(z.status_zona),
                                        }))
                                        .filter((z) => Number.isFinite(z.lat) && Number.isFinite(z.lng))
                                        .map((z) => (
                                            <React.Fragment key={z.id_zona}>
                                                <Circle
                                                    center={[z.lat, z.lng]}
                                                    radius={z.radius}
                                                    pathOptions={zoneStyle(z)}
                                                />

                                                <CircleMarker
                                                    center={[z.lat, z.lng]}
                                                    radius={7}
                                                    pathOptions={{
                                                        color: (z.warna_hex || "#FF0000").toString(),
                                                        fillColor: (z.warna_hex || "#FF0000").toString(),
                                                        fillOpacity: 0.9,
                                                    }}
                                                >
                                                    <Popup>
                                                        <div style={{ minWidth: 220 }}>
                                                            <div style={{ fontWeight: 700, marginBottom: 6 }}>
                                                                {z.nama_zona || "Zona Bahaya"}
                                                            </div>
                                                            <div style={{ fontSize: 13, marginBottom: 6 }}>
                                                                Status: <b>{z.statusNorm}</b>
                                                            </div>
                                                            <div style={{ fontSize: 13 }}>
                                                                Risiko: <b>{z.tingkat_risiko || "-"}</b>
                                                            </div>
                                                            <div style={{ fontSize: 13 }}>
                                                                Radius: <b>{z.radius} m</b>
                                                            </div>
                                                            <div style={{ fontSize: 12, marginTop: 6, color: "#444" }}>
                                                                {z.deskripsi || ""}
                                                            </div>
                                                        </div>
                                                    </Popup>
                                                </CircleMarker>
                                            </React.Fragment>
                                        ))}
                                </MapContainer>
                            )}
                        </div>
                    </div>
                </>
            )}
        </AdminLayout>
    );
};

export default AdminDashboardPage;
