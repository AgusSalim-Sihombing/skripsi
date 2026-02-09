import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;

const apiClient = axios.create({
    baseURL: API_BASE_URL,
});

// interceptor: otomatis tambahin Bearer token
apiClient.interceptors.request.use((config) => {
    const token = localStorage.getItem("sigap_admin_token");
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
}); 

export default apiClient;
