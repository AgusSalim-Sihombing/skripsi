// import React, { useEffect, useState } from "react";
// import { useNavigate, useParams } from "react-router-dom";
// import AdminLayout from "../../../shared/layout/AdminLayout";
// import {
//     getAdminLaporanDetail,
//     approveLaporan,
//     rejectLaporan,
// } from "../../../../services/laporanCepatService";

// const AdminLaporanCepatDetailPage = () => {
//     const { id } = useParams();
//     const navigate = useNavigate();

//     const [laporan, setLaporan] = useState(null);
//     const [voting, setVoting] = useState(null);
//     const [loading, setLoading] = useState(true);
//     const [saving, setSaving] = useState(false);
//     const [errorMsg, setErrorMsg] = useState("");
//     const [successMsg, setSuccessMsg] = useState("");

//     const loadDetail = async () => {
//         try {
//             setLoading(true);
//             setErrorMsg("");
//             const res = await getAdminLaporanDetail(id);
//             if (res.success) {
//                 setLaporan(res.data.laporan);
//                 setVoting(res.data.voting || null);
//             } else {
//                 setErrorMsg(res.message || "Gagal memuat detail laporan");
//             }
//         } catch (err) {
//             console.error("getAdminLaporanDetail error:", err);
//             setErrorMsg("Terjadi kesalahan saat memuat detail laporan");
//         } finally {
//             setLoading(false);
//         }
//     };

//     useEffect(() => {
//         const token = localStorage.getItem("sigap_admin_token");
//         if (!token) {
//             navigate("/login-admin");
//             return;
//         }
//         loadDetail();
//         // eslint-disable-next-line react-hooks/exhaustive-deps
//     }, [id]);

//     const handleApprove = async () => {
//         if (!window.confirm("Setujui laporan ini dan aktifkan zona bahaya?")) return;
//         try {
//             setSaving(true);
//             setErrorMsg("");
//             setSuccessMsg("");
//             const res = await approveLaporan(id);
//             if (res.success) {
//                 setSuccessMsg(res.message || "Laporan berhasil di-approve");
//                 await loadDetail();
//             } else {
//                 setErrorMsg(res.message || "Gagal meng-approve laporan");
//             }
//         } catch (err) {
//             console.error("approveLaporan error:", err);
//             setErrorMsg("Terjadi kesalahan saat meng-approve laporan");
//         } finally {
//             setSaving(false);
//         }
//     };

//     const handleReject = async () => {
//         if (!window.confirm("Tolak laporan ini?")) return;
//         try {
//             setSaving(true);
//             setErrorMsg("");
//             setSuccessMsg("");
//             const res = await rejectLaporan(id);
//             if (res.success) {
//                 setSuccessMsg(res.message || "Laporan berhasil ditolak");
//                 await loadDetail();
//             } else {
//                 setErrorMsg(res.message || "Gagal menolak laporan");
//             }
//         } catch (err) {
//             console.error("rejectLaporan error:", err);
//             setErrorMsg("Terjadi kesalahan saat menolak laporan");
//         } finally {
//             setSaving(false);
//         }
//     };

//     const status = laporan?.status_validasi;

//     return (
//         <AdminLayout>
//             <div className="dashboard-header">
//                 <button
//                     type="button"
//                     className="btn btn-outline"
//                     onClick={() => navigate("/admin/laporan-cepat")}
//                     style={{ marginBottom: "0.75rem" }}
//                 >
//                     &larr; Kembali ke Laporan Cepat
//                 </button>

//                 <h1>Detail Laporan Cepat</h1>
//                 <p>
//                     Review detail laporan dan hasil voting sebelum menentukan apakah zona
//                     bahaya akan diaktifkan.
//                 </p>
//             </div>

//             {loading ? (
//                 <p>Memuat detail laporan...</p>
//             ) : !laporan ? (
//                 <p>Laporan tidak ditemukan.</p>
//             ) : (
//                 <>
//                     {errorMsg && <div className="login-error">{errorMsg}</div>}
//                     {successMsg && <div className="login-success">{successMsg}</div>}

//                     <div className="detail-grid">
//                         {/* Kiri: info laporan */}
//                         <div className="detail-card">
//                             <h2>{laporan.judul_laporan}</h2>
//                             <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
//                                 Status:{" "}
//                                 <span style={{ textTransform: "capitalize", fontWeight: 600 }}>
//                                     {status}
//                                 </span>
//                             </p>

//                             <h3>Deskripsi Kejadian</h3>
//                             <p>{laporan.deskripsi || "-"}</p>

//                             <h3>Waktu & Lokasi</h3>
//                             <p>
//                                 Tanggal: {laporan.tanggal_kejadian} <br />
//                                 Waktu: {laporan.waktu_kejadian?.slice(0, 5)} <br />
//                                 Koordinat:{" "}
//                                 {Number(laporan.latitude).toFixed(5)},{" "}
//                                 {Number(laporan.longitude).toFixed(5)}
//                             </p>

//                             <h3>Data Pelapor</h3>
//                             {laporan.is_anon ? (
//                                 <p>Laporan dikirim secara anonim.</p>
//                             ) : (
//                                 <p>
//                                     Nama: {laporan.nama_pelapor || laporan.nama_user || "-"} <br />
//                                     No. HP: {laporan.no_hp_pelapor || laporan.phone_user || "-"}{" "}
//                                     <br />
//                                     Email: {laporan.email_pelapor || laporan.email_user || "-"}
//                                 </p>
//                             )}
//                         </div>

//                         {/* Kanan: foto + voting */}
//                         <div className="detail-card">
//                             <h3>Foto Kejadian</h3>
//                             {laporan.has_foto === false ? null : (
//                                 <div style={{ marginBottom: "1rem" }}>
//                                     {/* Cara simpel: panggil endpoint foto sebagai <img> dengan query token kalau perlu.
//                      Kalau butuh header Authorization, nanti bisa pakai fetch blob -> objectURL.
//                      Untuk sementara, kalau belum ada, ini bisa kamu lengkapi nanti. */}
//                                     <img
//                                         src={`${import.meta.env.VITE_REACT_APP_API_BASE_URL
//                                             }/api/admin/laporan-cepat/${laporan.id_laporan}/foto`}
//                                         alt="Foto kejadian"
//                                         style={{
//                                             maxWidth: "100%",
//                                             maxHeight: 260,
//                                             borderRadius: 8,
//                                             objectFit: "cover",
//                                         }}
//                                         onError={(e) => {
//                                             // kalau foto gak ada / error, disembunyikan
//                                             e.target.style.display = "none";
//                                         }}
//                                     />
//                                 </div>
//                             )}

//                             <h3>Hasil Voting</h3>
//                             {voting ? (
//                                 <>
//                                     <p>
//                                         Pertanyaan:{" "}
//                                         <strong>{voting.pertanyaan}</strong>
//                                     </p>
//                                     <p>
//                                         Setuju: <strong>{voting.total_setuju}</strong> <br />
//                                         Tidak setuju:{" "}
//                                         <strong>{voting.total_tidak_setuju}</strong>
//                                     </p>
//                                     {voting.total_setuju + voting.total_tidak_setuju > 0 && (
//                                         <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
//                                             Persentase setuju:{" "}
//                                             {Math.round(
//                                                 (voting.total_setuju * 100) /
//                                                 (voting.total_setuju + voting.total_tidak_setuju)
//                                             )}
//                                             %
//                                         </p>
//                                     )}
//                                     <p style={{ fontSize: "0.85rem", color: "#6b7280" }}>
//                                         Status voting:{" "}
//                                         <span style={{ textTransform: "capitalize" }}>
//                                             {voting.status_voting}
//                                         </span>
//                                     </p>
//                                 </>
//                             ) : (
//                                 <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
//                                     Belum ada voting untuk laporan ini.
//                                 </p>
//                             )}

//                             <div
//                                 className="zona-form-actions"
//                                 style={{ marginTop: "1rem" }}
//                             >
//                                 <button
//                                     type="button"
//                                     className="btn btn-primary"
//                                     onClick={handleApprove}
//                                     disabled={saving || status === "approved"}
//                                 >
//                                     {saving && status !== "approved"
//                                         ? "Memproses..."
//                                         : "Approve Laporan"}
//                                 </button>
//                                 <button
//                                     type="button"
//                                     className="btn btn-secondary"
//                                     onClick={handleReject}
//                                     disabled={saving || status === "rejected"}
//                                     style={{ marginLeft: "0.5rem" }}
//                                 >
//                                     {saving && status !== "rejected"
//                                         ? "Memproses..."
//                                         : "Reject Laporan"}
//                                 </button>
//                             </div>
//                         </div>
//                     </div>
//                 </>
//             )}
//         </AdminLayout>
//     );
// };

// export default AdminLaporanCepatDetailPage;
import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import {
    getAdminLaporanDetail,
    approveLaporan,
    rejectLaporan,
} from "../../../../services/laporanCepatService";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const statusLabel = (status) => {
    if (!status) return "Pending";
    return status.charAt(0).toUpperCase() + status.slice(1);
};

const initialVotingState = {
    total_setuju: 0,
    total_tidak: 0,
    total_vote: 0,
    persentase_setuju: 0,
    persentase_tidak: 0,
};

const AdminLaporanCepatDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [laporan, setLaporan] = useState(null);
    const [voting, setVoting] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const loadDetail = async () => {
        try {
            setLoading(true);
            setErrorMsg("");
            const res = await getAdminLaporanDetail(id);
            if (!res.success) {
                setErrorMsg(res.message || "Gagal memuat detail laporan");
                return;
            }
            setLaporan(res.data.laporan);
            setVoting(res.data.voting || initialVotingState);

        } catch (err) {
            console.error("getAdminLaporanDetail error:", err);
            setErrorMsg("Terjadi kesalahan saat memuat detail laporan");
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
        loadDetail();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id]);

    const handleSetStatus = async (newStatus) => {
        if (!laporan) return;
        setSaving(true);
        setErrorMsg("");
        setSuccessMsg("");

        try {
            if (newStatus === "approved") {
                await approveLaporan(laporan.id_laporan);
            } else if (newStatus === "rejected") {
                await rejectLaporan(laporan.id_laporan);
            }

            await loadDetail();
            setSuccessMsg(`Status laporan diubah menjadi ${newStatus}.`);
        } catch (err) {
            console.error("set status error:", err);
            setErrorMsg("Gagal mengubah status laporan");
        } finally {
            setSaving(false);
        }
    };

    const handleGoToZonaBahaya = () => {
        // nanti di Zona Bahaya page bisa baca query ?fromLaporan=id untuk prefilling
        navigate(`/admin/zona-bahaya?fromLaporan=${id}`);
    };

    const renderVotingBar = () => {
        const v = voting || initialVotingState;

        if (!v.total_vote || Number(v.total_vote) === 0) {
            return (
                <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
                    Belum ada voting dari pengguna untuk zona yang berasal dari laporan ini.
                </p>
            );
        }

        return (
            <>
                <div className="voting-bar" style={{ height: 12, background: "#e5e7eb", borderRadius: 999, overflow: "hidden" }}>
                    <div style={{ width: `${v.persentase_setuju}%`, height: "100%", background: "#22c55e" }} />
                    <div style={{ width: `${v.persentase_tidak}%`, height: "100%", background: "#ef4444" }} />
                </div>

                <div className="voting-legend" style={{ display: "flex", justifyContent: "space-between", marginTop: 8, fontSize: 12 }}>
                    <span>Setuju: {v.total_setuju} ({v.persentase_setuju}%)</span>
                    <span>Tidak setuju: {v.total_tidak} ({v.persentase_tidak}%)</span>
                </div>
            </>
        );
    };


    return (
        <AdminLayout>
            <div className="laporan-cepat-detail-page">
                <div className="dashboard-header">
                    <h1>Detail Laporan Cepat</h1>
                    <p>
                        Tinjau informasi lengkap laporan, foto kejadian, dan ringkasan voting
                        sebelum mengubah status atau membuat zona bahaya.
                    </p>
                </div>

                {errorMsg && <div className="alert alert--error">{errorMsg}</div>}
                {successMsg && <div className="alert alert--success">{successMsg}</div>}

                {loading || !laporan ? (
                    <p>Memuat detail laporan...</p>
                ) : (
                    <div className="laporan-detail-layout">
                        {/* INFO LAPORAN */}
                        <section className="card laporan-detail-card">
                            <h2 className="section-title" >{laporan.judul_laporan}</h2>
                            <p className="laporan-detail-status">
                                Status:{" "}
                                <span
                                    className={`badge badge--status badge--${laporan.status_validasi || "pending"}`}
                                >
                                    {statusLabel(laporan.status_validasi || "pending")}
                                </span>
                            </p>

                            <div className="laporan-detail-grid">
                                <div>
                                    <div className="detail-row">
                                        <span className="detail-label">Tanggal kejadian</span>
                                        <span>{laporan.tanggal_kejadian || "-"}</span>
                                    </div>
                                    <div className="detail-row">
                                        <span className="detail-label">Waktu kejadian</span>
                                        <span>{laporan.waktu_kejadian?.slice(0, 5) || "-"}</span>
                                    </div>
                                    <div className="detail-row">
                                        <span className="detail-label">Koordinat</span>
                                        <span>
                                            {Number(laporan.latitude).toFixed(5)},{" "}
                                            {Number(laporan.longitude).toFixed(5)}
                                        </span>
                                    </div>
                                    <div className="detail-row">
                                        <span className="detail-label">Pelapor</span>
                                        <span>
                                            {laporan.is_anonim
                                                ? "Anonim"
                                                : laporan.nama_pelapor || "Tidak diketahui"}
                                        </span>
                                    </div>
                                </div>

                                <div>
                                    <div className="detail-row">
                                        <span className="detail-label">NIK Pelapor</span>
                                        <span>{laporan.is_anonim ? "-" : laporan.nik_pelapor || "-"}</span>
                                    </div>
                                    <div className="detail-row">
                                        <span className="detail-label">Kontak</span>
                                        <span>
                                            {laporan.is_anonim
                                                ? "-"
                                                : laporan.phone_pelapor || laporan.email_pelapor || "-"}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className="detail-row detail-row--full">
                                <span className="detail-label">Deskripsi</span>
                                <p className="detail-description">
                                    {laporan.deskripsi || "-"}
                                </p>
                            </div>

                            <div className="laporan-detail-actions">
                                <button
                                    type="button"
                                    className="btn btn-primary"
                                    disabled={saving}
                                    onClick={() => handleSetStatus("approved")}
                                >
                                    {saving ? "Memproses..." : "Setujui (Approve)"}
                                </button>
                                <button
                                    type="button"
                                    className="btn btn-secondary"
                                    disabled={saving}
                                    onClick={() => handleSetStatus("rejected")}
                                >
                                    {saving ? "Memproses..." : "Tolak (Reject)"}
                                </button>
                                <button
                                    type="button"
                                    className="btn btn-outline"
                                    onClick={handleGoToZonaBahaya}
                                >
                                    Buat Zona Bahaya dari laporan ini
                                </button>
                            </div>
                        </section>

                        {/* FOTO + VOTING */}
                        <section className="card laporan-detail-side">
                            <h2 className="section-title">Foto Kejadian</h2>
                            <div className="laporan-detail-photo">
                                <img
                                    src={`${API_BASE_URL}/admin/laporan-cepat/${laporan.id_laporan}/foto`}
                                    alt="Foto laporan"
                                    onError={(e) => {
                                        e.currentTarget.style.display = "none";
                                    }}
                                />
                                <p className="photo-hint">
                                    Jika foto tidak tampil, cek kembali endpoint <code>/foto</code> atau
                                    pastikan laporan memiliki gambar.
                                </p>
                            </div>

                            <hr style={{ margin: "1rem 0" }} />

                            <h2 className="section-title">Ringkasan Voting</h2>
                            {renderVotingBar()}
                        </section>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminLaporanCepatDetailPage;
