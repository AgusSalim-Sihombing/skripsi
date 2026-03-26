import React, { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Row, Col, Form, Button, Spinner, Card, Table } from "react-bootstrap";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const emptyForm = {
    nik: "",
    nama: "",
    tempat_lahir: "",
    tanggal_lahir: "",
    alamat: "",
    phone: "",
    email: "",
    username: "",
    role: "masyarakat",
    status_verifikasi: "pending",
    catatan_verifikasi: ""
};

const statusLabel = (status) => {
    if (!status || status === "pending") return "Pending";
    if (status === "verified") return "Terverifikasi";
    if (status === "rejected") return "Ditolak";
    return status;
};

const formatDateInput = (date) => {
    if (!date) return "";
    return String(date).slice(0, 10);
};

const formatDateDisplay = (date) => {
    if (!date) return "-";
    const d = new Date(date);
    if (Number.isNaN(d.getTime())) return date;
    return d.toLocaleDateString("id-ID", {
        day: "2-digit",
        month: "long",
        year: "numeric",
    });
};

const InfoItem = ({ label, value }) => (
    <div
        style={{
            display: "grid",
            gridTemplateColumns: "170px 1fr",
            gap: "12px",
            padding: "10px 0",
            borderBottom: "1px solid #eef2f7",
        }}
    >
        <div style={{ fontWeight: 600, color: "#475569" }}>{label}</div>
        <div style={{ color: "#0f172a", wordBreak: "break-word" }}>{value || "-"}</div>
    </div>
);

const AdminUserDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [user, setUser] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");
    const [isEditMode, setIsEditMode] = useState(false);
    const [ktpError, setKtpError] = useState(false);

    const authHeader = () => {
        const token = localStorage.getItem("sigap_admin_token");
        return token ? { Authorization: `Bearer ${token}` } : {};
    };

    const loadUser = useCallback(async () => {
        try {
            setLoading(true);
            setErrorMsg("");
            setSuccessMsg("");
            setKtpError(false);

            const res = await axios.get(`${API_BASE_URL}/admin/users/${id}`, {
                headers: authHeader(),
            });

            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal memuat data user");
                return;
            }

            const u = res.data.data;
            setUser(u);
            setForm({
                nik: u.nik || "",
                nama: u.nama || "",
                tempat_lahir: u.tempat_lahir || "",
                tanggal_lahir: formatDateInput(u.tanggal_lahir),
                alamat: u.alamat || "",
                phone: u.phone || "",
                email: u.email || "",
                username: u.username || "",
                role: u.role || "masyarakat",
                status_verifikasi: u.status_verifikasi || "pending",
                catatan_verifikasi: u.catatan_verifikasi || "",
            });
        } catch (err) {
            console.error("loadUser error:", err);
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan saat memuat data user"
            );
        } finally {
            setLoading(false);
        }
    }, [id]);

    useEffect(() => {
        const token = localStorage.getItem("sigap_admin_token");
        if (!token) {
            navigate("/login-admin");
            return;
        }
        loadUser();
    }, [id, navigate, loadUser]);

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleSave = async (e) => {
        e.preventDefault();
        if (!user) return;

        try {
            setSaving(true);
            setErrorMsg("");
            setSuccessMsg("");

            const payload = {
                nik: form.nik,
                nama: form.nama,
                tempat_lahir: form.tempat_lahir,
                tanggal_lahir: form.tanggal_lahir || null,
                alamat: form.alamat,
                phone: form.phone,
                email: form.email,
                username: form.username,
                role: form.role,
                status_verifikasi: form.status_verifikasi,
                catatan_verifikasi: form.catatan_verifikasi,
            };

            const res = await axios.put(
                `${API_BASE_URL}/admin/users/${user.id}`,
                payload,
                { headers: authHeader() }
            );

            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal menyimpan perubahan");
                alert("Gagal Menyimpan Perubahan")
                return;
            }

            setSuccessMsg("Perubahan berhasil disimpan");

            setIsEditMode(false);
            alert("Data Berhasil Diupdate");
            await loadUser();
        } catch (err) {
            console.error("save user error:", err);
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan saat menyimpan perubahan"
            );
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

            const res = await axios.delete(`${API_BASE_URL}/admin/users/${user.id}`, {
                headers: authHeader(),
            });

            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal menghapus user");
                return;
            }

            navigate("/admin/users");
        } catch (err) {
            console.error("delete user error:", err);
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan saat menghapus user"
            );
        } finally {
            setSaving(false);
        }
    };

    return (
        <AdminLayout>
            <div
                className="admin-page user-detail-page"
                style={{
                    color: "#0f172a",
                    padding: "24px",
                    background: "#f8fafc",
                    minHeight: "100vh",
                }}
            >
                {/* Header */}
                <div
                    style={{
                        marginBottom: "24px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "flex-start",
                        gap: "16px",
                        flexWrap: "wrap",
                    }}
                >
                    <div>
                        <button
                            type="button"
                            onClick={() => navigate(-1)}
                            style={{
                                border: "none",
                                background: "transparent",
                                color: "#2563eb",
                                padding: 0,
                                marginBottom: "8px",
                                fontWeight: 600,
                                cursor: "pointer",
                            }}
                        >
                            ← Kembali ke daftar
                        </button>

                        <h1 style={{ margin: 0, fontSize: "28px", fontWeight: 700 }}>
                            Detail User & Verifikasi
                        </h1>
                        <p style={{ marginTop: "8px", color: "#64748b" }}>
                            Lihat data lengkap pengguna, cek foto KTP, lalu atur role dan status
                            verifikasinya.
                        </p>
                    </div>

                    {user && (
                        <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
                            <span
                                style={{
                                    padding: "8px 14px",
                                    borderRadius: "999px",
                                    fontSize: "13px",
                                    fontWeight: 700,
                                    background:
                                        user.status_verifikasi === "verified"
                                            ? "#dcfce7"
                                            : user.status_verifikasi === "rejected"
                                                ? "#fee2e2"
                                                : "#fef3c7",
                                    color:
                                        user.status_verifikasi === "verified"
                                            ? "#166534"
                                            : user.status_verifikasi === "rejected"
                                                ? "#991b1b"
                                                : "#92400e",
                                }}
                            >
                                {statusLabel(user.status_verifikasi)}
                            </span>

                            <span
                                style={{
                                    padding: "8px 14px",
                                    borderRadius: "999px",
                                    fontSize: "13px",
                                    fontWeight: 700,
                                    background: "#dbeafe",
                                    color: "#1d4ed8",
                                    textTransform: "uppercase",
                                }}
                            >
                                {user.role || "masyarakat"}
                            </span>
                        </div>
                    )}
                </div>

                {loading ? (
                    <div
                        style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "10px",
                            padding: "20px",
                            background: "#fff",
                            borderRadius: "16px",
                        }}
                    >
                        <Spinner animation="border" size="sm" />
                        <span>Memuat data user...</span>
                    </div>
                ) : errorMsg ? (
                    <div className="alert alert-danger">{errorMsg}</div>
                ) : !user ? (
                    <div className="alert alert-warning">Data user tidak ditemukan.</div>
                ) : (
                    <>
                        <form onSubmit={handleSave}>
                            <div
                                // className="container"
                                style={{
                                    display: "flex",
                                    gap: "10px",
                                    width: "100%",
                                    // height: "calc(100vh - 180px)",
                                    overflow: "hidden",
                                    alignItems: "stretch",
                                }}
                            >
                                {/* KIRI */}
                                <div
                                    className="data-verifikasi"
                                    style={{
                                        width: "50%",
                                        height: "100%",
                                        display: "flex",
                                        flexDirection: "column",
                                        gap: "3px",
                                        paddingRight: "4px",
                                    }}
                                >
                                    {/* Data identitas */}
                                    <Card
                                        style={{
                                            border: "none",
                                            borderRadius: "20px",
                                            boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                            fontSize: "14px",
                                        }}
                                    >
                                        <Card.Body style={{ padding: "0px" }}>
                                            <div
                                                style={{
                                                    display: "flex",
                                                    justifyContent: "space-between",
                                                    alignItems: "center",
                                                    marginBottom: "20px",
                                                    gap: "12px",
                                                    flexWrap: "wrap",
                                                }}
                                            >
                                                <h3 style={{ margin: 0, fontWeight: 700 }}>Data Identitas</h3>

                                                <Button
                                                    type="button"
                                                    variant={isEditMode ? "secondary" : "outline-primary"}
                                                    onClick={() => setIsEditMode((prev) => !prev)}
                                                    disabled={saving}
                                                >
                                                    {isEditMode ? "Batal Edit" : "Edit"}
                                                </Button>
                                            </div>

                                            {!isEditMode ? (
                                                <>
                                                    <InfoItem label="NIK" value={user.nik} />
                                                    <InfoItem label="Nama" value={user.nama} />
                                                    <InfoItem label="Username" value={user.username} />
                                                    <InfoItem label="Tempat Lahir" value={user.tempat_lahir} />
                                                    <InfoItem
                                                        label="Tanggal Lahir"
                                                        value={formatDateDisplay(user.tanggal_lahir)}
                                                    />
                                                    <InfoItem label="Alamat" value={user.alamat} />
                                                    <InfoItem label="No. Telepon" value={user.phone} />
                                                    <InfoItem label="Email" value={user.email} />
                                                </>
                                            ) : (
                                                <div className="table-edit-container">
                                                    <table className="table-edit-data-identitas">
                                                        <tbody>
                                                            <tr>
                                                                <th>NIK</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="text"
                                                                        name="nik"
                                                                        className="custom-input"
                                                                        value={form.nik}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Nama</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="text"
                                                                        name="nama"
                                                                        className="custom-input"
                                                                        value={form.nama}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Username</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="text"
                                                                        name="username"
                                                                        className="custom-input"
                                                                        value={form.username}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Tempat Lahir</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="text"
                                                                        name="tempat_lahir"
                                                                        className="custom-input"
                                                                        value={form.tempat_lahir}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Tanggal Lahir</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="date"
                                                                        name="tanggal_lahir"
                                                                        className="custom-input"
                                                                        value={form.tanggal_lahir}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>No. Telepon</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="text"
                                                                        name="phone"
                                                                        className="custom-input"
                                                                        value={form.phone}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Email</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        type="email"
                                                                        name="email"
                                                                        className="custom-input"
                                                                        value={form.email}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                            <tr>
                                                                <th>Alamat</th>
                                                                <td className="separator">:</td>
                                                                <td>
                                                                    <Form.Control
                                                                        as="textarea"
                                                                        rows={3}
                                                                        name="alamat"
                                                                        className="custom-input"
                                                                        value={form.alamat}
                                                                        onChange={handleFormChange}
                                                                    />
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            )}
                                        </Card.Body>
                                    </Card>

                                    {/* Verifikasi & role */}
                                    <Card
                                        style={{
                                            border: "none",
                                            borderRadius: "20px",
                                            boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                        }}
                                    >
                                        <Card.Body style={{ padding: "16px" }}>
                                            <h5 style={{ marginBottom: "20px", fontWeight: 700 }}>
                                                Verifikasi & Role
                                            </h5>

                                            <div style={{ overflowX: "auto" }}>
                                                <Table

                                                    // bordered
                                                    // style={{
                                                    //     marginBottom: 0,
                                                    //     verticalAlign: "middle",
                                                    //     backgroundColor: "white",

                                                    // }}
                                                    hover
                                                >
                                                    <tbody>
                                                        <tr>
                                                            <th style={{ width: "220px", backgroundColor: "#f8fafc" }}>Role User</th>
                                                            <td>{user?.role || "-"}</td>
                                                        </tr>

                                                        <tr style={{
                                                            background: "white"
                                                        }}>
                                                            <th>Status Verifikasi</th>
                                                            <td>
                                                                <Form.Select
                                                                    name="status_verifikasi"
                                                                    value={form.status_verifikasi}
                                                                    onChange={handleFormChange}
                                                                    style={{
                                                                        height: "44px",
                                                                        maxWidth: "250px",
                                                                        backgroundColor: "white",
                                                                        color: "black",
                                                                        borderRadius: "5px",
                                                                        width: "100%"
                                                                    }}
                                                                >
                                                                    <option value="pending">Pending</option>
                                                                    <option value="verified">Verified</option>
                                                                    <option value="rejected">Rejected</option>
                                                                </Form.Select>
                                                            </td>
                                                        </tr>


                                                        <tr>
                                                            <th style={{ backgroundColor: "#f8fafc" }}>Catatan Verifikasi</th>
                                                            <td>
                                                                <Form.Control
                                                                    type="text"
                                                                    name="catatan_verifikasi"
                                                                    value={form.catatan_verifikasi}
                                                                    onChange={handleFormChange}
                                                                    placeholder="Tuliskan alasan approve / reject (opsional)"
                                                                    style={{
                                                                        width: "100%",
                                                                        background: "white",
                                                                        border: "none",
                                                                        color: "black"
                                                                    }}
                                                                />
                                                            </td>
                                                        </tr>
                                                    </tbody>
                                                </Table>
                                            </div>

                                            <div
                                                style={{
                                                    display: "flex",
                                                    justifyContent: "space-between",
                                                    alignItems: "center",
                                                    gap: "12px",
                                                    marginTop: "24px",
                                                    flexWrap: "wrap",
                                                }}
                                            >
                                                <Button
                                                    type="button"
                                                    // variant="outline-danger"
                                                    className="btn-delete"
                                                    onClick={handleDelete}
                                                    disabled={saving}
                                                >
                                                    Hapus User
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
                                        </Card.Body>
                                    </Card>
                                </div>

                                {/* KANAN */}
                                <div
                                    className="foto-ktp"
                                    style={{
                                        width: "70%",
                                        height: "100%",
                                        display: "flex",
                                    }}
                                >
                                    <Card
                                        style={{
                                            border: "none",
                                            borderRadius: "20px",
                                            boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                            width: "100%",
                                            height: "100%",
                                            overflow: "hidden",
                                        }}
                                    >
                                        <Card.Body
                                            style={{
                                                padding: "20px",
                                                display: "flex",
                                                flexDirection: "column",
                                                height: "100%",
                                                overflow: "hidden",
                                            }}
                                        >
                                            <h5
                                                style={{
                                                    marginBottom: "12px",
                                                    fontWeight: 700,
                                                    flexShrink: 0,
                                                }}
                                            >
                                                Foto KTP
                                            </h5>

                                            <div
                                                style={{
                                                    flex: 1,
                                                    width: "100%",
                                                    borderRadius: "16px",
                                                    border: "1px solid #e2e8f0",
                                                    overflow: "hidden",
                                                    background: "#f8fafc",
                                                    display: "flex",
                                                    justifyContent: "center",
                                                    alignItems: "center",
                                                    minHeight: 0,

                                                }}
                                            >
                                                {!ktpError ? (
                                                    <img
                                                        src={`${API_BASE_URL}/admin/users/${user.id}/ktp`}
                                                        alt="Foto KTP"
                                                        onError={() => setKtpError(true)}
                                                        style={{
                                                            width: "100%",
                                                            height: "650px",
                                                            objectFit: "contain",
                                                            display: "block",
                                                        }}
                                                    />
                                                ) : (
                                                    <div
                                                        style={{
                                                            padding: "24px",
                                                            textAlign: "center",
                                                            color: "#64748b",
                                                        }}
                                                    >
                                                        Foto KTP tidak tersedia
                                                    </div>
                                                )}
                                            </div>

                                            <p
                                                style={{
                                                    marginTop: "10px",
                                                    marginBottom: 0,
                                                    color: "#64748b",
                                                    fontSize: "14px",
                                                    flexShrink: 0,
                                                }}
                                            >
                                                Jika gambar tidak muncul, pastikan user mengunggah KTP saat registrasi.
                                            </p>
                                        </Card.Body>
                                    </Card>
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