import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import { fetchPanicAlertDetail } from "../../../../../services/panicAlertService";

// Tambahkan Polyline di sini
import { MapContainer, TileLayer, CircleMarker, Popup } from "react-leaflet";
import "./AdminPanicList.css";
import RoutingMachine from "./RoutingMachine";

const fmt = (d) => (d ? new Date(d).toLocaleString("id-ID") : "-");

const AdminPanicAlertDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    const load = async () => {
        setLoading(true);
        try {
            const res = await fetchPanicAlertDetail(id);
            if (res?.success) setData(res.data);
        } catch (e) {
            if (e?.response?.status === 401) navigate("/login-admin");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, [id]);

    const panic = data?.panic;
    const targets = data?.dispatchTargets || [];

    const citizenPos = useMemo(() => {
        const lat = Number(panic?.citizen_lat);
        const lng = Number(panic?.citizen_lng);
        return Number.isFinite(lat) && Number.isFinite(lng) ? [lat, lng] : null;
    }, [panic]);

    const officerPos = useMemo(() => {
        const lat = Number(panic?.officerLastLat);
        const lng = Number(panic?.officerLastLng);
        return Number.isFinite(lat) && Number.isFinite(lng) ? [lat, lng] : null;
    }, [panic]);

    const center = citizenPos || officerPos || [-6.2, 106.816666];

    return (
        <AdminLayout>
            <div className="panic-detail-container">
                <div className="panic-detail-header">
                    <div>
                        <h1 className="panic-title">Detail Laporan Panic #{id}</h1>
                        <span className={`panic-status-badge status-${panic?.status?.toLowerCase()}`}>
                            Status: {panic?.status || "-"}
                        </span>
                    </div>
                    <button  onClick={() => navigate("/admin/panic-alert")}>
                        ← Kembali ke Daftar
                    </button>
                </div>

                {loading ? (
                    <div className="panic-loading">Memuat data detail...</div>
                ) : !panic ? (
                    <div className="panic-error">Data tidak ditemukan.</div>
                ) : (
                    <>
                        <div className="panic-info-grid">
                            {/* KARTU MASYARAKAT */}
                            <div className="panic-info-card citizen-border">
                                <div className="card-icon-header">
                                    <span className="icon">👤</span>
                                    <h4>Data Masyarakat</h4>
                                </div>
                                <div className="card-body">

                                    <table className="mini-table">
                                        <tbody>
                                            <tr><td><strong>Nama</strong></td><td>:</td><td>{panic.citizen_name_snap || panic.citizenNama || "-"}</td></tr>
                                            <tr><td><strong>Username</strong></td><td>:</td><td>@{panic.citizenUsername || ""}</td></tr>
                                            <tr><td><strong>Alamat Rumah</strong></td><td>:</td><td>{panic.citizenAlamat || "Lokasi GPS Terlampir"}</td></tr>
                                            <tr><td><strong>No. Tlp</strong></td><td>:</td><td>{panic.citizenPhone || ""}</td></tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* KARTU OFFICER */}
                            <div className="panic-info-card officer-border">
                                <div className="card-icon-header">
                                    <span className="icon">👮</span>
                                    <h4>Petugas Respon</h4>
                                </div>
                                <div className="card-body">
                                    <table className="mini-table">
                                        <tbody>
                                            <tr><td><strong>Nama</strong></td><td>:</td><td>{panic.assigned_officer_name_snap || panic.officerNama || "Belum ada petugas"}</td></tr>
                                            <tr><td><strong>Username</strong></td><td>:</td><td>@{panic.officerUsername || "-"}</td></tr>
                                            <tr><td><strong>Terakhir Update</strong></td><td>:</td><td>{fmt(panic.officerLastUpdatedAt)}</td></tr>
                                             <tr><td><strong>Alamat Rumah</strong></td><td>:</td><td>{panic.officerAlamat || "Lokasi GPS Terlampir"}</td></tr>
                                            <tr><td><strong>No. Tlp</strong></td><td>:</td><td>{panic.officerPhone || ""}</td></tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* KARTU TIMELINE */}
                            <div className="panic-info-card timeline-border">
                                <div className="card-icon-header">
                                    <span className="icon">🕒</span>
                                    <h4>Timeline Kejadian</h4>
                                </div>
                                <div className="card-body">
                                    <table className="mini-table">
                                        <tbody>
                                            <tr><td>Dibuat</td><td>:</td><td>{fmt(panic.created_at)}</td></tr>
                                            <tr><td>Direspon</td><td>:</td><td>{fmt(panic.responded_at)}</td></tr>
                                            <tr><td>Selesai</td><td>:</td><td>{fmt(panic.resolved_at)}</td></tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                        {/* MAP DENGAN GARIS RUTE */}
                        <div className="panic-map-section">
                            <div className="map-card-header">
                                <h3>Visualisasi Lokasi & Rute Penyelamatan</h3>
                                <p>Titik  <span style={{ color: '#d90429', fontWeight: 'bold' }}>Merah</span>: Citizen | Titik <span style={{ color: '#1d4ed8', fontWeight: 'bold' }}>Biru</span>: Officer</p>
                            </div>
                            <div className="map-frame">
                                <MapContainer center={center} zoom={15} className="leaflet-container-custom">
                                    <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

                                    {/* RUTE JALAN ASLI */}
                                    {citizenPos && officerPos && (
                                        <RoutingMachine waypoint1={officerPos} waypoint2={citizenPos} />
                                    )}

                                    {/* Marker tetap ditampilkan sebagai titik akhir */}
                                    {citizenPos && (
                                        <CircleMarker center={citizenPos} radius={10} pathOptions={{ color: "#d90429", fillColor: "#d90429", fillOpacity: 1 }}>
                                            <Popup><b>Lokasi Kejadian (Citizen)</b></Popup>
                                        </CircleMarker>
                                    )}

                                    {officerPos && (
                                        <CircleMarker center={officerPos} radius={10} pathOptions={{ color: "#1d4ed8", fillColor: "#1d4ed8", fillOpacity: 1 }}>
                                            <Popup><b>Posisi Petugas</b></Popup>
                                        </CircleMarker>
                                    )}
                                </MapContainer>
                            </div>
                        </div>

                        {/* DISPATCH TARGETS */}
                        <div className="panic-dispatch-section">
                            <h3>Petugas Terdekat (Dispatch Targets)</h3>
                            <div className="dispatch-table-wrapper">
                                <table className="panic-table">
                                    <thead>
                                        <tr>
                                            <th>Nama Officer</th>
                                            <th>Username</th>
                                            <th>Jarak Saat Alert</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {targets.length === 0 ? (
                                            <tr><td colSpan="3" style={{ textAlign: 'center' }}>Tidak ada data dispatch.</td></tr>
                                        ) : (
                                            targets.map((t) => (
                                                <tr key={t.officerId}>
                                                    <td>{t.nama}</td>
                                                    <td>@{t.username}</td>
                                                    <td>{t.distanceM} meter</td>
                                                </tr>
                                            ))
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminPanicAlertDetailPage;