// src/modules/public/components/organisms/PublicNavbar/PublicNavbar.jsx
import React from "react";
import { Link } from "react-router-dom";
import "../../pages/HomePublicPage.css";
import "../../pages/HomePublicPage.css"
const PublicNavbar = () => {
    const scrollToSection = (id) => {
        const el = document.getElementById(id);
        if (el) {
            el.scrollIntoView({ behavior: "smooth", block: "start" });
        }
    };

    return (
        <header className="public-navbar">
            <div className="public-navbar__inner">
                <div className="public-navbar__brand">
                    <a href="/" className="public-navbar__brand-link">
                        <span className="public-navbar__brand-dot"></span>
                        <span className="logo-text">SIGAP</span>
                    </a>
                </div>

                <nav className="public-navbar__nav" style={{
                    backgroundColor: " rgba(80, 80, 80, 0.08)"
                }}>
                    <button onClick={() => scrollToSection("aplikasi-sigap")} className="nav-link">
                        Aplikasi SIGAP
                    </button>
                    <button onClick={() => scrollToSection("tentang")} className="nav-link">
                        Tentang
                    </button>
                    <button onClick={() => scrollToSection("panduan")} className="nav-link">
                        Panduan Aplikasi
                    </button>
                    <button onClick={() => scrollToSection("kontak")} className="nav-link">
                        Info Kontak & Tautan
                    </button>
                </nav>

                <div className="public-navbar__actions">
                    <Link to="/login-admin" className="public-navbar__login-btn">
                        Login Admin
                    </Link>
                </div>
            </div>
        </header>
    );
};

export default PublicNavbar;