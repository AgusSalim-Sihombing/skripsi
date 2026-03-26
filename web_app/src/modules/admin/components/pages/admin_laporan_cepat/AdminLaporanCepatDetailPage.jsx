import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import "./AdminLaporanCepatDetail.css";
import {
    getAdminLaporanDetail,
    approveLaporan,
    rejectLaporan,
    deleteLaporan,
} from "../../../../../services/laporanCepatService";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const statusLabel = (status) => {
    if (!status) return "Pending";
    return status.charAt(0).toUpperCase() + status.slice(1);
};

const AdminLaporanCepatDetailPage = () => {
    const { id } = useParams();

    const navigate = useNavigate();

    const [laporan, setLaporan] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");
    const [isModalOpen, setIsModalOpen] = useState(false);

    const fotoUrl = `${API_BASE_URL}/admin/laporan-cepat/${id}/foto`;

    const statusStyles = {
        pending: { backgroundColor: "#f69300f6", color: "white" },  // Merah
        approved: { backgroundColor: "#2ecc71", color: "white" }, // Hijau
        rejected: { backgroundColor: "#fa0000", color: "white" }, // Biru
    };

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
        } catch (err) {
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
    }, [id]);

    const toggleModal = () => setIsModalOpen(!isModalOpen);

    const handleSetStatus = async (newStatus) => {
        if (!window.confirm(`Ubah status laporan menjadi ${newStatus}?`)) return;
        setSaving(true);
        try {
            if (newStatus === "approved") await approveLaporan(laporan.id_laporan);
            else if (newStatus === "rejected") await rejectLaporan(laporan.id_laporan);
            await loadDetail();
            setSuccessMsg(`Status berhasil diubah.`);
        } catch (err) {
            setErrorMsg("Gagal mengubah status");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!laporan) return;
        if (!window.confirm(`Yakin ingin menghapus laporan dengan id : ${laporan.id_laporan} ini?`)) return;

        try {
            const res = await deleteLaporan(laporan.id_laporan)
            alert("Berhasil Menghapus Laporan")
            navigate("/admin/laporan-cepat");
        } catch (err) {
            console.error("delete report error:", err);
            alert("Gagal Menghapus Laporan")
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan saat menghapus laporan"
            );
        }
    };

    return (
        <AdminLayout>
            <div className="laporan-container">
                <header className="page-header">
                    <div className="header-text">
                        <h2>Detail Laporan Cepat</h2>
                        <p>Validasi informasi laporan dan kelola status kejadian di bawah ini.</p>
                    </div>
                    
                </header>

                {errorMsg && <div className="alert alert-danger">{errorMsg}</div>}
                {successMsg && <div className="alert alert-success">{successMsg}</div>}

                {loading || !laporan ? (
                    <div className="loading-state">Memuat data...</div>
                ) : (
                    <div className="detail-content-grid">
                        {/* SISI KIRI: INFORMASI TEKSTUAL */}
                        <div className="info-section">
                            <div className="card" style={{ height: "100%" }}>
                                <div className="card-header">
                                    <h2 className="judul-laporan">{laporan.judul_laporan}</h2>
                                    <span
                                        className={`badge badge-${laporan.status_validasi || "pending"}`}
                                        style={statusStyles[laporan.status_validasi] || statusStyles.pending}
                                    >
                                        {statusLabel(laporan.status_validasi)}
                                    </span>
                                </div>

                                <table className="info-table" >
                                    <tbody>
                                        <tr >
                                            <th>ID Laporan</th>
                                            <td>{laporan.id_laporan}</td>
                                        </tr>
                                        <tr style={{ background: "white" }}>
                                            <th>Waktu Kejadian</th>
                                            <td>{laporan.tanggal_kejadian} | {laporan.waktu_kejadian?.slice(0, 5)}</td>
                                        </tr>
                                        <tr>
                                            <th>Lokasi (Lat, Long)</th>
                                            <td>{Number(laporan.latitude).toFixed(5)}, {Number(laporan.longitude).toFixed(5)}</td>
                                        </tr>
                                        <tr style={{ background: "white" }}>
                                            <th>Nama Pelapor</th>
                                            <td>{laporan.is_anonim ? "Anonim" : laporan.nama_pelapor}</td>
                                        </tr>
                                        {!laporan.is_anonim && (
                                            <>
                                                <tr>
                                                    <th>NIK Pelapor</th>
                                                    <td>{laporan.nik_pelapor || "-"}</td>
                                                </tr>
                                                <tr style={{ background: "white" }}>
                                                    <th>No. Tlp</th>
                                                    <td>{laporan.phone_pelapor || laporan.email_pelapor}</td>
                                                </tr>
                                                <tr style={{ background: "white" }}>
                                                    <th>Email</th>
                                                    <td>{laporan.email_pelapor}</td>
                                                </tr>
                                            </>
                                        )}
                                    </tbody>
                                </table>

                                <div className="deskripsi-box">
                                    <label>Deskripsi Kejadian:</label>
                                    <p>{laporan.deskripsi || "Tidak ada deskripsi."}</p>
                                </div>

                                <div className="action-footer">
                                    <button className="btn btn-approve" onClick={() => handleSetStatus("approved")} disabled={saving}>Setujui</button>
                                    <button className="btn btn-reject" onClick={() => handleSetStatus("rejected")} disabled={saving}>Tolak</button>
                                    <button className="btn btn-danger" onClick={handleDelete}>Hapus Laporan</button>
                                    <button className="btn btn-warning" onClick={() => navigate(`/admin/zona-bahaya?fromLaporan=${id}`)}>Buat Zona Bahaya</button>
                                </div>
                            </div>
                        </div>

                        {/* SISI KANAN: MEDIA/FOTO */}
                        <div className="media-section">
                            <div className="card" style={{ height: "100%" }}>
                                <h3>Foto Lampiran</h3>
                                <div className="image-preview-container" onClick={toggleModal}>
                                    <img
                                        src={fotoUrl}
                                        alt="Klik untuk memperbesar"
                                        className="img-preview"
                                        // height={"80px"}
                                        onError={(e) => { e.target.src = 'https://via.placeholder.com/500x300?text=Foto+Tidak+Tersedia'; }}
                                    />
                                    <div className="image-overlay">
                                        <span>Klik untuk memperbesar</span>
                                    </div>
                                </div>
                                <p>Note : Klik untuk memperbesar gambar</p>
                            </div>
                        </div>
                    </div>
                )}

                {isModalOpen && (
                    <div className="modal-overlay" onClick={toggleModal}>
                        <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                            <button className="modal-close" onClick={toggleModal}>&times;</button>
                            <img src={fotoUrl} alt="Ukuran Penuh" className="img-full" />
                        </div>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminLaporanCepatDetailPage;