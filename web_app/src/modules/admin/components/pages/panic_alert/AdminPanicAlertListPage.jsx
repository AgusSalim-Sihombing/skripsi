import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import { fetchPanicAlerts } from "../../../../../services/panicAlertService";
import "./AdminPanicList.css"
const fmt = (d) => (d ? new Date(d).toLocaleString() : "-");

const AdminPanicAlertListPage = () => {
    const navigate = useNavigate();
    const [rows, setRows] = useState([]);
    const [status, setStatus] = useState("");
    const [search, setSearch] = useState("");
    const [page] = useState(1);
    const [limit] = useState(20);
    const [loading, setLoading] = useState(true);

    const load = async () => {
        setLoading(true);
        try {
            const res = await fetchPanicAlerts({ status, search, page, limit });
            if (res?.success) setRows(res.data || []);
            else setRows([]);
        } catch (e) {
            console.error(e);
            if (e?.response?.status === 401) navigate("/login-admin");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []); // initial
    useEffect(() => { load(); }, [status]); // filter status auto load

    return (
        <AdminLayout>
            <div className="dashboard-header" style={{color:"black"}}>
                <h1>Panic Alert</h1>
                <p>Semua panic button dari masyarakat + officer yang merespon.</p>
            </div>

            <div style={{ display: "flex", gap: 12, marginBottom: 12 }}>
                <select value={status} onChange={(e) => setStatus(e.target.value)}>
                    <option value="">Semua Status</option>
                    <option value="OPEN">OPEN</option>
                    <option value="ASSIGNED">ASSIGNED</option>
                    <option value="RESOLVED">RESOLVED</option>
                </select>

                <input
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="Cari panicId / nama citizen / officer / username..."
                    style={{ flex: 1 }}
                />
                <button onClick={load}>Cari</button>
            </div>

            {loading ? (
                <p>Loading...</p>
            ) : (
                <div className="table-wrap">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Status</th>
                                <th>Masyarakat</th>
                                <th>Officer</th>
                                <th>Created</th>
                                <th>Responded</th>
                                <th>Resolved</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            {rows.length === 0 ? (
                                <tr><td colSpan="8">Belum ada panic.</td></tr>
                            ) : (
                                rows.map((r) => (
                                    <tr key={r.panicId}>
                                        <td>{r.panicId}</td>
                                        <td>{r.status}</td>
                                        <td>{r.citizenName || "-"} <div style={{ color: "#777", fontSize: 12 }}>{r.citizenUsername || ""}</div></td>
                                        <td>{r.officerName || "-"} <div style={{ color: "#777", fontSize: 12 }}>{r.officerUsername || ""}</div></td>
                                        <td>{fmt(r.created_at)}</td>
                                        <td>{fmt(r.responded_at)}</td>
                                        <td>{fmt(r.resolved_at)}</td>
                                        <td>
                                            <button onClick={() => navigate(`/admin/panic-alert/${r.panicId}`)}>
                                                Detail
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminPanicAlertListPage;
