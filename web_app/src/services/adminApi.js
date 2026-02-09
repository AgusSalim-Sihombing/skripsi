import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

export const adminApi = axios.create({
    baseURL: API_BASE_URL,
});

adminApi.interceptors.request.use((config) => {
    const token = localStorage.getItem("sigap_admin_token");
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
});

// ===== LAPORAN KEPOLISIAN =====
export const getAdminLaporanKepolisianList = async (params) => {
    const res = await adminApi.get("/admin/laporan-kepolisian", { params });
    return res.data;
};

export const getAdminLaporanKepolisianDetail = async (id) => {
    const res = await adminApi.get(`/admin/laporan-kepolisian/${id}`);
    return res.data;
};

export const patchAdminLaporanKepolisianStatus = async (id, payload) => {
    const res = await adminApi.patch(`/admin/laporan-kepolisian/${id}/status`, payload);
    return res.data;
};
