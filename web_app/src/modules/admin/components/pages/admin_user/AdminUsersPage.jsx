// src/modules/admin/pages/users/AdminUsersPage.jsx
import React, { useEffect, useState } from "react";
import AdminLayout from "../../../../shared/layout/AdminLayout";
import {
    getAdminUsers,
    createAdminUser,
    updateAdminUser,
    deleteAdminUser,
} from "../../../../../services/adminUserService";
import { Modal, Button, Form } from "react-bootstrap";
import { useNavigate } from "react-router-dom";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const AdminUsersPage = ({ title = "Data Pengguna", defaultRole = "" }) => {
    const navigate = useNavigate();
    const [users, setUsers] = useState([]);
    const [filters, setFilters] = useState({
        search: "",
        role: defaultRole || "",
        status_verifikasi: "",
    });
    const [loading, setLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const [showModal, setShowModal] = useState(false);
    const [modalMode, setModalMode] = useState("edit"); // "create" | "edit"
    const [selectedUser, setSelectedUser] = useState(null);
    const [form, setForm] = useState({
        nik: "",
        nama: "",
        username: "",
        phone: "",
        email: "",
        tempat_lahir: "",
        tanggal_lahir: "",
        alamat: "",
        role: "masyarakat",
        status_verifikasi: "pending",
        catatan_verifikasi: "",
        password: "",
    });
    const [saving, setSaving] = useState(false);

    // ========== LOAD LIST ==========
    useEffect(() => {
        const fetchData = async () => {
            try {
                setLoading(true);
                setErrorMsg("");
                const res = await getAdminUsers(filters);
                if (!res.success) {
                    setErrorMsg(res.message || "Gagal memuat data pengguna");
                    setUsers([]);
                    return;
                }
                setUsers(res.data || []);
            } catch (err) {
                console.error("getAdminUsers error:", err);
                setErrorMsg("Terjadi kesalahan saat memuat data pengguna");
            } finally {
                setLoading(false);
            }
        };

        fetchData();
    }, [filters]);

    // ========== FILTER ==========
    const handleFilterChange = (e) => {
        const { name, value } = e.target;
        setFilters((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    // ========== MODAL CREATE ==========
    const openCreateModal = () => {
        setModalMode("create");
        setSelectedUser(null);
        setForm({
            nik: "",
            nama: "",
            username: "",
            phone: "",
            email: "",
            tempat_lahir: "",
            tanggal_lahir: "",
            alamat: "",
            role: "masyarakat",
            status_verifikasi: "pending",
            catatan_verifikasi: "",
            password: "",
        });
        setErrorMsg("");
        setSuccessMsg("");
        setShowModal(true);
    };

    // ========== MODAL EDIT / DETAIL ==========
    const openDetailModal = (user) => {
        setModalMode("edit");
        setSelectedUser(user);
        setForm({
            nik: user.nik || "",
            nama: user.nama || "",
            username: user.username || "",
            phone: user.phone || "",
            email: user.email || "",
            tempat_lahir: user.tempat_lahir || "",
            tanggal_lahir: user.tanggal_lahir || "",
            alamat: user.alamat || "",
            role: user.role || "masyarakat",
            status_verifikasi: user.status_verifikasi || "pending",
            catatan_verifikasi: user.catatan_verifikasi || "",
            password: "",
        });
        setErrorMsg("");
        setSuccessMsg("");
        setShowModal(true);
    };

    const closeModal = () => {
        setShowModal(false);
        setSelectedUser(null);
    };

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    // ========== SAVE (CREATE / UPDATE) ==========
    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setErrorMsg("");
        setSuccessMsg("");

        try {
            if (modalMode === "create") {
                // payload create user via admin
                if (!form.nik || !form.nama || !form.username || !form.password) {
                    setErrorMsg("NIK, Nama, Username, dan Password wajib diisi.");
                    setSaving(false);
                    return;
                }

                const payload = {
                    nik: form.nik,
                    nama: form.nama,
                    username: form.username,
                    password: form.password,
                    phone: form.phone || null,
                    email: form.email || null,
                    tempat_lahir: form.tempat_lahir || null,
                    tanggal_lahir: form.tanggal_lahir || null,
                    alamat: form.alamat || null,
                    role: form.role || "masyarakat",
                    status_verifikasi: form.status_verifikasi || "pending",
                    catatan_verifikasi: form.catatan_verifikasi || "",
                };

                const res = await createAdminUser(payload);
                if (!res.success) {
                    setErrorMsg(res.message || "Gagal menambahkan user");
                } else {
                    setSuccessMsg("User berhasil ditambahkan");
                    // refresh list
                    setFilters((prev) => ({ ...prev }));
                    setShowModal(false);
                }
            } else if (modalMode === "edit" && selectedUser) {
                // update: fokus ke verifikasi & role, + catatan
                const payload = {
                    role: form.role,
                    status_verifikasi: form.status_verifikasi,
                    catatan_verifikasi: form.catatan_verifikasi,
                };

                // kalau mau: bisa kirim phone/email juga
                // payload.phone = form.phone;
                // payload.email = form.email;

                const res = await updateAdminUser(selectedUser.id, payload);
                if (!res.success) {
                    setErrorMsg(res.message || "Gagal menyimpan perubahan");
                } else {
                    setSuccessMsg("Perubahan berhasil disimpan");
                    setFilters((prev) => ({ ...prev })); // reload list
                    setShowModal(false);
                }
            }
        } catch (err) {
            console.error("save user error:", err);
            setErrorMsg("Terjadi kesalahan saat menyimpan data");
        } finally {
            setSaving(false);
        }
    };

    // ========== DELETE ==========
    const handleDelete = async (user) => {
        if (!window.confirm(`Yakin ingin menghapus user ${user.nama} ?`)) return;
        try {
            setErrorMsg("");
            setSuccessMsg("");
            const res = await deleteAdminUser(user.id);
            if (!res.success) {
                setErrorMsg(res.message || "Gagal menghapus user");
                return;
            }
            setSuccessMsg("User berhasil dihapus");
            setFilters((prev) => ({ ...prev }));
        } catch (err) {
            console.error("deleteUser error:", err);
            setErrorMsg("Terjadi kesalahan saat menghapus user");
        }
    };

    return (
        <AdminLayout>
            <div className="dashboard-header">
                <h1>{title}</h1>
                <p>
                    Kelola data pengguna, verifikasi identitas, dan lihat foto KTP untuk
                    mengatur role & status verifikasi.
                </p>
            </div>

            {/* FILTER + ADD BUTTON */}
            <div className="card" style={{ marginBottom: "1rem" }}>
                <div
                    className="filter-row"
                    style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}
                >
                    <input
                        type="text"
                        name="search"
                        placeholder="Cari nama / NIK / username / email..."
                        value={filters.search}
                        onChange={handleFilterChange}
                        style={{ flex: 1, backgroundColor: "#f9fafb", border: "1px solid #d1d5db", borderRadius: 4, padding: "0.5rem" }}
                    />
                    <select
                        name="role"
                        value={filters.role}
                        onChange={handleFilterChange}
                    >
                        <option value="">Semua Role</option>
                        <option value="masyarakat">Masyarakat</option>
                        <option value="officer">Officer</option>
                        <option value="admin">Admin</option>
                    </select>
                    <select
                        name="status_verifikasi"
                        value={filters.status_verifikasi}
                        onChange={handleFilterChange}
                    >
                        <option value="">Semua Status</option>
                        <option value="pending">Pending</option>
                        <option value="verified">Verified</option>
                        <option value="rejected">Rejected</option>
                    </select>

                    <Button variant="primary" onClick={openCreateModal}>
                        + Tambah User
                    </Button>
                </div>
            </div>

            {errorMsg && <div className="alert alert--error">{errorMsg}</div>}
            {successMsg && <div className="alert alert--success">{successMsg}</div>}

            {/* TABLE */}
            <div className="card" style={{ color: "black" }}>
                {loading ? (
                    <p>Memuat data pengguna...</p>
                ) : users.length === 0 ? (
                    <p>Tidak ada data pengguna.</p>
                ) : (
                    <div className="table-wrapper">
                        <table className="simple-table">
                            <thead>
                                <tr>
                                    <th>NIK</th>
                                    <th>Nama</th>
                                    <th>Username</th>
                                    <th>Role</th>
                                    <th>Status Verifikasi</th>
                                    <th>Kontak</th>
                                    <th>Created</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                {users.map((u) => (
                                    <tr key={u.id}>
                                        <td>{u.nik}</td>
                                        <td>{u.nama}</td>
                                        <td>{u.username}</td>
                                        <td style={{ textTransform: "capitalize" }}>{u.role}</td>
                                        <td>{u.status_verifikasi}</td>
                                        <td>
                                            {u.phone || "-"}
                                            <br />
                                            <span style={{ fontSize: "0.8rem", color: "#6b7280" }}>
                                                {u.email || ""}
                                            </span>
                                        </td>
                                        <td>
                                            {u.created_at
                                                ? new Date(u.created_at).toLocaleDateString()
                                                : "-"}
                                        </td>
                                        <td>
                                            <button
                                                type="button"
                                                className="btn btn-outline btn-sm"
                                                onClick={() => navigate(`/admin/users/${u.id}`)}
                                            >
                                                Detail & Verifikasi
                                            </button>
                                            <button
                                                type="button"
                                                className="btn btn-secondary"
                                                style={{
                                                    padding: "0.2rem 0.5rem",
                                                    fontSize: "0.8rem",
                                                    marginLeft: "0.3rem",
                                                }}
                                                onClick={() => handleDelete(u)}
                                            >
                                                Hapus
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* MODAL CREATE / EDIT */}
            <Modal show={showModal} onHide={closeModal} centered size="lg">
                <Form onSubmit={handleSubmit}>
                    <Modal.Header closeButton>
                        <Modal.Title>
                            {modalMode === "create" ? "Tambah User" : "Detail User & Verifikasi"}
                        </Modal.Title>
                    </Modal.Header>
                    <Modal.Body className="user-detail-modal">
                        {modalMode === "edit" && selectedUser && (
                            <>
                                {/* DATA + FOTO KTP */}
                                <div className="user-detail-grid">
                                    {/* KOLUM KIRI: DATA USER */}
                                    <div className="user-detail-left">
                                        <h5 className="mb-3">Data Identitas</h5>
                                        <dl className="user-detail-dl">
                                            <div className="user-detail-row">
                                                <dt>NIK</dt>
                                                <dd>{selectedUser.nik || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Nama</dt>
                                                <dd>{selectedUser.nama || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Username</dt>
                                                <dd>{selectedUser.username || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Tempat, Tgl Lahir</dt>
                                                <dd>
                                                    {(selectedUser.tempat_lahir || "-") +
                                                        ", " +
                                                        (selectedUser.tanggal_lahir || "-")}
                                                </dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Alamat</dt>
                                                <dd>{selectedUser.alamat || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Phone</dt>
                                                <dd>{selectedUser.phone || "-"}</dd>
                                            </div>
                                            <div className="user-detail-row">
                                                <dt>Email</dt>
                                                <dd>{selectedUser.email || "-"}</dd>
                                            </div>
                                        </dl>
                                    </div>

                                    {/* KOLUM KANAN: FOTO KTP */}
                                    <div className="user-detail-right">
                                        <h5 className="mb-3 text-center">Foto KTP</h5>
                                        <div className="ktp-preview">
                                            <img
                                                src={`${API_BASE_URL}/admin/users/${selectedUser.id}/ktp`}
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

                                <hr className="mt-3 mb-3" />
                            </>
                        )}

                        {/* FORM CREATE ATAU VERIFIKASI */}
                        {errorMsg && (
                            <div className="alert alert--error" style={{ marginBottom: 8 }}>
                                {errorMsg}
                            </div>
                        )}

                        {modalMode === "create" && (
                            <>
                                <h5 className="mb-3">Data Akun Baru</h5>
                                <Form.Group className="mb-2">
                                    <Form.Label>NIK</Form.Label>
                                    <Form.Control
                                        name="nik"
                                        value={form.nik}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                                <Form.Group className="mb-2">
                                    <Form.Label>Nama Lengkap</Form.Label>
                                    <Form.Control
                                        name="nama"
                                        value={form.nama}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                                <Form.Group className="mb-2">
                                    <Form.Label>Username</Form.Label>
                                    <Form.Control
                                        name="username"
                                        value={form.username}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                                <Form.Group className="mb-2">
                                    <Form.Label>Password</Form.Label>
                                    <Form.Control
                                        type="password"
                                        name="password"
                                        value={form.password}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                                <Form.Group className="mb-2">
                                    <Form.Label>Phone</Form.Label>
                                    <Form.Control
                                        name="phone"
                                        value={form.phone}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                                <Form.Group className="mb-3">
                                    <Form.Label>Email</Form.Label>
                                    <Form.Control
                                        name="email"
                                        value={form.email}
                                        onChange={handleFormChange}
                                    />
                                </Form.Group>
                            </>
                        )}

                        <h5 className="mb-3">
                            {modalMode === "create" ? "Role & Status Awal" : "Verifikasi & Role"}
                        </h5>

                        <div className="verify-grid">
                            <div className="verify-left">
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
                            </div>

                            <div className="verify-right">
                                <Form.Group className="mb-2">
                                    <Form.Label>Catatan Verifikasi</Form.Label>
                                    <Form.Control
                                        as="textarea"
                                        rows={modalMode === "create" ? 2 : 4}
                                        name="catatan_verifikasi"
                                        value={form.catatan_verifikasi}
                                        onChange={handleFormChange}
                                        placeholder="Tuliskan alasan approve / reject (opsional)"
                                    />
                                </Form.Group>
                            </div>
                        </div>
                    </Modal.Body>

                    <Modal.Footer>
                        <Button variant="secondary" onClick={closeModal}>
                            Tutup
                        </Button>
                        <Button type="submit" variant="primary" disabled={saving}>
                            {saving
                                ? "Menyimpan..."
                                : modalMode === "create"
                                    ? "Tambah User"
                                    : "Simpan Perubahan"}
                        </Button>
                    </Modal.Footer>
                </Form>
            </Modal>
        </AdminLayout>
    );
};

export default AdminUsersPage;
