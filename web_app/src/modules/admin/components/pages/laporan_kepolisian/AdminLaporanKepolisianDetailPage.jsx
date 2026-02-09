import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { FiArrowLeft, FiSave } from "react-icons/fi";
import {
    getAdminLaporanKepolisianDetail,
    patchAdminLaporanKepolisianStatus,
} from "../../../../../services/adminApi";
import "./laporanKepolisianAdmin.css";
import AdminLayout from "../../../../shared/layout/AdminLayout";

const fmt = (v) => {
    if (!v) return "-";
    try {
        return new Date(v).toLocaleString("id-ID");
    } catch {
        return v;
    }
};

const Field = ({ label, value }) => (
    <div className="lk-field">
        <div className="lk-field__label">{label}</div>
        <div className="lk-field__value">{value ?? "-"}</div>
    </div>
);

export default function AdminLaporanKepolisianDetailPage() {
    const { id } = useParams();
    const nav = useNavigate();

    const [loading, setLoading] = useState(false);
    const [row, setRow] = useState(null);

    const [saving, setSaving] = useState(false);
    const [status, setStatus] = useState("");

    const allowed = useMemo(
        () => ["pending", "on_process", "selesai", "dibatalkan"],
        []
    );

    const fetchDetail = async () => {
        setLoading(true);
        try {
            const data = await getAdminLaporanKepolisianDetail(id);
            const r = data?.data ?? data ?? null;
            setRow(r);
            setStatus(r?.status || "");
        } catch (e) {
            console.error(e);
            alert(e?.response?.data?.message || "Gagal ambil detail laporan");
            nav(-1);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDetail();
        // eslint-disable-next-line
    }, [id]);

    const saveStatus = async () => {
        if (!status || !allowed.includes(status)) {
            return alert("Status tidak valid");
        }
        setSaving(true);
        try {
            await patchAdminLaporanKepolisianStatus(id, { status });
            await fetchDetail();
            alert("Status berhasil diupdate ✅");
        } catch (e) {
            console.error(e);
            alert(e?.response?.data?.message || "Gagal update status");
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <div className="lk-admin">
                <div className="lk-card lk-empty">Loading detail...</div>
            </div>
        );
    }

    if (!row) {
        return (
            <div className="lk-admin">
                <div className="lk-card lk-empty">Data tidak ditemukan.</div>
            </div>
        );
    }

    return (
        <AdminLayout>
            <div className="lk-admin" style={{ color: "black" }}>
                <div className="lk-admin__header">
                    <div>
                        <h2 className="lk-admin__title">Detail Laporan #{row.id}</h2>
                        <p className="lk-admin__subtitle">Pelapor + officer penerima + isi laporan.</p>
                    </div>

                    <div className="lk-actions">
                        <button className="lk-btn lk-btn--ghost" onClick={() => nav(-1)}>
                            <FiArrowLeft /> Kembali
                        </button>
                    </div>
                </div>

                <div className="lk-card">
                    <div className="lk-detailTop" style={{ color: "black" }}>
                        <div className="lk-detailTop__left" style={{ color: "black" }}>
                            <Field label="Status" value={row.status} />
                            <Field label="Created At" value={fmt(row.created_at)} />
                            <Field label="Responded At" value={fmt(row.responded_at)} />
                            <Field label="Completed At" value={fmt(row.completed_at)} />
                        </div>

                        <div className="lk-detailTop__right">
                            <div className="lk-statusEdit">
                                <select
                                    style={{ color: "black" }}
                                    className="lk-input"
                                    value={status}
                                    onChange={(e) => setStatus(e.target.value)}
                                >
                                    {allowed.map((s) => (
                                        <option key={s} value={s}>
                                            {s}
                                        </option>
                                    ))}
                                </select>

                                <button className="lk-btn" onClick={saveStatus} disabled={saving}>
                                    <FiSave /> {saving ? "Menyimpan..." : "Update Status"}
                                </button>
                            </div>

                            <div className="lk-note">
                                * Kalau status diubah ke <b>on_process</b> dan <b>responded_at</b> masih kosong,
                                backend akan isi otomatis. Begitu juga <b>selesai</b> akan isi <b>completed_at</b>.
                            </div>
                        </div>
                    </div>

                    <div className="lk-sections">
                        <section className="lk-section">
                            <h3 className="lk-section__title">Pelapor</h3>
                            <div className="lk-grid">
                                <Field label="Nama" value={row.pelapor_nama} />
                                <Field label="Username" value={row.pelapor_username ? `@${row.pelapor_username}` : "-"} />
                                <Field label="Pelapor (form)" value={row.pelapor_nama} />
                                <Field label="Kontak (form)" value={row.pelapor_kontak} />
                                <Field label="Pangkat/NRP (form)" value={row.pelapor_pangkat_nrp} />
                                <Field label="Kesatuan (form)" value={row.pelapor_kesatuan} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Officer Penerima</h3>
                            {row.officer_id ? (
                                <div className="lk-grid">
                                    <Field label="Nama" value={row.officer_nama} />
                                    <Field label="Username" value={row.officer_username ? `@${row.officer_username}` : "-"} />
                                    <Field label="Officer ID" value={row.officer_id} />
                                </div>
                            ) : (
                                <div className="lk-muted">Belum ada officer yang menerima laporan ini.</div>
                            )}
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Waktu & Tempat Kejadian</h3>
                            <div className="lk-grid">
                                <Field label="Hari" value={row.waktu_kejadian_hari} />
                                <Field label="Tanggal" value={row.waktu_kejadian_tanggal} />
                                <Field label="Jam" value={row.waktu_kejadian_jam} />
                                <Field label="Jalan" value={row.tempat_jalan} />
                                <Field label="Desa/Kel" value={row.tempat_desa_kel} />
                                <Field label="Kecamatan" value={row.tempat_kecamatan} />
                                <Field label="Kab/Kota" value={row.tempat_kab_kota} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Isi Laporan</h3>
                            <div className="lk-grid">
                                <Field label="Tindak Pidana" value={row.tindak_pidana} />
                                <Field label="Apa Terjadi" value={row.apa_terjadi} />
                                <Field label="Bagaimana Terjadi" value={row.bagaimana_terjadi} />
                                <Field label="Uraian Singkat" value={row.uraian_singkat} />
                                <Field label="Barang Bukti" value={row.barang_bukti} />
                                <Field label="Tindakan Dilakukan" value={row.tindakan_dilakukan} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Terlapor</h3>
                            <div className="lk-grid">
                                <Field label="Nama" value={row.terlapor_nama} />
                                <Field label="JK" value={row.terlapor_jk} />
                                <Field label="Alamat" value={row.terlapor_alamat} />
                                <Field label="Pekerjaan" value={row.terlapor_pekerjaan} />
                                <Field label="Kontak" value={row.terlapor_kontak} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Korban</h3>
                            <div className="lk-grid">
                                <Field label="Nama" value={row.korban_nama} />
                                <Field label="JK" value={row.korban_jk} />
                                <Field label="Alamat" value={row.korban_alamat} />
                                <Field label="Pekerjaan" value={row.korban_pekerjaan} />
                                <Field label="Kontak" value={row.korban_kontak} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Saksi</h3>
                            <div className="lk-grid">
                                <Field label="Saksi 1 Nama" value={row.saksi1_nama} />
                                <Field label="Saksi 1 Umur" value={row.saksi1_umur} />
                                <Field label="Saksi 1 Alamat" value={row.saksi1_alamat} />
                                <Field label="Saksi 1 Pekerjaan" value={row.saksi1_pekerjaan} />

                                <Field label="Saksi 2 Nama" value={row.saksi2_nama} />
                                <Field label="Saksi 2 Umur" value={row.saksi2_umur} />
                                <Field label="Saksi 2 Alamat" value={row.saksi2_alamat} />
                                <Field label="Saksi 2 Pekerjaan" value={row.saksi2_pekerjaan} />
                            </div>
                        </section>

                        <section className="lk-section">
                            <h3 className="lk-section__title">Dilaporkan</h3>
                            <div className="lk-grid">
                                <Field label="Hari" value={row.dilaporkan_hari} />
                                <Field label="Tanggal" value={row.dilaporkan_tanggal} />
                                <Field label="Jam" value={row.dilaporkan_jam} />
                                <Field label="Mengetahui (Jabatan)" value={row.mengetahui_kepala_jabatan} />
                                <Field label="Mengetahui (Nama)" value={row.mengetahui_kepala_nama} />
                                <Field label="Mengetahui (Pangkat/NRP)" value={row.mengetahui_kepala_pangkat_nrp} />
                            </div>
                        </section>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
