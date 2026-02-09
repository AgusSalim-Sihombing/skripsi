// src/routes/publicRoutes.jsx
import React from "react";
import { Routes, Route } from "react-router-dom";
import HomePublicPage from "../modules/public/components/pages/HomePublicPage";
// import AdminLoginPage from "../modules/public/components/pages/AdminLoginPage"; // nanti

const PublicRoutes = () => {
    return (
        <Routes>
            <Route path="/" element={<HomePublicPage />} />
            {/* <Route path="/login-admin" element={<AdminLoginPage />} /> */}
        </Routes>
    );
};

export default PublicRoutes;
