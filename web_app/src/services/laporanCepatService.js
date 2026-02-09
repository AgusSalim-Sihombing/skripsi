// // src/services/laporanCepatService.js
// import axios from "axios";

// const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

// const getAuthHeader = () => {
//     const token = localStorage.getItem("sigap_admin_token");
//     return token ? { Authorization: `Bearer ${token}` } : {};
// };

// export const getAdminLaporanList = async (params = {}) => {
//     // ⬅️ PENTING: pastikan ada "laporan-cepat" di sini
//     const res = await axios.get(
//         `${API_BASE_URL}/admin/laporan-cepat`,
//         {
//             params,
//             headers: getAuthHeader(),
//         }
//     );
//     return res.data;
// };

// export const getAdminLaporanDetail = async (id) => {
//     const res = await axios.get(
//         `${API_BASE_URL}/admin/laporan-cepat/${id}`,
//         {
//             headers: getAuthHeader(),
//         }
//     );
//     return res.data;
// };

// export const getLaporanForZona = async () => {
//     const res = await axios.get(
//         `${API_BASE_URL}/api/admin/laporan-cepat/for-zona`,
//         {
//             headers: getAuthHeader(),
//         }
//     );
//     return res.data;
// };

// export const approveLaporan = async (id) => {
//     const res = await axios.post(
//         `${API_BASE_URL}/api/admin/laporan-cepat/${id}/approve`,
//         {},
//         { headers: getAuthHeader() }
//     );
//     return res.data;
// };

// export const rejectLaporan = async (id) => {
//     const res = await axios.post(
//         `${API_BASE_URL}/api/admin/laporan-cepat/${id}/reject`,
//         {},
//         { headers: getAuthHeader() }
//     );
//     return res.data;
// };

// export const getLaporanCepatLocations = async () => {
//     const res = await axios.get(
//         `${API_BASE_URL}/api/admin/laporan-cepat`,
//         {
//             headers: getAuthHeader(),
//             params: { status: "approved" }, // boleh diganti kalau mau
//         }
//     );
//     return res.data;
// };

// src/services/laporanCepatService.js
import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const getAuthHeader = () => {
    const token = localStorage.getItem("sigap_admin_token");
    return token ? { Authorization: `Bearer ${token}` } : {};
};

// LIST laporan untuk tabel admin
export const getAdminLaporanList = async (params = {}) => {
    const res = await axios.get(
        `${API_BASE_URL}/admin/laporan-cepat`,
        {
            params,
            headers: getAuthHeader(),
        }
    );
    return res.data;
};

// DETAIL laporan (dipakai di halaman detail + voting)
export const getAdminLaporanDetail = async (id) => {
    const res = await axios.get(
        `${API_BASE_URL}/admin/laporan-cepat/${id}`,
        {
            headers: getAuthHeader(),
        }
    );
    return res.data;
};

// Dropdown "laporan sumber" di halaman Zona Bahaya
export const getLaporanForZona = async () => {
    const res = await axios.get(
        `${API_BASE_URL}/admin/laporan-cepat/for-zona`,
        {
            headers: getAuthHeader(),
        }
    );
    return res.data;
};

// APPROVE laporan
export const approveLaporan = async (id) => {
    const res = await axios.post(
        `${API_BASE_URL}/admin/laporan-cepat/${id}/approve`,
        {},
        { headers: getAuthHeader() }
    );
    return res.data;
};

// REJECT laporan
export const rejectLaporan = async (id) => {
    const res = await axios.post(
        `${API_BASE_URL}/admin/laporan-cepat/${id}/reject`,
        {},
        { headers: getAuthHeader() }
    );
    return res.data;
};

// Peta laporan cepat (kalau butuh semua titik approved)
export const getLaporanCepatLocations = async () => {
    const res = await axios.get(
        `${API_BASE_URL}/admin/laporan-cepat`,
        {
            headers: getAuthHeader(),
            params: { status: "approved" },
        }
    );
    return res.data;
};
