// src/modules/shared/layouts/PublicLayout.jsx
import React from "react";
import PublicNavbar from "../../public/components/organisms/public_navbar/PublicNavbar";
import PublicFooter from "../../public/components/organisms/public_footer/PublicFooter";


const PublicLayout = ({ children }) => {
  return (
    <div className="public-layout">
      <PublicNavbar />
      <main className="public-main">{children}</main>
      <PublicFooter />
    </div>
  );
};

export default PublicLayout;
