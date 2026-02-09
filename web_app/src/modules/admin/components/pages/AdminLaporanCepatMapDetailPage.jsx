import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import { getLaporanCepatDetail } from "../../../../services/laporanCepatService";

const AdminLaporanCepatDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [detail, setDetail] = useState(null);
    const [loading, setLoading] = useState(true);

    const loadDetail = async () => {
        setLoading(true);
        try {
            const res = await getLaporanCepatDetail(id);
            if (res.success) {
                setDetail(res.data);
            }
        } catch (err) {
            console.error("getLaporanCepatDetail error:", err);
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
    }, [id, navigate]);

    if (loading) {
        return (
            <AdminLayout>
                <p>Memuat detail laporan...</p>
            </AdminLayout>
        );
    }

    if (!detail) {
        return (
            <AdminLayout>
                <p>Detail laporan tidak ditemukan.</p>
            </AdminLayout>
        );
    }

    const { laporan, voting } = detail;

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>Detail Laporan Cepat</h1>
                <p>Lihat detail laporan dan hasil voting (jika sudah dibuat).</p>
            </div>

            <div className="laporan-detail-layout">
                <div className="laporan-detail-main">
                    <h2>{laporan.judul_laporan}</h2>
                    <p style={{ fontSize: "0.9rem", color: "#6b7280" }}>
                        Status: <strong>{laporan.status_validasi}</strong>
                    </p>

                    {laporan.tanggal_kejadian && (
                        <p style={{ fontSize: "0.9rem" }}>
                            Tanggal kejadian: {laporan.tanggal_kejadian}{" "}
                            {laporan.waktu_kejadian?.slice(0, 5) || ""}
                        </p>
                    )}

                    {laporan.is_anon ? (
                        <p style={{ fontSize: "0.9rem" }}>Pelapor: Anonim</p>
                    ) : (
                        laporan.nama_pelapor && (
                            <p style={{ fontSize: "0.9rem" }}>
                                Pelapor: {laporan.nama_pelapor}
                            </p>
                        )
                    )}

                    {laporan.deskripsi && (
                        <>
                            <h3>Deskripsi</h3>
                            <p style={{ fontSize: "0.9rem" }}>{laporan.deskripsi}</p>
                        </>
                    )}

                    {laporan.foto_path && (
                        <>
                            <h3>Bukti Foto</h3>
                            <img
                                src={laporan.foto_path}
                                alt="bukti"
                                style={{
                                    maxWidth: "100%",
                                    borderRadius: "0.75rem",
                                    marginTop: "0.25rem",
                                }}
                            />
                        </>
                    )}
                </div>

                <div className="laporan-detail-side">
                    <h3>Voting Validasi</h3>
                    {voting ? (
                        <div className="voting-summary-card">
                            <p style={{ fontSize: "0.9rem" }}>
                                Pertanyaan: {voting.pertanyaan}
                            </p>
                            <p style={{ fontSize: "0.9rem" }}>
                                Setuju: <strong>{voting.total_setuju}</strong>
                            </p>
                            <p style={{ fontSize: "0.9rem" }}>
                                Tidak setuju: <strong>{voting.total_tidak_setuju}</strong>
                            </p>
                            <p style={{ fontSize: "0.9rem" }}>
                                Status voting: <strong>{voting.status_voting}</strong>
                            </p>
                        </div>
                    ) : (
                        <p style={{ fontSize: "0.85rem", color: "#6b7280" }}>
                            Belum ada voting untuk laporan inisd.
                        </p>
                    )}

                    {/* Nanti di sini kita tambahkan tombol:
              - Buat Voting
              - Tandai sebagai Zona Bahaya
          */}
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminLaporanCepatDetailPage;
