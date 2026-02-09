import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FiSearch, FiRefreshCw, FiChevronLeft, FiChevronRight } from "react-icons/fi";
import {
    getAdminLaporanKepolisianList,
} from "../../../../../services/adminApi";
import "./laporanKepolisianAdmin.css";
import AdminLayout from "../../../../shared/layout/AdminLayout";

const STATUS_OPTIONS = [
    { value: "", label: "Semua Status" },
    { value: "pending", label: "pending" },
    { value: "on_process", label: "on_process" },
    { value: "selesai", label: "selesai" },
    { value: "dibatalkan", label: "dibatalkan" },
];

const fmt = (v) => {
    if (!v) return "-";
    try {
        return new Date(v).toLocaleString("id-ID");
    } catch {
        return v;
    }
};

const StatusBadge = ({ status }) => {
    const cls =
        status === "pending"
            ? "badge badge--pending"
            : status === "on_process"
                ? "badge badge--process"
                : status === "selesai"
                    ? "badge badge--done"
                    : status === "dibatalkan"
                        ? "badge badge--cancel"
                        : "badge";

    return <span className={cls}>{status || "-"}</span>;
};

export default function AdminLaporanKepolisianListPage() {
    const nav = useNavigate();

    const [status, setStatus] = useState("");
    const [search, setSearch] = useState("");
    const [q, setQ] = useState("");

    const [page, setPage] = useState(1);
    const limit = 20;

    const [loading, setLoading] = useState(false);
    const [rows, setRows] = useState([]);

    const canPrev = page > 1;
    const canNext = rows.length >= limit; // simple paging (tanpa total)

    const params = useMemo(() => {
        const p = { page, limit };
        if (status) p.status = status;
        if (q) p.search = q;
        return p;
    }, [page, limit, status, q]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const data = await getAdminLaporanKepolisianList(params);

            // backend kamu return { data: rows, page, limit }
            const list = data?.data ?? data ?? [];
            setRows(Array.isArray(list) ? list : []);
        } catch (e) {
            console.error(e);
            setRows([]);
            alert(e?.response?.data?.message || "Gagal ambil laporan kepolisian");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
        // eslint-disable-next-line
    }, [params]);

    return (
        <AdminLayout>
            <div className="lk-admin" style={{color:"black"}}>
                <div className="lk-admin__header">
                    <div>
                        <h2 className="lk-admin__title">Laporan Kepolisian</h2>
                        <p className="lk-admin__subtitle">
                            Lihat semua laporan + officer yang menerima.
                        </p>
                    </div>

                    <button
                        className="lk-btn lk-btn--ghost"
                        onClick={fetchData}
                        disabled={loading}
                        title="Refresh"
                    >
                        <FiRefreshCw />
                        Refresh
                    </button>
                </div>

                <div className="lk-admin__toolbar" style={{color:"black"}}>
                    <select 
                        className="lk-input"
                        value={status}
                        onChange={(e) => {
                            setPage(1);
                            setStatus(e.target.value);
                        }}
                        style={{color:"black"}}
                    >
                        {STATUS_OPTIONS.map((o) => (
                            <option key={o.value} value={o.value} style={{color:"black"}}>
                                {o.label}
                            </option>
                        ))}
                    </select>

                    <div className="lk-search">
                        <FiSearch className="lk-search__icon" />
                        <input
                            className="lk-input lk-search__input"
                            placeholder="Cari pelapor / officer / tindak pidana / kota..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            onKeyDown={(e) => {
                                if (e.key === "Enter") {
                                    setPage(1);
                                    setQ(search.trim());
                                }
                            }}
                        />
                        <button
                            className="lk-btn"
                            onClick={() => {
                                setPage(1);
                                setQ(search.trim());
                            }}
                            disabled={loading}
                        >
                            Cari
                        </button>
                    </div>
                </div>

                <div className="lk-card">
                    <div className="lk-tableWrap">
                        <table className="lk-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Status</th>
                                    <th>Tindak Pidana</th>
                                    <th>Kab/Kota</th>
                                    <th>Pelapor</th>
                                    <th>Officer</th>
                                    <th>Dibuat</th>
                                    <th>Responded</th>
                                    <th>Selesai</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>

                            <tbody>
                                {loading ? (
                                    <tr>
                                        <td colSpan={10} className="lk-empty">
                                            Loading...
                                        </td>
                                    </tr>
                                ) : rows.length === 0 ? (
                                    <tr>
                                        <td colSpan={10} className="lk-empty">
                                            Data kosong.
                                        </td>
                                    </tr>
                                ) : (
                                    rows.map((r) => (
                                        <tr key={r.id}>
                                            <td className="lk-mono">#{r.id}</td>
                                            <td>
                                                <StatusBadge status={r.status} />
                                            </td>
                                            <td>{r.tindak_pidana || "-"}</td>
                                            <td>{r.tempat_kab_kota || "-"}</td>
                                            <td>
                                                <div className="lk-person">
                                                    <div className="lk-person__name">{r.pelapor_nama || "-"}</div>
                                                    <div className="lk-person__meta">@{r.pelapor_username || "-"}</div>
                                                </div>
                                            </td>
                                            <td>
                                                {r.officer_id ? (
                                                    <div className="lk-person">
                                                        <div className="lk-person__name">{r.officer_nama}</div>
                                                        <div className="lk-person__meta">@{r.officer_username}</div>
                                                    </div>
                                                ) : (
                                                    <span className="lk-muted">Belum ada</span>
                                                )}
                                            </td>
                                            <td>{fmt(r.created_at)}</td>
                                            <td>{fmt(r.responded_at)}</td>
                                            <td>{fmt(r.completed_at)}</td>
                                            <td>
                                                <button
                                                    className="lk-btn lk-btn--sm"
                                                    onClick={() => nav(`/admin/laporan-kepolisian/${r.id}`)}
                                                >
                                                    Detail
                                                </button>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>

                    <div className="lk-pagination">
                        <button
                            className="lk-btn lk-btn--ghost"
                            disabled={!canPrev || loading}
                            onClick={() => setPage((p) => Math.max(1, p - 1))}
                        >
                            <FiChevronLeft /> Prev
                        </button>

                        <div className="lk-pagination__info">
                            Page <b>{page}</b>
                        </div>

                        <button
                            className="lk-btn lk-btn--ghost"
                            disabled={!canNext || loading}
                            onClick={() => setPage((p) => p + 1)}
                        >
                            Next <FiChevronRight />
                        </button>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
