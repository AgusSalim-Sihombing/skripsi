import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_REACT_APP_API_BASE_URL;
// contoh di .env: VITE_REACT_APP_API_BASE_URL="http://localhost:5000/api"

export const loginAdmin = async ({ username, password }) => {
    const response = await axios.post(`${API_BASE_URL}/admin/login`, {
        username,
        password,
    });
    return response.data; // { success, message, data: { token, admin } }
};
