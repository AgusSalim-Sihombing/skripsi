import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import {
  fetchAdminCommunities,
  takedownCommunity,
  restoreCommunity,
} from "../../../../../services/communityAdminService";

// Objek Style untuk kebersihan kode
const styles = {
  container: { padding: "24px", background: "#f8fafc", minHeight: "100vh" },
  header: { marginBottom: "24px" },
  title: { fontSize: "28px", fontWeight: "800", color: "#1e293b", margin: 0 },
  subtitle: { color: "#64748b", marginTop: "4px" },
  filterCard: {
    display: "flex",
    gap: "12px",
    marginBottom: "20px",
    background: "#fff",
    padding: "16px",
    borderRadius: "12px",
    boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
  },
  input: {
    flex: 1,
    padding: "10px 16px",
    borderRadius: "8px",
    border: "1px solid #a0c6f8",
    outline: "none",
    fontSize: "14px",
    background: "white",
    color: "black"
  },
  select: {
    padding: "10px 16px",
    borderRadius: "8px",
    border: "1px solid #e2e8f0",
    background: "#fff",
    cursor: "pointer",
    color: "black"
  },
  tableWrapper: {
    background: "#fff",
    borderRadius: "12px",
    boxShadow: "0 4px 6px -1px rgba(0,0,0,0.1)",
    overflow: "hidden",
  },
  table: { width: "100%", borderCollapse: "collapse", textAlign: "left" },
  th: {
    background: "#f1f5f9",
    padding: "14px",
    color: "#475569",
    fontSize: "12px",
    textTransform: "uppercase",
    letterSpacing: "0.05em",
  },
  td: { padding: "14px", borderBottom: "1px solid #f1f5f9", color: "#1e293b", fontSize: "14px" },
  btnMonitor: {
    padding: "6px 12px",
    borderRadius: "6px",
    border: "1px solid #e2e8f0",
    background: "#fff",
    fontWeight: "600",
    cursor: "pointer",
    transition: "0.2s",
    color:"black",
  },
};

const AdminKomunitasListPage = () => {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(1);
  const [limit] = useState(20);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetchAdminCommunities({ search, status, page, limit });
      setRows(res.data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [search, status, page]);

  const onTakedown = async (id) => {
    const reason = prompt("Alasan takedown? (wajib)");
    if (!reason?.trim()) return;
    try {
      await takedownCommunity(id, reason);
      load();
    } catch (e) { console.error(e); }
  };

  const onRestore = async (id) => {
    if (window.confirm("Restore komunitas ini?")) {
      try {
        await restoreCommunity(id);
        load();
      } catch (e) { console.error(e); }
    }
  };

  const renderBadge = (s) => {
    const isTakedown = s === "takedown";
    return (
      <span style={{
        padding: "4px 10px",
        borderRadius: "99px",
        fontSize: "11px",
        fontWeight: "800",
        background: isTakedown ? "#fee2e2" : "#dcfce7",
        color: isTakedown ? "#991b1b" : "#166534",
        border: `1px solid ${isTakedown ? "#fecaca" : "#bbf7d0"}`
      }}>
        {isTakedown ? "🚫 TAKEDOWN" : "✅ ACTIVE"}
      </span>
    );
  };

  return (
    <AdminLayout>
      <div style={styles.container}>
        <header style={styles.header}>
          <h1 style={styles.title}>Manajemen Komunitas</h1>
          <p style={styles.subtitle}>Pantau aktivitas grup dan kelola kebijakan konten komunitas.</p>
        </header>

        <div style={styles.filterCard}>
          <input
            style={styles.input}
            value={search}
            onChange={(e) => { setPage(1); setSearch(e.target.value); }}
            placeholder="Cari nama komunitas..."
          />
          <select
            style={styles.select}
            value={status}
            onChange={(e) => { setPage(1); setStatus(e.target.value); }}
          >
            <option value="">Semua Status</option>
            <option value="active">🟢 Aktif</option>
            <option value="takedown">🚫 Takedown</option>
          </select>
        </div>

        <div style={styles.tableWrapper}>
          {loading ? (
            <div style={{ padding: "40px", textAlign: "center", color: "#64748b" }}>Memuat data komunitas...</div>
          ) : (
            <>
              <table style={styles.table}>
                <thead>
                  <tr>
                    <th style={styles.th}>Nama Komunitas</th>
                    <th style={styles.th}>Status</th>
                    <th style={styles.th}>Pemilik</th>
                    <th style={styles.th}>Anggota</th>
                    <th style={styles.th}>Pesan Terakhir</th>
                    <th style={styles.th}>Tindakan</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((c) => (
                    <tr key={c.id}>
                      <td style={{ ...styles.td, fontWeight: "700", color: "#0f172a" }}>{c.name}</td>
                      <td style={styles.td}>{renderBadge(c.status)}</td>
                      <td style={styles.td}>@{c.owner_username}</td>
                      <td style={styles.td}>{c.member_count}</td>
                      <td style={{ ...styles.td, fontSize: "12px", color: "#64748b" }}>
                        {c.last_message_at ? new Date(c.last_message_at).toLocaleString("id-ID") : "-"}
                      </td>
                      <td style={{ ...styles.td, display: "flex", gap: "8px" }}>
                        <button
                          style={styles.btnMonitor}
                          onClick={() => navigate(`/admin/komunitas/${c.id}`)}
                        >
                          Monitor
                        </button>
                        {c.status === "active" ? (
                          <button
                            onClick={() => onTakedown(c.id)}
                            style={{ ...styles.btnMonitor, background: "#ef4444", color: "#fff", borderColor: "#ef4444" }}
                          >
                            Takedown
                          </button>
                        ) : (
                          <button
                            onClick={() => onRestore(c.id)}
                            style={{ ...styles.btnMonitor, background: "#22c55e", color: "#fff", borderColor: "#22c55e" }}
                          >
                            Restore
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {!rows.length && (
                <div style={{ padding: "40px", textAlign: "center", color: "#94a3b8" }}>Tidak ada komunitas ditemukan.</div>
              )}

              <div style={{ padding: "16px", display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #f1f5f9" }}>
                <button
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(p - 1, 1))}
                  style={{ ...styles.btnMonitor, opacity: page <= 1 ? 0.5 : 1 }}
                >
                  Sebelumnya
                </button>
                <div style={{ fontWeight: "600", color: "#64748b" }}>Halaman {page}</div>
                <button
                  disabled={rows.length < limit}
                  onClick={() => setPage((p) => p + 1)}
                  style={{ ...styles.btnMonitor, opacity: rows.length < limit ? 0.5 : 1 }}
                >
                  Selanjutnya
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </AdminLayout>
  );
};

export default AdminKomunitasListPage;