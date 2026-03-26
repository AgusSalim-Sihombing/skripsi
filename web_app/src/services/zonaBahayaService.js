import apiClient from "./apiClient";

export const fetchZonaBahaya = async () => {
    const res = await apiClient.get("/admin/zona-bahaya");
    return res.data;
};

export const fetchZonaBahayaDetail = async (id) => {
    const res = await apiClient.get(`/admin/zona-bahaya/${id}`);
    return res.data;
};

export const fetchZonaBahayaVoteSummary = async (id) => {
    const res = await apiClient.get(`/admin/zona-bahaya/${id}/votes-summary`);
    return res.data;
};

export const fetchZonaBahayaVotes = async (id) => {
    const res = await apiClient.get(`/admin/zona-bahaya/${id}/votes`);
    return res.data;
};

export const updateZonaBahayaStatus = async (id, payload) => {
    const res = await apiClient.put(`/admin/zona-bahaya/${id}/status`, payload);
    return res.data;
};

export const createZonaBahaya = async (payload) => {
    const res = await apiClient.post("/admin/zona-bahaya", payload);
    return res.data;
};

export const updateZonaBahaya = async (id, payload) => {
    const res = await apiClient.put(`/admin/zona-bahaya/${id}`, payload);
    return res.data;
};

export const deleteZonaBahaya = async (id) => {
    const res = await apiClient.delete(`/admin/zona-bahaya/${id}`);
    return res.data;
};