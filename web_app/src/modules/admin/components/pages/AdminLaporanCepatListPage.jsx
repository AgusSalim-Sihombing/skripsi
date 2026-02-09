// src/features/admin/pages/laporan-cepat/AdminLaporanCepatListPage.jsx

import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import AdminLayout from "../../../shared/layout/AdminLayout";
import { getAdminLaporanList } from "../../../../services/laporanCepatService";

const AdminLaporanCepatListPage = () => {
    const navigate = useNavigate();

    const [list, setList] = useState([]);
    const [loading, setLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");

    const [filters, setFilters] = useState({
        search: "",
        status: "",
        tanggal_from: "",
        tanggal_to: "",
    });

    const loadData = async () => {
        try {
            setLoading(true);
            setErrorMsg("");
            const res = await getAdminLaporanList(filters);
            if (res.success) {
                setList(res.data || []);
            } else {
                setErrorMsg(res.message || "Gagal memuat laporan");
            }
        } catch (err) {
            console.error("getAdminLaporanList error:", err);
            setErrorMsg("Terjadi kesalahan saat memuat data laporan");
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
        loadData();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const handleFilterChange = (e) => {
        const { name, value } = e.target;
        setFilters((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const applyFilter = (e) => {
        e.preventDefault();
        loadData();
    };

    const handleReset = () => {
        setFilters({
            search: "",
            status: "",
            tanggal_from: "",
            tanggal_to: "",
        });
        loadData();
    };

    return (
        <AdminLayout>
            <div className="laporan-cepat-page">
                {/* HEADER */}
                <div className="dashboard-header">
                    <h1>Laporan Cepat</h1>
                    <p>
                        Daftar laporan cepat yang dikirim oleh pengguna aplikasi SIGAP.
                        Gunakan filter untuk mempermudah proses review.
                    </p>
                </div>

                {/* FILTER CARD */}
                <section className="card card--filter">
                    <h2 className="section-title">Filter Laporan</h2>

                    <form onSubmit={applyFilter} className="filter-form">
                        <div className="form-group">
                            <label htmlFor="search">Cari Judul / Deskripsi</label>
                            <input
                                id="search"
                                type="text"
                                name="search"
                                value={filters.search}
                                onChange={handleFilterChange}
                                placeholder="Contoh: Tawuran pelajar di jembatan..."
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="status">Status Validasi</label>
                            <select
                                id="status"
                                name="status"
                                value={filters.status}
                                onChange={handleFilterChange}
                            >
                                <option value="">Semua</option>
                                <option value="pending">Pending</option>
                                <option value="review">Review</option>
                                <option value="approved">Approved</option>
                                <option value="rejected">Rejected</option>
                            </select>
                        </div>

                        <div className="form-row">
                            <div className="form-group">
                                <label htmlFor="tanggal_from">Dari Tanggal</label>
                                <input
                                    id="tanggal_from"
                                    type="date"
                                    name="tanggal_from"
                                    value={filters.tanggal_from}
                                    onChange={handleFilterChange}
                                />
                            </div>
                            <div className="form-group">
                                <label htmlFor="tanggal_to">Sampai Tanggal</label>
                                <input
                                    id="tanggal_to"
                                    type="date"
                                    name="tanggal_to"
                                    value={filters.tanggal_to}
                                    onChange={handleFilterChange}
                                />
                            </div>
                        </div>

                        <div className="filter-actions">
                            <button type="submit" className="btn btn-primary">
                                Terapkan Filter
                            </button>
                            <button
                                type="button"
                                className="btn btn-outline"
                                onClick={handleReset}
                            >
                                Reset
                            </button>
                        </div>
                    </form>
                </section>

                {/* ERROR MESSAGE */}
                {errorMsg && <div className="alert alert--error">{errorMsg}</div>}

                {/* TABLE CARD */}
                <section className="card card--table">
                    <div className="table-header">
                        <h2 className="section-title">Daftar Laporan</h2>
                        <p className="section-subtitle">
                            Klik tombol <b>Detail</b> pada salah satu laporan untuk melihat
                            foto, data pelapor, dan hasil voting.
                        </p>
                    </div>

                    {loading ? (
                        <p>Memuat data laporan...</p>
                    ) : list.length === 0 ? (
                        <div className="empty-state">
                            <p>
                                Belum ada laporan cepat yang masuk atau tidak ditemukan sesuai
                                filter.
                            </p>
                        </div>
                    ) : (
                        <div className="table-wrapper">
                            <table className="zona-table">
                                <thead>
                                    <tr>
                                        <th>Judul Laporan</th>
                                        <th>Tanggal</th>
                                        <th>Waktu</th>
                                        <th>Koordinat</th>
                                        <th>Status</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {list.map((lap) => (
                                        <tr key={lap.id_laporan}>
                                            <td>{lap.judul_laporan}</td>
                                            <td>{lap.tanggal_kejadian}</td>
                                            <td>{lap.waktu_kejadian?.slice(0, 5)}</td>
                                            <td>
                                                {Number(lap.latitude).toFixed(5)},{" "}
                                                {Number(lap.longitude).toFixed(5)}
                                            </td>
                                            <td style={{ textTransform: "capitalize" }}>
                                                {lap.status_validasi}
                                            </td>
                                            <td>
                                                <button
                                                    type="button"
                                                    className="btn btn-outline"
                                                    style={{
                                                        padding: "0.25rem 0.6rem",
                                                        fontSize: "0.8rem",
                                                    }}
                                                    onClick={() =>
                                                        navigate(
                                                            `/admin/laporan-cepat/${lap.id_laporan}`
                                                        )
                                                    }
                                                >
                                                    Detail
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </section>
            </div>
        </AdminLayout>
    );
};

export default AdminLaporanCepatListPage;
