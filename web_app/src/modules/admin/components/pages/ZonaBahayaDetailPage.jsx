import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import {
    fetchZonaBahayaDetail,
    fetchZonaBahayaVoteSummary,
    updateZonaBahayaStatus,
} from "../../../../services/zonaBahayaService";

const ZonaBahayaDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [zone, setZone] = useState(null);
    const [summary, setSummary] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const toInt = (value) => {
        if (value == null) return 0;
        if (typeof value === "number") return Math.round(value);
        if (typeof value === "string") return parseInt(value, 10) || 0;
        return 0;
    };

    const loadData = async () => {
        setLoading(true);
        setErrorMsg("");
        setSuccessMsg("");

        try {
            const [detailRes, summaryRes] = await Promise.all([
                fetchZonaBahayaDetail(id),
                fetchZonaBahayaVoteSummary(id)
            ]);

            if (!detailRes.success) {
                setErrorMsg(detailRes.message || "Gagal mengambil detail zona");
                return;
            }

            setZone(detailRes.data);

            if (summaryRes.success) {
                setSummary(summaryRes.data || {});
            } else {
                setSummary({
                    total_setuju: 0,
                    total_tidak: 0,
                    total_vote: 0,
                    persen_setuju: 0,
                    persen_tidak_setuju: 0,
                });
            }
        } catch (err) {
            console.error("load detail zona error:", err);
            setErrorMsg("Terjadi kesalahan saat memuat detail zona");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, [id]);

    const voteStats = useMemo(() => {
        const totalSetuju = toInt(summary?.total_setuju);
        const totalTidak =
            toInt(summary?.total_tidak) || toInt(summary?.total_tidak_setuju);
        const totalVoteRaw = toInt(summary?.total_vote);
        const totalVote = totalVoteRaw || totalSetuju + totalTidak;

        const persenSetuju =
            toInt(summary?.persen_setuju) ||
            (totalVote > 0 ? Math.round((totalSetuju * 100) / totalVote) : 0);

        const persenTidak =
            toInt(summary?.persen_tidak_setuju) ||
            (totalVote > 0 ? Math.round((totalTidak * 100) / totalVote) : 0);

        return {
            totalSetuju,
            totalTidak,
            totalVote,
            persenSetuju,
            persenTidak,
        };
    }, [summary]);

    const rekomendasi = useMemo(() => {
        const currentStatus = (zone?.status || "").toLowerCase();

        if (currentStatus !== "pending") {
            return {
                text: `Zona sudah berstatus ${zone?.status || "-"}`,
                type: "done",
            };
        }

        if (voteStats.totalVote === 0) {
            return {
                text: "Belum ada voting. Zona sebaiknya tetap pending dulu.",
                type: "pending",
            };
        }

        if (voteStats.totalSetuju > voteStats.totalTidak) {
            return {
                text: "Voting lebih banyak SETUJU. Zona direkomendasikan untuk di-APPROVE.",
                type: "approve",
            };
        }

        if (voteStats.totalTidak > voteStats.totalSetuju) {
            return {
                text: "Voting lebih banyak TIDAK SETUJU. Zona direkomendasikan untuk di-REJECT.",
                type: "reject",
            };
        }

        return {
            text: "Voting masih imbang. Zona bisa tetap ditahan dalam status PENDING.",
            type: "pending",
        };
    }, [voteStats, zone]);

    const handleChangeStatus = async (newStatus) => {
        if (!window.confirm(`Yakin ingin mengubah status zona menjadi ${newStatus}?`)) {
            return;
        }

        setSaving(true);
        setErrorMsg("");
        setSuccessMsg("");

        try {
            const res = await updateZonaBahayaStatus(id, { status: newStatus });

            if (!res.success) {
                setErrorMsg(res.message || "Gagal mengubah status zona");
                return;
            }

            setSuccessMsg(`Status zona berhasil diubah menjadi ${newStatus}`);
            await loadData();
        } catch (err) {
            console.error("handleChangeStatus error:", err);
            setErrorMsg("Terjadi kesalahan saat mengubah status");
        } finally {
            setSaving(false);
        }
    };

    const formatTanggal = (tgl) => {
        if (!tgl) return "-";
        try {
            return new Date(tgl).toLocaleDateString("id-ID", {
                day: "2-digit",
                month: "long",
                year: "numeric",
            });
        } catch {
            return tgl;
        }
    };

    return (
        <AdminLayout>
            <div style={{ padding: "24px" }}>
                <button
                    type="button"
                    onClick={() => navigate(-1)}
                    style={{
                        border: "none",
                        background: "transparent",
                        color: "#2563eb",
                        fontWeight: 600,
                        cursor: "pointer",
                        marginBottom: "12px",
                    }}
                >
                    ← Kembali
                </button>

                <div style={{ marginBottom: "20px" }}>
                    <h2 style={{ marginBottom: "6px",color:"black" }}>Detail Zona Bahaya</h2>
                    <p style={{ color: "#6b7280", margin: 0 }}>
                        Admin dapat melihat hasil voting zona dan menentukan keputusan akhir.
                    </p>
                </div>

                {loading ? (
                    <p>Memuat detail zona...</p>
                ) : errorMsg ? (
                    <p style={{ color: "red" }}>{errorMsg}</p>
                ) : !zone ? (
                    <p>Data zona tidak ditemukan.</p>
                ) : (
                    <>
                        {successMsg && (
                            <div
                                style={{
                                    backgroundColor: "#dcfce7",
                                    color: "#166534",
                                    padding: "12px 16px",
                                    borderRadius: "10px",
                                    marginBottom: "16px",
                                    fontWeight: 600,
                                }}
                            >
                                {successMsg}
                            </div>
                        )}

                        <div
                            style={{
                                display: "grid",
                                gridTemplateColumns: "1fr 1fr",
                                gap: "20px",
                            }}
                        >
                            {/* kiri */}
                            <div
                                style={{
                                    backgroundColor: "#fff",
                                    borderRadius: "16px",
                                    padding: "20px",
                                    boxShadow: "0 10px 30px rgba(15,23,42,0.06)",
                                }}
                            >
                                <h3 style={{ marginTop: 0, marginBottom: "16px", color:"black" }}>
                                    Informasi Zona
                                </h3>

                                <table style={{ width: "100%", borderCollapse: "collapse", border:"hide"}}>
                                    <tbody>
                                        <tr>
                                            <th style={thStyle}>Nama Zona</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{zone.nama_zona || "-"}</td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Status</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{zone.status_zona || "-"}</td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Risiko</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{zone.tingkat_risiko || "-"}</td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Radius</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{zone.radius_meter || "-"} meter</td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Koordinat</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>
                                                {Number(zone.latitude).toFixed(5)},{" "}
                                                {Number(zone.longitude).toFixed(5)}
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Tanggal Kejadian</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>
                                                {formatTanggal(zone.tanggal_kejadian)}
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Deskripsi</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{zone.deskripsi || "-"}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            {/* kanan */}
                            <div
                                style={{
                                    backgroundColor: "#fff",
                                    borderRadius: "16px",
                                    padding: "20px",
                                    boxShadow: "0 10px 30px rgba(15,23,42,0.06)",
                                }}
                            >
                                <h3 style={{ marginTop: 0, marginBottom: "16px" ,color:"black"}}>
                                    Ringkasan Voting
                                </h3>

                                <table style={{ width: "100%", borderCollapse: "collapse" }}>
                                    <tbody>
                                        <tr>
                                            <th style={thStyle}>Total Vote</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>{voteStats.totalVote}</td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Setuju</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>
                                                {voteStats.totalSetuju} orang ({voteStats.persenSetuju}%)
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style={thStyle}>Tidak Setuju</th>
                                            <td style={colonStyle}>:</td>
                                            <td style={tdStyle}>
                                                {voteStats.totalTidak} orang ({voteStats.persenTidak}%)
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>

                                <div style={{ marginTop: "18px" }}>
                                    <div
                                        style={{
                                            width: "100%",
                                            height: "18px",
                                            backgroundColor: "#e5e7eb",
                                            borderRadius: "999px",
                                            overflow: "hidden",
                                            display: "flex",
                                        }}
                                    >
                                        <div
                                            style={{
                                                width: `${voteStats.persenSetuju}%`,
                                                backgroundColor: "#16a34a",
                                                transition: "0.3s",
                                            }}
                                        />
                                        <div
                                            style={{
                                                width: `${voteStats.persenTidak}%`,
                                                backgroundColor: "#dc2626",
                                                transition: "0.3s",
                                            }}
                                        />
                                    </div>

                                    <div
                                        style={{
                                            display: "flex",
                                            justifyContent: "space-between",
                                            marginTop: "8px",
                                            fontSize: "13px",
                                            color: "#475569",
                                        }}
                                    >
                                        <span>Setuju: {voteStats.persenSetuju}%</span>
                                        <span>Tidak setuju: {voteStats.persenTidak}%</span>
                                    </div>
                                </div>

                                <div
                                    style={{
                                        marginTop: "18px",
                                        padding: "14px",
                                        borderRadius: "12px",
                                        backgroundColor:
                                            rekomendasi.type === "approve"
                                                ? "#dcfce7"
                                                : rekomendasi.type === "reject"
                                                    ? "#fee2e2"
                                                    : "#fef3c7",
                                        color:
                                            rekomendasi.type === "approve"
                                                ? "#166534"
                                                : rekomendasi.type === "reject"
                                                    ? "#991b1b"
                                                    : "#92400e",
                                        fontWeight: 600,
                                    }}
                                >
                                    {rekomendasi.text}
                                </div>

                                <div
                                    style={{
                                        display: "flex",
                                        gap: "10px",
                                        marginTop: "18px",
                                        flexWrap: "wrap",
                                    }}
                                >
                                    <button
                                        type="button"
                                        disabled={saving}
                                        onClick={() => handleChangeStatus("approve")}
                                        style={btnApprove}
                                    >
                                        Approve
                                    </button>

                                    <button
                                        type="button"
                                        disabled={saving}
                                        onClick={() => handleChangeStatus("rejected")}
                                        style={btnReject}
                                    >
                                        Reject
                                    </button>

                                    <button
                                        type="button"
                                        disabled={saving}
                                        onClick={() => handleChangeStatus("pending")}
                                        style={btnPending}
                                    >
                                        Tahan Pending
                                    </button>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </AdminLayout>
    );
};

const thStyle = {
    textAlign: "left",
    padding: "10px 0",
    width: "160px",
    verticalAlign: "top",
    color: "#334155",
};

const colonStyle = {
    width: "20px",
    textAlign: "center",
    verticalAlign: "top",
    padding: "10px 0",
    color: "#334155",
};

const tdStyle = {
    padding: "10px 0",
    verticalAlign: "top",
    color: "#0f172a",
};

const btnApprove = {
    border: "none",
    backgroundColor: "#16a34a",
    color: "white",
    padding: "10px 16px",
    borderRadius: "10px",
    cursor: "pointer",
    fontWeight: 600,
};

const btnReject = {
    border: "none",
    backgroundColor: "#dc2626",
    color: "white",
    padding: "10px 16px",
    borderRadius: "10px",
    cursor: "pointer",
    fontWeight: 600,
};

const btnPending = {
    border: "none",
    backgroundColor: "#f59e0b",
    color: "white",
    padding: "10px 16px",
    borderRadius: "10px",
    cursor: "pointer",
    fontWeight: 600,
};

export default ZonaBahayaDetailPage;