import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Row, Col, Form, Button, Spinner } from "react-bootstrap";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const statusLabel = (status) => {
    if (!status) return "Pending";
    if (status === "verified") return "Terverifikasi";
    if (status === "rejected") return "Ditolak";
    return status.charAt(0).toUpperCase() + status.slice(1);
};

const AdminUserDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [user, setUser] = useState(null);
    const [form, setForm] = useState({
        role: "masyarakat",
        status_verifikasi: "pending",
        catatan_verifikasi: "",
    });

    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const authHeader = () => {
        const token = localStorage.getItem("sigap_admin_token");
        return token ? { Authorization: `Bearer ${token}` } : {};
    };

    const loadUser = async () => {
        try {
            setLoading(true);
            setErrorMsg("");

            // sesuaikan endpoint ini dengan backend-mu
            // kalau tadi kamu pakai /api/admin/users/:id, tinggal ganti aja
            const res = await axios.get(
                `${API_BASE_URL}/admin/users/${id}`,
                { headers: authHeader() }
            );

            if (!res.data.success) {
                setErrorMsg(res.data.message || "Gagal memuat data user");
                return;
            }

            const u = res.data.data;
            setUser(u);
            setForm({
                role: u.role || "masyarakat",
                status_verifikasi: u.status_verifikasi || "pending",
                catatan_verifikasi: u.catatan_verifikasi || "",
            });
        } catch (err) {
            console.error("loadUser error:", err);
            setErrorMsg("Terjadi kesalahan saat memuat data user");
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
        loadUser();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id]);

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({ ...prev, [name]: value }));
    };

    const handleSave = async (e) => {
        e.preventDefault();
        if (!user) return;

        setSaving(true);
        setErrorMsg("");
        setSuccessMsg("");

        try {
            const res = await axios.put(
                `${API_BASE_URL}/admin/users/${user.id}`,
                {
                    role: form.role,
                    status_verifikasi: form.status_verifikasi,
                    catatan_verifikasi: form.catatan_verifikasi,
                },
                { headers: authHeader() }
            );

            if (!res.data.success) {
                setErrorMsg(res.data.message || "Gagal menyimpan perubahan");
            } else {
                setSuccessMsg("Perubahan berhasil disimpan");
                await loadUser();
            }
        } catch (err) {
            console.error("save user error:", err);
            setErrorMsg("Terjadi kesalahan saat menyimpan perubahan");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!user) return;
        if (!window.confirm("Yakin ingin menghapus user ini?")) return;

        try {
            setSaving(true);
            setErrorMsg("");
            const res = await axios.delete(
                `${API_BASE_URL}/admin/users/${user.id}`,
                { headers: authHeader() }
            );
            if (!res.data.success) {
                setErrorMsg(res.data.message || "Gagal menghapus user");
            } else {
                navigate("/admin/users");
            }
        } catch (err) {
            console.error("delete user error:", err);
            setErrorMsg("Terjadi kesalahan saat menghapus user");
        } finally {
            setSaving(false);
        }
    };

    return (
        <AdminLayout>
            <div className="admin-page user-detail-page" style={{color:"black"}}>
                {/* HEADER */}
                <div className="user-detail-header">
                    <div>
                        <button
                            type="button"
                            className="link-back"
                            onClick={() => navigate(-1)}
                        >
                            ← Kembali ke daftar
                        </button>
                        <h1>Detail User & Verifikasi</h1>
                        <p>
                            Lihat data lengkap pengguna, cek foto KTP, lalu atur role dan
                            status verifikasinya.
                        </p>
                    </div>

                    {user && (
                        <div className="user-detail-header__badges">
                            <span
                                className={
                                    "pill pill--status pill--" +
                                    (user.status_verifikasi || "pending")
                                }
                            >
                                {statusLabel(user.status_verifikasi || "pending")}
                            </span>
                            <span className="pill pill--role">
                                {(user.role || "masyarakat").toUpperCase()}
                            </span>
                        </div>
                    )}
                </div>

                {loading ? (
                    <div className="user-detail-loading">
                        <Spinner animation="border" size="sm" />
                        <span>Memuat data user...</span>
                    </div>
                ) : errorMsg ? (
                    <div className="alert alert--error">{errorMsg}</div>
                ) : !user ? (
                    <p>Data user tidak ditemukan.</p>
                ) : (
                    <>
                        {successMsg && (
                            <div className="alert alert--success">{successMsg}</div>
                        )}

                        {/* BAGIAN ATAS: DATA + FOTO */}
                        <Row className="g-4 mb-4">
                            <Col md={7}>
                                <div className="card card-elevated">
                                    <div className="card-header-simple">
                                        <h5>Data Identitas</h5>
                                    </div>
                                    <div className="card-body">
                                        <dl className="user-detail-dl">
                                            <div className="user-detail-row">
                                                <dt>NIK</dt>
                                                <dd>{user.nik || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Nama</dt>
                                                <dd>{user.nama || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Username</dt>
                                                <dd>{user.username || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Tempat, Tgl Lahir</dt>
                                                <dd>
                                                    {(user.tempat_lahir || "-") +
                                                        ", " +
                                                        (user.tanggal_lahir || "-")}
                                                </dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Alamat</dt>
                                                <dd>{user.alamat || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Phone</dt>
                                                <dd>{user.phone || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Email</dt>
                                                <dd>{user.email || "-"}</dd>
                                            </div>
                                        </dl>
                                    </div>
                                </div>
                            </Col>

                            <Col md={5}>
                                <div className="card card-elevated">
                                    <div className="card-header-simple">
                                        <h5>Foto KTP</h5>
                                    </div>
                                    <div className="card-body ktp-section">
                                        <div className="ktp-preview ktp-preview--large">
                                            <img
                                                src={`${API_BASE_URL}/admin/users/${user.id}/ktp`}
                                                alt="Foto KTP"
                                                onError={(e) => {
                                                    e.currentTarget.style.display = "none";
                                                }}
                                            />
                                        </div>
                                        <p className="ktp-caption">
                                            Jika gambar tidak muncul, pastikan user mengupload KTP saat
                                            registrasi.
                                        </p>
                                    </div>
                                </div>
                            </Col>
                        </Row>

                        {/* BAGIAN BAWAH: VERIFIKASI */}
                        <form onSubmit={handleSave}>
                            <div className="card card-elevated">
                                <div className="card-header-simple">
                                    <h5>Verifikasi & Role</h5>
                                </div>
                                <div className="card-body">
                                    <Row className="g-3">
                                        <Col md={4}>
                                            <Form.Group className="mb-2">
                                                <Form.Label>Role Pengguna</Form.Label>
                                                <Form.Select
                                                    name="role"
                                                    value={form.role}
                                                    onChange={handleFormChange}
                                                >
                                                    <option value="masyarakat">Masyarakat</option>
                                                    <option value="officer">Officer</option>
                                                    <option value="admin">Admin</option>
                                                </Form.Select>
                                            </Form.Group>
                                        </Col>

                                        <Col md={4}>
                                            <Form.Group className="mb-2">
                                                <Form.Label>Status Verifikasi</Form.Label>
                                                <Form.Select
                                                    name="status_verifikasi"
                                                    value={form.status_verifikasi}
                                                    onChange={handleFormChange}
                                                >
                                                    <option value="pending">Pending</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </Form.Select>
                                            </Form.Group>
                                        </Col>

                                        <Col md={4}>
                                            <Form.Group className="mb-2">
                                                <Form.Label>Catatan Verifikasi</Form.Label>
                                                <Form.Control
                                                    as="textarea"
                                                    rows={2}
                                                    name="catatan_verifikasi"
                                                    value={form.catatan_verifikasi}
                                                    onChange={handleFormChange}
                                                    placeholder="Tuliskan alasan approve / reject (opsional)"
                                                />
                                            </Form.Group>
                                        </Col>
                                    </Row>

                                    <div className="user-detail-actions">
                                        <Button
                                            type="button"
                                            variant="outline-danger"
                                            onClick={handleDelete}
                                            disabled={saving}
                                        >
                                            Hapus User
                                        </Button>

                                        <div className="gap-2 d-flex">
                                            <Button
                                                type="button"
                                                variant="outline-secondary"
                                                onClick={() => navigate(-1)}
                                                disabled={saving}
                                            >
                                                Tutup
                                            </Button>
                                            <Button type="submit" variant="primary" disabled={saving}>
                                                {saving ? (
                                                    <>
                                                        <Spinner
                                                            as="span"
                                                            animation="border"
                                                            size="sm"
                                                            className="me-2"
                                                        />
                                                        Menyimpan...
                                                    </>
                                                ) : (
                                                    "Simpan Perubahan"
                                                )}
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </>
                )}
            </div>
        </AdminLayout>
    );
};

export default AdminUserDetailPage;
