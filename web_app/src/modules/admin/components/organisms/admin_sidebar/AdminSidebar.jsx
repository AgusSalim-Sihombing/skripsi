// src/modules/admin/components/organisms/AdminSidebar/AdminSidebar.jsx
import { NavLink, useNavigate } from "react-router-dom";
import {
    FiHome,
    FiUsers,
    FiUserCheck,
    FiFileText,
    FiAlertTriangle,
    FiShield,
    FiBarChart2,
    FiMessageSquare,
    FiPower,
} from "react-icons/fi";

const menuItems = [
    { label: "Beranda", path: "/admin/dashboard", icon: FiHome },
    { label: "Data Pengguna", path: "/admin/users", icon: FiUsers },
    { label: "Data Officer", path: "/admin/officers", icon: FiUserCheck },
    { label: "Laporan Cepat", path: "/admin/laporan-cepat", icon: FiFileText },
    { label: "Laporan Kepolisian", path: "/admin/laporan-kepolisian", icon: FiFileText },
    { label: "Zona Bahaya", path: "/admin/zona-bahaya", icon: FiAlertTriangle },
    { label: "Panic Alert", path: "/admin/panic-alert", icon: FiShield },
    { label: "Komunitas", path: "/admin/komunitas", icon: FiMessageSquare },
];

const AdminSidebar = () => {
    const navigate = useNavigate();

    const handleLogout = () => {
        localStorage.removeItem("sigap_admin_token");
        localStorage.removeItem("sigap_admin_info");
        navigate("/login-admin");
    };

    return (
        <aside className="admin-sidebar">
            <div className="admin-sidebar__logo">
                <span className="admin-sidebar__logo-mark">S</span>
                <div className="admin-sidebar__logo-text">
                    <span className="title">SIGAP</span>
                    <span className="subtitle">Dashboard Admin</span>
                </div>
            </div>

            <nav className="admin-sidebar__nav">
                {menuItems.map((item) => {
                    const Icon = item.icon;
                    return (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            className={({ isActive }) =>
                                "admin-sidebar__item" +
                                (isActive ? " admin-sidebar__item--active" : "")
                            }
                        >
                            <Icon className="admin-sidebar__icon" />
                            <span>{item.label}</span>
                        </NavLink>
                    );
                })}
            </nav>

            <button
                type="button"
                className="admin-sidebar__item admin-sidebar__item--logout"
                onClick={handleLogout}
            >
                <FiPower className="admin-sidebar__icon" />
                <span>Logout</span>
            </button>
        </aside>
    );
};

export default AdminSidebar;
