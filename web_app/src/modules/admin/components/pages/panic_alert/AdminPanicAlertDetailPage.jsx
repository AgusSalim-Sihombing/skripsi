import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import { fetchPanicAlertDetail } from "../../../../../services/panicAlertService";

import { MapContainer, TileLayer, CircleMarker, Popup } from "react-leaflet";
import "./AdminPanicList.css"

const fmt = (d) => (d ? new Date(d).toLocaleString() : "-");

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
            else setData(null);
        } catch (e) {
            console.error(e);
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
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        return [lat, lng];
    }, [panic]);

    const officerPos = useMemo(() => {
        const lat = Number(panic?.officerLastLat);
        const lng = Number(panic?.officerLastLng);
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        return [lat, lng];
    }, [panic]);

    const center = citizenPos || officerPos || [-6.2, 106.816666];

    return (
        <AdminLayout>
            <div className="dashboard-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                    <h1>Detail Panic #{id}</h1>
                    <p>Status: <b>{panic?.status || "-"}</b></p>
                </div>
                <button onClick={() => navigate("/admin/panic-alert")}>← Kembali</button>
            </div>

            {loading ? (
                <p>Loading...</p>
            ) : !panic ? (
                <p>Data panic tidak ditemukan.</p>
            ) : (
                <>
                    <div className="dashboard-cards" style={{ gridTemplateColumns: "repeat(3, 1fr)" }}>
                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Masyarakat</span>
                            <span className="dashboard-card__value" style={{ fontSize: 16 }}>
                                {panic.citizen_name_snap || panic.citizenNama || "-"}
                            </span>
                            <div style={{ color: "#666", fontSize: 12 }}>{panic.citizenUsername || ""}</div>
                            <div style={{ marginTop: 8, fontSize: 12, color: "#444" }}>
                                Lokasi: {panic.citizen_address_snap || `${panic.citizen_lat}, ${panic.citizen_lng}`}
                            </div>
                        </div>

                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Officer Respon</span>
                            <span className="dashboard-card__value" style={{ fontSize: 16 }}>
                                {panic.assigned_officer_name_snap || panic.officerNama || "-"}
                            </span>
                            <div style={{ color: "#666", fontSize: 12 }}>{panic.officerUsername || ""}</div>
                            <div style={{ marginTop: 8, fontSize: 12, color: "#444" }}>
                                Last GPS: {officerPos ? `${officerPos[0]}, ${officerPos[1]}` : "-"}
                            </div>
                            <div style={{ fontSize: 12, color: "#444" }}>
                                Updated: {fmt(panic.officerLastUpdatedAt)}
                            </div>
                        </div>

                        <div className="dashboard-card">
                            <span className="dashboard-card__label">Timeline</span>
                            <div style={{ marginTop: 8, fontSize: 13, color:"black" }}>
                                Created: <b>{fmt(panic.created_at)}</b><br />
                                Responded: <b>{fmt(panic.responded_at)}</b><br />
                                Resolved: <b>{fmt(panic.resolved_at)}</b>
                            </div>
                        </div>
                    </div>

                    <div className="dashboard-map-card" style={{ marginTop: 16 }}>
                        <div className="dashboard-map-card__header">
                            <div>
                                <h3>Map</h3>
                                <p className="dashboard-map-card__sub">
                                    Marker merah = citizen, marker biru = officer (kalau ada).
                                </p>
                            </div>
                        </div>

                        <div className="dashboard-map-wrapper">
                            <MapContainer center={center} zoom={13} scrollWheelZoom className="dashboard-map">
                                <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

                                {citizenPos && (
                                    <CircleMarker center={citizenPos} radius={8} pathOptions={{ color: "#d90429", fillOpacity: 0.9 }}>
                                        <Popup>
                                            <b>Citizen</b><br />
                                            {panic.citizen_name_snap || "-"}<br />
                                            {panic.citizen_address_snap || ""}
                                        </Popup>
                                    </CircleMarker>
                                )}

                                {officerPos && (
                                    <CircleMarker center={officerPos} radius={8} pathOptions={{ color: "#1d4ed8", fillOpacity: 0.9 }}>
                                        <Popup>
                                            <b>Officer</b><br />
                                            {panic.assigned_officer_name_snap || "-"}<br />
                                            Updated: {fmt(panic.officerLastUpdatedAt)}
                                        </Popup>
                                    </CircleMarker>
                                )}
                            </MapContainer>
                        </div>
                    </div>

                    <div style={{ marginTop: 16 }}>
                        <h3>Dispatch Targets (Officer yang ditawari)</h3>
                        {targets.length === 0 ? (
                            <p>-</p>
                        ) : (
                            <div className="table-wrap">
                                <table className="table">
                                    <thead>
                                        <tr>
                                            <th>Officer</th>
                                            <th>Username</th>
                                            <th>Distance (m)</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {targets.map((t) => (
                                            <tr key={t.officerId}>
                                                <td>{t.nama}</td>
                                                <td>{t.username}</td>
                                                <td>{t.distanceM}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </>
            )}
        </AdminLayout>
    );
};

export default AdminPanicAlertDetailPage;
