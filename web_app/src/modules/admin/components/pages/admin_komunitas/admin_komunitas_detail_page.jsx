import React, { useEffect, useState, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import {
    fetchAdminCommunityDetail,
    fetchAdminCommunityMessages,
    takedownCommunity,
    restoreCommunity,
    deleteCommunityMessage,
} from "../../../../../services/communityAdminService";

const AdminKomunitasDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [detail, setDetail] = useState(null);
    const [messages, setMessages] = useState([]);
    const [page, setPage] = useState(1);
    const [limit] = useState(50);
    const [loading, setLoading] = useState(true);

    const load = useCallback(async () => {
        if (!id) return;
        setLoading(true);
        try {
            const d = await fetchAdminCommunityDetail(id);
            const m = await fetchAdminCommunityMessages(id, { page, limit });

            setDetail(d?.data || null);
            setMessages(m?.data || []);
        } catch (e) {
            console.error(e);
            alert("Gagal ambil detail / messages komunitas");
        } finally {
            setLoading(false);
        }
    }, [id, page, limit]);

    useEffect(() => {
        load();
    }, [load]);

    const onTakedown = async () => {
        const reasonRaw = prompt(
            "Alasan takedown?",
            detail?.takedown_reason || "Pelanggaran aturan"
        );
        if (reasonRaw === null) return;

        const reason = reasonRaw.trim();
        if (!reason) {
            alert("Alasan takedown wajib diisi");
            return;
        }

        try {
            const res = await takedownCommunity(id, reason);
            alert(res.message || "Komunitas berhasil ditakedown");
            await load();
        } catch (e) {
            console.error(e);
            alert(e?.response?.data?.message || "Gagal takedown");
        }
    };

    const onRestore = async () => {
        if (!window.confirm("Restore komunitas ini?")) return;
        try {
            const res = await restoreCommunity(id);
            alert(res.message || "Komunitas berhasil direstore");
            await load();
        } catch (e) {
            console.error(e);
            alert(e?.response?.data?.message || "Gagal restore");
        }
    };

    const onDeleteMsg = async (msgId) => {
        const reasonRaw = prompt("Alasan hapus pesan?", "Melanggar aturan");
        if (reasonRaw === null) return;

        const reason = reasonRaw.trim();
        if (!reason) {
            alert("Alasan hapus pesan wajib diisi");
            return;
        }

        try {
            const res = await deleteCommunityMessage(msgId, reason);
            alert(res.message || "Pesan berhasil dihapus");
            await load();
        } catch (e) {
            console.error(e);
            alert(e?.response?.data?.message || "Gagal hapus pesan");
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <p>Memuat...</p>
            </AdminLayout>
        );
    }

    if (!detail) {
        return (
            <AdminLayout>
                <p>Komunitas tidak ditemukan.</p>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="komunitas-page">
                <div
                    className="dashboard-header"
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                    }}
                >
                    <div>
                        <h1>Monitor Komunitas</h1>
                        <p style={{ margin: 0 }}>Pantau chat + moderasi.</p>
                    </div>

                    <button
                        onClick={() => navigate("/admin/komunitas")}
                        style={{
                            padding: "10px 12px",
                            borderRadius: 10,
                            border: "1px solid #ddd",
                            background: "#fff",
                            color: "black",
                        }}
                    >
                        ← Back
                    </button>
                </div>

                {detail.status === "takedown" && (
                    <div
                        style={{
                            background: "#fff1f2",
                            border: "1px solid #fecdd3",
                            color: "#b42318",
                            padding: "12px 14px",
                            borderRadius: 12,
                            marginBottom: 14,
                            fontWeight: 600,
                        }}
                    >
                        Komunitas ini sedang ditakedown admin.
                        {detail.takedown_reason ? ` Alasan: ${detail.takedown_reason}` : ""}
                    </div>
                )}

                <div style={{ background: "#fff", borderRadius: 14, padding: 14, marginBottom: 14 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
                        <div>
                            <div style={{ fontWeight: 800, fontSize: 18, color: "#777" }}>{detail.name}</div>
                            <div style={{ color: "#666", marginTop: 4 }}>
                                Owner: <b>{detail.owner_username}</b> • Members: <b>{detail.member_count}</b>
                            </div>
                            <div style={{ color: "#666", marginTop: 4 }}>
                                Status: <b>{detail.status}</b>
                                {detail.status === "takedown" && detail.takedown_reason ? (
                                    <>
                                        {" "}
                                        • Reason: <b style={{ color: "#b00020" }}>{detail.takedown_reason}</b>
                                    </>
                                ) : null}
                            </div>
                        </div>

                        <div style={{ display: "flex", gap: 10 }}>
                            {detail.status === "active" ? (
                                <button
                                    onClick={onTakedown}
                                    style={{
                                        padding: "10px 12px",
                                        borderRadius: 10,
                                        border: "1px solid #b00020",
                                        background: "#ffe1e1",
                                        color: "#b00020",
                                        fontWeight: 800,
                                    }}
                                >
                                    Takedown
                                </button>
                            ) : (
                                <button
                                    onClick={onRestore}
                                    style={{
                                        padding: "10px 12px",
                                        borderRadius: 10,
                                        border: "1px solid #0b7a2a",
                                        background: "#e6fff1",
                                        color: "#0b7a2a",
                                        fontWeight: 800,
                                    }}
                                >
                                    Restore
                                </button>
                            )}
                        </div>
                    </div>
                </div>

                <div style={{ background: "#fff", borderRadius: 14, padding: 14 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
                        <div style={{ fontWeight: 800, color: "black" }}>Chat (newest)</div>
                        <div style={{ display: "flex", gap: 8 }}>
                            <button
                                disabled={page <= 1}
                                onClick={() => setPage((p) => Math.max(p - 1, 1))}
                                style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ddd", background: "#fff", color: "black" }}
                            >
                                Prev
                            </button>
                            <button
                                disabled={messages.length < limit}
                                onClick={() => setPage((p) => p + 1)}
                                style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ddd", background: "#fff", color: "black" }}
                            >
                                Next
                            </button>
                        </div>
                    </div>

                    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                        {messages.map((m) => {
                            const deleted = m.is_deleted === 1 || m.is_deleted === true;

                            return (
                                <div
                                    key={m.id}
                                    style={{
                                        border: "1px solid #eee",
                                        borderRadius: 12,
                                        padding: 12,
                                        background: deleted ? "#fafafa" : "#fff",
                                    }}
                                >
                                    <div style={{ display: "flex", justifyContent: "space-between", gap: 10 }}>
                                        <div style={{ fontWeight: 800, color: "#5e5e5e" }}>
                                            @{m.username}{" "}
                                            <span style={{ fontWeight: 400, color: "#777", marginLeft: 8 }}>
                                                {new Date(m.created_at).toLocaleString()}
                                            </span>
                                        </div>

                                        {!deleted ? (
                                            <button
                                                onClick={() => onDeleteMsg(m.id)}
                                                style={{
                                                    padding: "6px 10px",
                                                    borderRadius: 10,
                                                    border: "1px solid #b00020",
                                                    background: "#ffe1e1",
                                                    color: "#b00020",
                                                    fontWeight: 800,
                                                }}
                                            >
                                                Delete
                                            </button>
                                        ) : (
                                            <span style={{ color: "#b00020", fontWeight: 800 }}>
                                                deleted ({m.deleted_by}){m.deleted_reason ? ` • ${m.deleted_reason}` : ""}
                                            </span>
                                        )}
                                    </div>

                                    <div style={{ marginTop: 8, color: deleted ? "#999" : "#111" }}>
                                        {deleted ? <i>(pesan dihapus)</i> : m.message}
                                    </div>
                                </div>
                            );
                        })}

                        {!messages.length && <div style={{ color: "#000000" }}>Belum ada pesan.</div>}
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminKomunitasDetailPage;
