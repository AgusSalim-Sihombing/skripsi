import React, { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Form, Button, Spinner, Card, Table, Modal } from "react-bootstrap";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import axios from "axios";
import ActionNotification from "../../../../shared/components/action_notification/ActionNotification";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const emptyForm = {
    status_verifikasi: "pending",
    catatan_verifikasi: "",
};



const statusLabel = (status) => {
    if (!status || status === "pending") return "Pending";
    if (status === "verified") return "Terverifikasi";
    if (status === "rejected") return "Ditolak";
    if (status === "takedown") return "Takedown";
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

const getStatusBadgeStyle = (status) => {
    if (status === "verified") {
        return {
            background: "#dcfce7",
            color: "#166534",
        };
    }
    if (status === "rejected") {
        return {
            background: "#fee2e2",
            color: "#991b1b",
        };
    }
    if (status === "takedown") {
        return {
            background: "#fee2e2",
            color: "#b91c1c",
        };
    }
    return {
        background: "#fef3c7",
        color: "#92400e",
    };
};

const AdminUserDetailPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();

    const [user, setUser] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");
    const [ktpError, setKtpError] = useState(false);
    const [notification, setNotification] = useState({
        open: false,
        type: "success",
        message: "",
    });

    const showNotification = (type, message) => {
        setNotification({
            open: true,
            type,
            message,
        });
    };

    const closeNotification = () => {
        setNotification((prev) => ({
            ...prev,
            open: false,
        }));
    };
    const [showTakedownModal, setShowTakedownModal] = useState(false);
    const [takedownReason, setTakedownReason] = useState("");

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
    }, [navigate, loadUser]);

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleSaveStatus = async (e) => {
        e.preventDefault();
        if (!user) return;

        try {
            if (!window.confirm(`Ubah status ?`)) return;
            setSaving(true);
            // setErrorMsg("");
            // setSuccessMsg("");

            const payload = {
                status_verifikasi: form.status_verifikasi,
                catatan_verifikasi: form.catatan_verifikasi,
            };

            const res = await axios.put(
                `${API_BASE_URL}/admin/users/${user.id}`,
                payload,
                { headers: authHeader() }
            );


            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal menyimpan status user");
                return;
            }

            // setSuccessMsg("Status user berhasil diperbarui");
            // ActionNotification("Status Berhasil Update")
            await loadUser();
            // setNotification("success", "Status berhasil diubah")
            showNotification("success", "Status berhasil diubah")

        } catch (err) {
            console.error("save status error:", err);
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan saat menyimpan status user"
            );
            showNotification("error", "Gagal mengubah status.");
            setErrorMsg("Gagal mengubah status");
        } finally {
            setSaving(false);
        }
    };

    const openTakedownModal = () => {
        setTakedownReason("");
        setShowTakedownModal(true);
    };

    const handleConfirmTakedown = async () => {
        if (!user) return;

        if (!takedownReason.trim()) {
            setErrorMsg("Alasan takedown wajib diisi");
            return;
        }

        try {
            setSaving(true);
            setErrorMsg("");
            setSuccessMsg("");

            const res = await axios.patch(
                `${API_BASE_URL}/admin/users/${user.id}/takedown`,
                { reason: takedownReason.trim() },
                { headers: authHeader() }
            );

            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal menonaktifkan akun user");
                return;
            }

            setShowTakedownModal(false);
            setTakedownReason("");
            setSuccessMsg("Akun user berhasil dinonaktifkan sementara");
            await loadUser();
        } catch (err) {
            console.error("takedown user error:", err);
            setErrorMsg(
                err?.response?.data?.message ||
                "Terjadi kesalahan saat menonaktifkan akun user"
            );
        } finally {
            setSaving(false);
        }
    };

    const handleRestoreUser = async () => {
        if (!user) return;
        if (!window.confirm("Aktifkan kembali akun pengguna ini?")) return;

        try {
            setSaving(true);
            setErrorMsg("");
            setSuccessMsg("");

            const res = await axios.patch(
                `${API_BASE_URL}/admin/users/${user.id}/restore`,
                {},
                { headers: authHeader() }
            );

            if (!res.data?.success) {
                setErrorMsg(res.data?.message || "Gagal mengaktifkan kembali akun");
                return;
            }

            setSuccessMsg("Akun user berhasil diaktifkan kembali");
            await loadUser();
        } catch (err) {
            console.error("restore user error:", err);
            setErrorMsg(
                err?.response?.data?.message ||
                "Terjadi kesalahan saat mengaktifkan kembali akun user"
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
                            Detail User & Status Akun
                        </h1>
                        <p style={{ marginTop: "8px", color: "#64748b" }}>
                            Lihat data lengkap pengguna, cek foto KTP, lalu kelola status akun
                            tanpa menghapus user.
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
                                    ...getStatusBadgeStyle(user.status_verifikasi),
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

                {errorMsg && (
                    <div className="alert alert-danger" style={{ marginBottom: "16px" }}>
                        {errorMsg}
                    </div>
                )}

                {successMsg && (
                    <div className="alert alert-success" style={{ marginBottom: "16px" }}>
                        {successMsg}
                    </div>
                )}

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
                ) : !user ? (
                    <div className="alert alert-warning">Data user tidak ditemukan.</div>
                ) : (
                    <>
                        <div
                            style={{
                                display: "flex",
                                gap: "16px",
                                width: "100%",
                                alignItems: "stretch",
                                flexWrap: "wrap",
                            }}
                        >
                            <div
                                style={{
                                    flex: "1 1 420px",
                                    display: "flex",
                                    flexDirection: "column",
                                    gap: "16px",
                                }}
                            >
                                <Card
                                    style={{
                                        border: "none",
                                        borderRadius: "20px",
                                        boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                    }}
                                >
                                    <Card.Body style={{ padding: "20px" }}>
                                        <h5 style={{ marginBottom: "16px", fontWeight: 700 }}>
                                            Data Identitas
                                        </h5>

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
                                    </Card.Body>
                                </Card>

                                <Card
                                    style={{
                                        border: "none",
                                        borderRadius: "20px",
                                        boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                    }}
                                >
                                    <Card.Body style={{ padding: "20px" }}>
                                        <h5 style={{ marginBottom: "20px", fontWeight: 700 }}>
                                            Kelola Status Akun
                                        </h5>

                                        {user.status_verifikasi === "takedown" ? (
                                            <>
                                                <div
                                                    style={{
                                                        background: "#fef2f2",
                                                        border: "1px solid #fecaca",
                                                        borderRadius: "16px",
                                                        padding: "16px",
                                                        marginBottom: "16px",
                                                    }}
                                                >
                                                    <h6
                                                        style={{
                                                            margin: "0 0 8px 0",
                                                            color: "#b91c1c",
                                                            fontWeight: 700,
                                                        }}
                                                    >
                                                        Akun dinonaktifkan sementara
                                                    </h6>
                                                    <p
                                                        style={{
                                                            margin: 0,
                                                            color: "#7f1d1d",
                                                            lineHeight: 1.7,
                                                        }}
                                                    >
                                                        {user.catatan_verifikasi ||
                                                            "Tidak ada alasan takedown."}
                                                    </p>
                                                </div>

                                                <Table hover>
                                                    <tbody>
                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Role User
                                                            </th>
                                                            <td>{user.role || "-"}</td>
                                                        </tr>
                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Status Akun
                                                            </th>
                                                            <td>Takedown</td>
                                                        </tr>
                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Alasan
                                                            </th>
                                                            <td>{user.catatan_verifikasi || "-"}</td>
                                                        </tr>
                                                    </tbody>
                                                </Table>

                                                <div style={{ display: "flex", justifyContent: "flex-end" }}>
                                                    <Button
                                                        type="button"
                                                        variant="success"
                                                        onClick={handleRestoreUser}
                                                        disabled={saving}
                                                    >
                                                        {saving ? "Memproses..." : "Aktifkan Kembali Akun Pengguna"}
                                                    </Button>
                                                </div>
                                            </>
                                        ) : (
                                            <form onSubmit={handleSaveStatus}>
                                                <Table hover>
                                                    <tbody>
                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Role User
                                                            </th>
                                                            <td>{user.role || "-"}</td>
                                                        </tr>

                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Status Verifikasi
                                                            </th>
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
                                                                    }}
                                                                >
                                                                    <option value="pending">Pending</option>
                                                                    <option value="verified">Verified</option>
                                                                    <option value="rejected">Rejected</option>
                                                                </Form.Select>
                                                            </td>
                                                        </tr>

                                                        <tr>
                                                            <th
                                                                style={{
                                                                    width: "220px",
                                                                    backgroundColor: "#f8fafc",
                                                                }}
                                                            >
                                                                Catatan Status Akun
                                                            </th>
                                                            <td>
                                                                <Form.Control
                                                                    type="text"
                                                                    name="catatan_verifikasi"
                                                                    value={form.catatan_verifikasi}
                                                                    onChange={handleFormChange}
                                                                    placeholder="Tuliskan catatan admin (opsional)"
                                                                    style={{
                                                                        width: "100%",
                                                                        background: "white",
                                                                        color: "black",
                                                                    }}
                                                                />
                                                            </td>
                                                        </tr>
                                                    </tbody>
                                                </Table>

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
                                                        variant="danger"
                                                        onClick={openTakedownModal}
                                                        disabled={saving}
                                                    >
                                                        Nonaktifkan Akun User
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
                                                            "Simpan Status"
                                                        )}
                                                    </Button>
                                                </div>
                                            </form>
                                        )}
                                    </Card.Body>
                                </Card>
                            </div>

                            <div
                                style={{
                                    flex: "1 1 520px",
                                    display: "flex",
                                }}
                            >
                                <Card
                                    style={{
                                        border: "none",
                                        borderRadius: "20px",
                                        boxShadow: "0 10px 30px rgba(15, 23, 42, 0.06)",
                                        width: "100%",
                                        overflow: "hidden",
                                    }}
                                >
                                    <Card.Body
                                        style={{
                                            padding: "20px",
                                            display: "flex",
                                            flexDirection: "column",
                                            height: "100%",
                                        }}
                                    >
                                        <h5
                                            style={{
                                                marginBottom: "12px",
                                                fontWeight: 700,
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
                                                minHeight: "540px",
                                            }}
                                        >
                                            {!ktpError ? (
                                                <img
                                                    src={`${API_BASE_URL}/admin/users/${user.id}/ktp`}
                                                    alt="Foto KTP"
                                                    onError={() => setKtpError(true)}
                                                    style={{
                                                        width: "100%",
                                                        height: "100%",
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
                                            }}
                                        >
                                            Jika gambar tidak muncul, pastikan user mengunggah KTP saat registrasi.
                                        </p>
                                    </Card.Body>
                                </Card>
                            </div>
                        </div>

                        <Modal
                            show={showTakedownModal}
                            onHide={() => !saving && setShowTakedownModal(false)}
                            centered
                            backdrop="static"
                            keyboard={!saving}
                            contentClassName="takedown-modal-content"
                            dialogClassName="takedown-modal-dialog"
                            backdropClassName="takedown-modal-backdrop"
                        >
                            <Modal.Header closeButton={!saving}>
                                <Modal.Title>Nonaktifkan Akun User</Modal.Title>
                            </Modal.Header>
                            +

                            <Modal.Body>
                                <p style={{ marginBottom: "12px", color: "#475569" }}>
                                    Masukkan alasan kenapa akun ini dinonaktifkan sementara.
                                    Alasan ini akan disimpan dan bisa ditampilkan ke pengguna.
                                </p>

                                <Form.Group>
                                    <Form.Label>Alasan Takedown</Form.Label>
                                    <Form.Control
                                        as="textarea"
                                        rows={4}
                                        value={takedownReason}
                                        onChange={(e) => setTakedownReason(e.target.value)}
                                        placeholder="Contoh: Akun melanggar aturan komunitas / penggunaan tidak sesuai kebijakan."
                                        disabled={saving}
                                        autoFocus
                                    />
                                </Form.Group>
                            </Modal.Body>

                            <Modal.Footer>
                                <Button
                                    variant="secondary"
                                    onClick={() => setShowTakedownModal(false)}
                                    disabled={saving}
                                >
                                    Batal
                                </Button>
                                <Button
                                    variant="danger"
                                    onClick={handleConfirmTakedown}
                                    disabled={saving}
                                >
                                    {saving ? "Memproses..." : "Oke, Nonaktifkan"}
                                </Button>
                            </Modal.Footer>
                        </Modal>
                    </>
                )}
            </div>
            <ActionNotification
                open={notification.open}
                type={notification.type}
                message={notification.message}
                onClose={closeNotification}
                duration={2200}
            />
        </AdminLayout>
    );
};

export default AdminUserDetailPage;