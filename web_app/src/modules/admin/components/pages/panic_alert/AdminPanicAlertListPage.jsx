import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import { fetchPanicAlerts } from "../../../../../services/panicAlertService";
import "./AdminPanicList.css";

const fmt = (d) => (d ? new Date(d).toLocaleString("id-ID") : "-");

const AdminPanicAlertListPage = () => {
    const navigate = useNavigate();
    const [rows, setRows] = useState([]);
    const [status, setStatus] = useState("");
    const [search, setSearch] = useState("");
    const [loading, setLoading] = useState(true);

    const load = async () => {
        setLoading(true);
        try {
            const res = await fetchPanicAlerts({ status, search, page: 1, limit: 20 });
            if (res?.success) setRows(res.data || []);
            else setRows([]);
        } catch (e) {
            if (e?.response?.status === 401) navigate("/login-admin");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);
    useEffect(() => { load(); }, [status]);

    return (
        <AdminLayout>
            <div className="panic-page-container">
                <header className="panic-page-header">
                    <div className="panic-header-content">
                        <h1>Panic Alert System</h1>
                        <p>Monitoring real-time tombol darurat masyarakat dan respon petugas lapangan.</p>
                    </div>
                </header>

                <div className="panic-page-filter-card">
                    <div className="panic-filter-wrapper">
                        <select
                            className="panic-input-select"
                            value={status}
                            onChange={(e) => setStatus(e.target.value)}
                        >
                            <option value="">Semua Status</option>
                            <option value="OPEN">🔴 OPEN</option>
                            <option value="ASSIGNED">🟡 ASSIGNED</option>
                            <option value="RESOLVED">🟢 RESOLVED</option>
                        </select>

                        <div className="panic-search-group">
                            <input
                                className="panic-input-text"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                placeholder="Cari ID, Nama Citizen, Officer..."
                            />
                            <button className="panic-btn-search" onClick={load}>Cari</button>
                        </div>
                    </div>
                </div>

                {loading ? (
                    <div className="panic-loading-state">
                        <div className="panic-spinner"></div>
                        <p>Sinkronisasi data darurat...</p>
                    </div>
                ) : (
                    <div className="panic-table-card">
                        <div className="panic-table-wrapper">
                            <table className="panic-custom-table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Status</th>
                                        <th>Masyarakat</th>
                                        <th>Petugas Respon</th>
                                        <th>Waktu Alert</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {rows.length === 0 ? (
                                        <tr><td colSpan="6" className="panic-empty">Tidak ada alert darurat ditemukan.</td></tr>
                                    ) : (
                                        rows.map((r) => (
                                            <tr key={r.panicId}>
                                                <td className="panic-td-id">#{r.panicId}</td>
                                                <td>
                                                    <span className={`panic-badge panic-badge-${r.status?.toLowerCase()}`}>
                                                        {r.status}
                                                    </span>
                                                </td>
                                                <td>
                                                    <div className="panic-user-info">
                                                        <span className="panic-user-name">{r.citizenName || "Anonim"}</span>
                                                        <span className="panic-user-sub">@{r.citizenUsername}</span>
                                                    </div>
                                                </td>
                                                <td>
                                                    {r.officerName ? (
                                                        <div className="panic-user-info">
                                                            <span className="panic-user-name">{r.officerName}</span>
                                                            <span className="panic-user-sub">@{r.officerUsername}</span>
                                                        </div>
                                                    ) : (
                                                        /* Jika statusnya OPEN dan belum ada petugas, gunakan class blink */
                                                        <span className={r.status === "OPEN" ? "panic-unassigned-blink" : "panic-unassigned"}>
                                                            ⚠️ Menunggu Petugas...
                                                        </span>
                                                    )}
                                                </td>
                                                <td>
                                                    <div className="panic-time-info">
                                                        <span>{fmt(r.created_at)}</span>
                                                    </div>
                                                </td>
                                                <td>
                                                    <button
                                                        className="panic-btn-detail"
                                                        onClick={() => navigate(`/admin/panic-alert/${r.panicId}`)}
                                                    >
                                                        Lihat Detail
                                                    </button>
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminPanicAlertListPage;