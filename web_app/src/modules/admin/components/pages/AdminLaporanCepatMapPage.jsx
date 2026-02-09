import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";

import {
    MapContainer,
    TileLayer,
    Marker,
    Tooltip,
} from "react-leaflet";
import L from "leaflet";

import { getLaporanCepatLocations } from "../../../../services/laporanCepatService";

// perbaiki icon leaflet default
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: markerIcon2x,
    iconUrl: markerIcon,
    shadowUrl: markerShadow,
});

// ICON TANDA TANYA UNTUK LAPORAN PENDING/REVIEW
const questionIcon = new L.DivIcon({
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

const AdminLaporanCepatMapPage = () => {
    const navigate = useNavigate();

    const [locations, setLocations] = useState([]);
    const [loading, setLoading] = useState(true);

    const loadLocations = async () => {
        setLoading(true);
        try {
            const res = await getLaporanCepatLocations();
            if (res.success) {
                setLocations(res.data || []);
            }
        } catch (err) {
            console.error("getLaporanCepatLocations error:", err);
            // kalau token expired, bisa tambahin handle di sini kalau mau
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        const token = localStorage.getItem("sigap_admin_token");
        if (!token) {
            navigate("/login-admin");
            return;
        }
        loadLocations();
    }, [navigate]);

    const mapCenter = useMemo(() => {
        if (locations.length > 0) {
            const first = locations[0];
            return [Number(first.latitude), Number(first.longitude)];
        }
        // fallback: Medan
        return [3.5952, 98.6722];
    }, [locations]);

    const formatTanggalWaktu = (tgl, wkt) => {
        if (!tgl) return "-";
        const t = new Date(tgl);
        const tanggal = t.toLocaleDateString("id-ID");
        const waktu = wkt ? wkt.slice(0, 5) : "";
        return waktu ? `${tanggal} ${waktu}` : tanggal;
    };

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>Peta Laporan Cepat</h1>
                <p>
                    Titik pada peta menunjukkan laporan kejahatan dari pengguna. Ikon tanda
                    tanya menandakan laporan yang masih menunggu validasi/voting.
                </p>
            </div>

            {loading ? (
                <p>Memuat data ...</p>
            ) : locations.length === 0 ? (
                <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
                    Belum ada laporan dengan lokasi yang tercatat.
                </p>
            ) : (
                <div className="dashboard-map">
                    <MapContainer
                        center={mapCenter}
                        zoom={13}
                        scrollWheelZoom
                        style={{ height: "100%", width: "100%" }}
                    >
                        <TileLayer
                            attribution='&copy; OpenStreetMap contributors'
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        />

                        {locations.map((loc) => (
                            <Marker
                                key={loc.id_laporan}
                                position={[
                                    Number(loc.latitude),
                                    Number(loc.longitude),
                                ]}
                                icon={questionIcon}
                                eventHandlers={{
                                    click: () => navigate(`/admin/laporan-cepat/${loc.id_laporan}`),
                                }}
                            >
                                {/* judul laporan selalu tampil di atas marker */}
                                <Tooltip permanent direction="top" offset={[0, -10]}>
                                    <div style={{ fontSize: "0.8rem", fontWeight: 600 }}>
                                        {loc.judul_laporan}
                                    </div>
                                </Tooltip>
                            </Marker>
                        ))}
                    </MapContainer>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminLaporanCepatMapPage;
