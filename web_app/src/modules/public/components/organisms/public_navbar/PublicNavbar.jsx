// src/modules/public/components/organisms/PublicNavbar/PublicNavbar.jsx
import React from "react";
import { Link } from "react-router-dom";

const PublicNavbar = () => {
    const scrollToSection = (id) => {
        const el = document.getElementById(id);
        if (el) {
            el.scrollIntoView({ behavior: "smooth" });
        }
    };

    return (
        <header className="public-navbar">
            <div className="public-navbar__inner">
                <div className="public-navbar__brand" onClick={() => scrollToSection("aplikasi-sigap")}>
                    <span className="logo-text">SIGAP</span>
                </div>

                <nav className="public-navbar__nav">
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
                    {/* Tombol menuju halaman login admin */}
                    <Link to="/login-admin" className="btn btn-primary">
                        Login Admin
                    </Link>
                </div>
            </div>
        </header>
    );
};

export default PublicNavbar;
