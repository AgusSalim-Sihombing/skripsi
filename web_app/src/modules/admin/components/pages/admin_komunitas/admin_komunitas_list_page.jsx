import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import {
  fetchAdminCommunities,
  takedownCommunity,
  restoreCommunity,
} from "../../../../../services/communityAdminService";

const AdminKomunitasListPage = () => {
  const navigate = useNavigate();

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState(""); // "" | active | takedown
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
      alert("Gagal ambil komunitas admin");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, status, page]);

  const onTakedown = async (id) => {
    const reason = prompt("Alasan takedown? (wajib)", "Pelanggaran aturan");
    if (!reason) return;
    try {
      await takedownCommunity(id, reason);
      await load();
    } catch (e) {
      console.error(e);
      alert("Gagal takedown komunitas");
    }
  };

  const onRestore = async (id) => {
    if (!confirm("Restore komunitas ini?")) return;
    try {
      await restoreCommunity(id);
      await load();
    } catch (e) {
      console.error(e);
      alert("Gagal restore komunitas");
    }
  };

  const badge = (s) => {
    const base = {
      padding: "4px 10px",
      borderRadius: 999,
      fontSize: 12,
      fontWeight: 700,
      display: "inline-block",
    };
    if (s === "takedown") return <span style={{ ...base, background: "#ffe1e1", color: "#b00020" }}>TAKEDOWN</span>;
    return <span style={{ ...base, background: "#e6fff1", color: "#0b7a2a" }}>ACTIVE</span>;
  };

  return (
    <AdminLayout>
      <div className="dashboard-header">
        <h1>Komunitas</h1>
        <p>Admin bisa pantau semua komunitas + takedown kalau perlu.</p>
      </div>

      <div style={{ display: "flex", gap: 12, marginBottom: 14 }}>
        <input
          value={search}
          onChange={(e) => { setPage(1); setSearch(e.target.value); }}
          placeholder="Cari nama komunitas..."
          style={{ flex: 1, padding: 10, borderRadius: 10, border: "1px solid #ddd" }}
        />
        <select
          value={status}
          onChange={(e) => { setPage(1); setStatus(e.target.value); }}
          style={{ padding: 10, borderRadius: 10, border: "1px solid #ddd" }}
        >
          <option value="">Semua</option>
          <option value="active">Active</option>
          <option value="takedown">Takedown</option>
        </select>
      </div>

      {loading ? (
        <p>Memuat...</p>
      ) : (
        <div style={{ background: "#fff", borderRadius: 14, padding: 12, overflow: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ textAlign: "left", borderBottom: "1px solid #eee" }}>
                <th style={{ padding: 10 }}>Nama</th>
                <th style={{ padding: 10 }}>Status</th>
                <th style={{ padding: 10 }}>Owner</th>
                <th style={{ padding: 10 }}>Members</th>
                <th style={{ padding: 10 }}>Last chat</th>
                <th style={{ padding: 10 }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((c) => (
                <tr key={c.id} style={{ borderBottom: "1px solid #f3f3f3" }}>
                  <td style={{ padding: 10, fontWeight: 700 }}>{c.name}</td>
                  <td style={{ padding: 10 }}>{badge(c.status)}</td>
                  <td style={{ padding: 10 }}>{c.owner_username}</td>
                  <td style={{ padding: 10 }}>{c.member_count}</td>
                  <td style={{ padding: 10 }}>
                    {c.last_message_at ? new Date(c.last_message_at).toLocaleString() : "-"}
                  </td>
                  <td style={{ padding: 10, display: "flex", gap: 8, flexWrap: "wrap" }}>
                    <button
                      onClick={() => navigate(`/admin/komunitas/${c.id}`)}
                      style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ddd", background: "#f7f7f7", color: "black" }}
                    >
                      Monitor
                    </button>

                    {c.status === "active" ? (
                      <button
                        onClick={() => onTakedown(c.id)}
                        style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #b00020", background: "#ffe1e1", color: "#b00020", fontWeight: 700 }}
                      >
                        Takedown
                      </button>
                    ) : (
                      <button
                        onClick={() => onRestore(c.id)}
                        style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #0b7a2a", background: "#e6fff1", color: "#0b7a2a", fontWeight: 700 }}
                      >
                        Restore
                      </button>
                    )}
                  </td>
                </tr>
              ))}

              {!rows.length && (
                <tr>
                  <td colSpan={6} style={{ padding: 14, color: "#666" }}>Tidak ada komunitas.</td>
                </tr>
              )}
            </tbody>
          </table>

          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 12 }}>
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(p - 1, 1))}
              style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ddd", background: "#fff", color: "black" }}
            >
              Prev
            </button>
            <div style={{ color: "#666" }}>Page: {page}</div>
            <button
              disabled={rows.length < limit}
              onClick={() => setPage((p) => p + 1)}
              style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #ddd", background: "#fff", color: "black" }}
            >
              Next
            </button>
          </div>
        </div>
      )}
    </AdminLayout>
  );
};

export default AdminKomunitasListPage;
