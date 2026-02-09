// src/modules/admin/components/layouts/AdminLayout.jsx
import React from "react";
import AdminSidebar from "../../admin/components/organisms/admin_sidebar/AdminSidebar";

const AdminLayout = ({ children }) => {
    return (
        <div className="admin-layout">
            <AdminSidebar />
            <main className="admin-layout__content">{children}</main>
        </div>
    );
};

export default AdminLayout;
