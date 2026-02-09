import apiClient from "./apiClient";

export const fetchPanicAlerts = async (params) => {
    const res = await apiClient.get("/admin/panic-alert", { params });
    return res.data; // { success, data, page, limit }
};

export const fetchPanicAlertDetail = async (id) => {
    const res = await apiClient.get(`/admin/panic-alert/${id}`);
    return res.data; // { success, data: { panic, dispatchTargets } }
};
