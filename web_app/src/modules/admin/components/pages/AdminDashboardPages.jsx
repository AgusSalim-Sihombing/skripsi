import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import { getDashboardSummary } from "../../../../services/dashboardService";
import { fetchZonaBahaya } from "../../../../services/zonaBahayaService";

// import { MapContainer, TileLayer, Circle, CircleMarker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";

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

const AdminDashboardPage = () => {
    const navigate = useNavigate();
    const [selectedId, setSelectedId] = useState(null);
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

    return (
        <AdminLayout>
            <div className="beranda">
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
                                    // <MapContainer
                                    //     center={mapCenter}
                                    //     zoom={6}
                                    //     scrollWheelZoom
                                    //     className="dashboard-map"

                                    // >
                                    //     <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

                                    //     {zones
                                    //         .map((z) => ({
                                    //             ...z,
                                    //             lat: Number(z.latitude),
                                    //             lng: Number(z.longitude),
                                    //             radius: Number(z.radius_meter || 0),
                                    //             statusNorm: normalizeStatus(z.status_zona),
                                    //         }))
                                    //         .filter((z) => Number.isFinite(z.lat) && Number.isFinite(z.lng))
                                    //         .map((z) => (
                                    //             <React.Fragment key={z.id_zona}>
                                    //                 <Circle
                                    //                     center={[z.lat, z.lng]}
                                    //                     radius={z.radius}
                                    //                     pathOptions={zoneStyle(z)}
                                    //                 />

                                    //                 <CircleMarker
                                    //                     center={[z.lat, z.lng]}
                                    //                     radius={7}
                                    //                     pathOptions={{
                                    //                         color: (z.warna_hex || "#FF0000").toString(),
                                    //                         fillColor: (z.warna_hex || "#FF0000").toString(),
                                    //                         fillOpacity: 0.9,
                                    //                     }}
                                    //                 >
                                    //                     <Popup>
                                    //                         <div style={{ minWidth: 220 }}>
                                    //                             <div style={{ fontWeight: 700, marginBottom: 6 }}>
                                    //                                 {z.nama_zona || "Zona Bahaya"}
                                    //                             </div>
                                    //                             <div style={{ fontSize: 13, marginBottom: 6 }}>
                                    //                                 Status: <b>{z.statusNorm}</b>
                                    //                             </div>
                                    //                             <div style={{ fontSize: 13 }}>
                                    //                                 Risiko: <b>{z.tingkat_risiko || "-"}</b>
                                    //                             </div>
                                    //                             <div style={{ fontSize: 13 }}>
                                    //                                 Radius: <b>{z.radius} m</b>
                                    //                             </div>
                                    //                             <div style={{ fontSize: 12, marginTop: 6, color: "#444" }}>
                                    //                                 {z.deskripsi || ""}
                                    //                             </div>
                                    //                         </div>
                                    //                     </Popup>
                                    //                 </CircleMarker>
                                    //             </React.Fragment>
                                    //         ))}
                                    // </MapContainer>
                                    <MapContainer
                                        center={mapCenter}
                                        zoom={7}
                                        style={{ height: "100%", width: "100%" }}
                                    >
                                        {/* <ZonaClickHandler
                                            enabled={clickMode === "MARK"}
                                            onMapClick={handleMapClick}
                                        /> */}

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

                                                    {/* <Popup>
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
                                    
                                                                                        <button
                                                                                            type="button"
                                                                                            onClick={() => navigate(`/admin/zona-bahaya/semua/${z.id_zona}`)}
                                                                                            className="btn btn-outline"
                                                                                            style={{
                                                                                                padding: "0.2rem 0.5rem",
                                                                                                fontSize: "0.8rem",
                                                                                            }}
                                                                                        >
                                                                                            Lihat Detail
                                                                                        </button>
                                                                                    </div>
                                                                                </Popup> */}
                                                    <Popup>
                                                        <div style={{ maxWidth: 220, fontFamily: 'sans-serif' }}>
                                                            <strong style={{ fontSize: '1.1rem', color: '#1e293b', display: 'block', marginBottom: '8px' }}>
                                                                {z.nama_zona}
                                                            </strong>

                                                            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem', marginBottom: '8px' }}>
                                                                <tbody>
                                                                    <tr>
                                                                        <td style={{ padding: '2px 0', color: '#64748b' }}>Status</td>
                                                                        <td style={{ padding: '2px 4px' }}>:</td>
                                                                        <td style={{ padding: '2px 0' }}><b>{z.status_zona}</b></td>
                                                                    </tr>
                                                                    <tr>
                                                                        <td style={{ padding: '2px 0', color: '#64748b' }}>Risiko</td>
                                                                        <td style={{ padding: '2px 4px' }}>:</td>
                                                                        <td style={{ padding: '2px 0' }}><b>{z.tingkat_risiko}</b></td>
                                                                    </tr>
                                                                    <tr>
                                                                        <td style={{ padding: '2px 0', color: '#64748b' }}>Radius</td>
                                                                        <td style={{ padding: '2px 4px' }}>:</td>
                                                                        <td style={{ padding: '2px 0' }}>{z.radius_meter} m</td>
                                                                    </tr>
                                                                    {z.tanggal_kejadian && (
                                                                        <tr>
                                                                            <td style={{ padding: '2px 0', color: '#64748b' }}>Tanggal</td>
                                                                            <td style={{ padding: '2px 4px' }}>:</td>
                                                                            <td style={{ padding: '2px 0' }}>{z.tanggal_kejadian}</td>
                                                                        </tr>
                                                                    )}
                                                                    {z.waktu_kejadian && (
                                                                        <tr>
                                                                            <td style={{ padding: '2px 0', color: '#64748b' }}>Waktu</td>
                                                                            <td style={{ padding: '2px 4px' }}>:</td>
                                                                            <td style={{ padding: '2px 0' }}>{z.waktu_kejadian.slice(0, 5)}</td>
                                                                        </tr>
                                                                    )}
                                                                    <tr>
                                                                        <td style={{ padding: '2px 0', color: '#64748b', verticalAlign: 'top' }}>Koordinat</td>
                                                                        <td style={{ padding: '2px 4px', verticalAlign: 'top' }}>:</td>
                                                                        <td style={{ padding: '2px 0' }}>
                                                                            {Number(z.latitude).toFixed(5)},<br />
                                                                            {Number(z.longitude).toFixed(5)}
                                                                        </td>
                                                                    </tr>
                                                                </tbody>
                                                            </table>

                                                            {z.deskripsi && (
                                                                <div style={{
                                                                    borderTop: '1px solid #e2e8f0',
                                                                    paddingTop: '8px',
                                                                    marginTop: '8px',
                                                                    fontSize: '0.8rem',
                                                                    color: '#475569',
                                                                    fontStyle: 'italic',
                                                                    lineHeight: '1.4'
                                                                }}>
                                                                    {z.deskripsi}
                                                                </div>
                                                            )}

                                                            <button
                                                                type="button"
                                                                onClick={() => navigate(`/admin/zona-bahaya/semua/${z.id_zona}`)}
                                                                className="btn btn-primary"
                                                                style={{
                                                                    width: '100%',
                                                                    marginTop: '10px',
                                                                    padding: '0.4rem',
                                                                    fontSize: '0.8rem',
                                                                    borderRadius: '4px',
                                                                    cursor: 'pointer'
                                                                }}
                                                            >
                                                                Lihat Detail Zona
                                                            </button>
                                                        </div>
                                                    </Popup>
                                                </Marker>
                                            </React.Fragment>
                                        ))}

                                        {/* {!selectedId && form.latitude && form.longitude && (
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
                                        )} */}
                                    </MapContainer>
                                )}
                            </div>
                        </div>
                    </>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminDashboardPage;
