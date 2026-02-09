import apiClient from "./apiClient";

export const getDashboardSummary = async () => {
    const res = await apiClient.get("/admin/dashboard/summary");
    return res.data; // { success, data: { ... } }
};
