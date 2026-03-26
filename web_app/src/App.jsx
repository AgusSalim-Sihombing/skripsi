// src/App.jsx
import React from "react";
import "leaflet/dist/leaflet.css";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import HomePublicPage from "./modules/public/components/pages/HomePublicPage";
import "../src/assets/style/public.css";
import "../src/assets/style/admin.css";
// import AdminLoginPage from "./modules/public/components/pages/AdminLoginPage";
// import AdminDashboardPage from "./modules/admin/components/pages/DashboardPage";
import AdminDashboardPage from "./modules/admin/components/pages//AdminDashboardPages";
import AdminLoginPage from "./modules/public/components/pages/AdminLoginPage";
// import AdminLaporanCepatMapPage from "./modules/admin/components/pages/AdminLaporanCepatMapPage";
// import AdminLaporanCepatDetailPage from "./modules/admin/components/pages/AdminLaporanCepatMapDetailPage";
import ZonaBahayaPage from "./modules/admin/components/pages/ZonaBahayaPage";
import ZonaBahayaListPage from "./modules/admin/components/pages/ZonaBahayaListPage";
import AdminLaporanCepatListPage from "./modules/admin/components/pages/admin_laporan_cepat/AdminLaporanCepatListPage";
import AdminLaporanCepatDetailPage from "./modules/admin/components/pages/admin_laporan_cepat/AdminLaporanCepatDetailPage";
import AdminUserMasyarakatPage from "./modules/admin/components/pages/admin_user/AdminUserMasyarakatPage";
import AdminOfficerPage from "./modules/admin/components/pages/admin_user/AdminOfficerPage";
import AdminUserDetailPage from "./modules/admin/components/pages/admin_user/AdminUserDetailPage";
import AdminLaporanKepolisianListPage from "./modules/admin/components/pages/laporan_kepolisian/AdminLaporanKepolisianListPage";
import AdminLaporanKepolisianDetailPage from "./modules/admin/components/pages/laporan_kepolisian/AdminLaporanKepolisianDetailPage";
import "leaflet/dist/leaflet.css";
import AdminPanicAlertListPage from "./modules/admin/components/pages/panic_alert/AdminPanicAlertListPage";
import AdminPanicAlertDetailPage from "./modules/admin/components/pages/panic_alert/AdminPanicAlertDetailPage";
import AdminKomunitasListPage from "./modules/admin/components/pages/admin_komunitas/admin_komunitas_list_page";
import AdminKomunitasDetailPage from "./modules/admin/components/pages/admin_komunitas/admin_komunitas_detail_page";
import ZonaBahayaDetailPage from "./modules/admin/components/pages/ZonaBahayaDetailPage";





function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public */}
        <Route path="/" element={<HomePublicPage />} />
        <Route path="/login-admin" element={<AdminLoginPage />} />

        {/* ADMIN */}
        <Route path="/admin/users" element={<AdminUserMasyarakatPage />} />
        <Route path="/admin/officers" element={<AdminOfficerPage />} />
        <Route path="/admin/users/:id" element={<AdminUserDetailPage />} />
        <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
        <Route path="/admin/zona-bahaya" element={<ZonaBahayaPage />} />
        {/* <Route path="/admin/laporan-cepat/map" element={<AdminLaporanCepatMapPage />} />
        <Route path="/admin/laporan-cepat/:id" element={<AdminLaporanCepatDetailPage />} /> */}
        <Route path="/admin/zona-bahaya/semua" element={<ZonaBahayaListPage />} />
        <Route path="/admin/zona-bahaya/semua/:id" element={<ZonaBahayaDetailPage />} />
        <Route path="/admin/laporan-kepolisian" element={<AdminLaporanKepolisianListPage />} />
        <Route path="/admin/laporan-kepolisian/:id" element={<AdminLaporanKepolisianDetailPage />} />

        <Route path="/admin/panic-alert" element={<AdminPanicAlertListPage />} />
        <Route path="/admin/panic-alert/:id" element={<AdminPanicAlertDetailPage />} />

        <Route path="/admin/komunitas" element={<AdminKomunitasListPage />} />
        <Route path="/admin/komunitas/:id" element={<AdminKomunitasDetailPage />} />

        <Route path="/admin/laporan-cepat" element={<AdminLaporanCepatListPage />} />
        <Route
          path="/admin/laporan-cepat/:id"
          element={<AdminLaporanCepatDetailPage />}
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
