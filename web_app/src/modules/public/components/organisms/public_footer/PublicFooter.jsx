// src/modules/public/components/organisms/PublicFooter/PublicFooter.jsx
import React from "react";

const PublicFooter = () => {
    return (
        <footer className="public-footer">
            <div className="public-footer__inner">
                <p>© {new Date().getFullYear()} SIGAP - Sistem Informasi Geospasial Anti Kejahatan.</p>
                <p>Pengembangan: M. Agus Salim - Septian Jedidja Hutagalung - Dinda Putri Sinaga</p>
            </div>
        </footer>
    );
};

export default PublicFooter;
