// src/services/adminUserService.js
import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const getAuthHeader = () => {
    const token = localStorage.getItem("sigap_admin_token");
    return token ? { Authorization: `Bearer ${token}` } : {};
};

export const getAdminUsers = async (params = {}) => {
    const res = await axios.get(`${API_BASE_URL}/admin/users`, {
        params,
        headers: getAuthHeader(),
    });
    return res.data;
};

export const getAdminUserDetail = async (id) => {
    const res = await axios.get(`${API_BASE_URL}/admin/users/${id}`, {
        headers: getAuthHeader(),
    });
    return res.data;
};

export const createAdminUser = async (payload) => {
    const res = await axios.post(`${API_BASE_URL}/admin/users`, payload, {
        headers: {
            ...getAuthHeader(),
            "Content-Type": "application/json",
        },
    });
    return res.data;
};

export const updateAdminUser = async (id, payload) => {
    const res = await axios.put(`${API_BASE_URL}/admin/users/${id}`, payload, {
        headers: {
            ...getAuthHeader(),
            "Content-Type": "application/json",
        },
    });
    return res.data;
};

export const deleteAdminUser = async (id) => {
    const res = await axios.delete(`${API_BASE_URL}/admin/users/${id}`, {
        headers: getAuthHeader(),
    });
    return res.data;
};
