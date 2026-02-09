// src/services/communityAdminService.js
import apiClient from "./apiClient";

// LIST komunitas
export const fetchAdminCommunities = async (params) => {
    const res = await apiClient.get("/admin/communities", { params });
    return res.data; // { page, limit, data: [] }
};

// LIST chat komunitas
export const fetchAdminCommunityMessages = async (communityId, params) => {
    const res = await apiClient.get(`/admin/communities/${communityId}/messages`, { params });
    return res.data; // { page, limit, data: [] }
};

// TAKEDOWN
export const takedownCommunity = async (communityId, reason) => {
    const res = await apiClient.patch(`/admin/communities/${communityId}/takedown`, { reason });
    return res.data;
};

// RESTORE
export const restoreCommunity = async (communityId) => {
    const res = await apiClient.patch(`/admin/communities/${communityId}/restore`);
    return res.data;
};

// DELETE MESSAGE (soft delete)
export const deleteCommunityMessage = async (messageId, reason) => {
    const res = await apiClient.patch(`/admin/messages/${messageId}/delete`, { reason });
    return res.data;
};

export const fetchAdminCommunityDetail = async (communityId) => {
    const res = await apiClient.get(`/admin/communities/${communityId}`);
    return res.data; // { data: {...} }
};
