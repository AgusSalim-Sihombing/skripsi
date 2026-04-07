// import React, { useState } from "react";
// import { useNavigate } from "react-router-dom";
// import PublicLayout from "../../../shared/layout/PublicLayout";
// import { loginAdmin } from "../../../../services/authService";

// const AdminLoginPage = () => {
//     const navigate = useNavigate();
//     const [form, setForm] = useState({ username: "", password: "" });
//     const [loading, setLoading] = useState(false);
//     const [errorMsg, setErrorMsg] = useState("");
//     const [successMsg, setSuccessMsg] = useState("");

//     const handleChange = (e) => {
//         setForm((prev) => ({
//             ...prev,
//             [e.target.name]: e.target.value,
//         }));
//     };

//     const handleSubmit = async (e) => {
//         e.preventDefault();
//         setErrorMsg("");
//         setSuccessMsg("");
//         setLoading(true);

//         try {
//             const res = await loginAdmin(form);

//             if (!res.success) {
//                 setErrorMsg(res.message || "Login gagal");
//             } else {
//                 // simpan token & info admin
//                 localStorage.setItem("sigap_admin_token", res.data.token);
//                 localStorage.setItem(
//                     "sigap_admin_info",
//                     JSON.stringify(res.data.admin)
//                 );

//                 // tampilkan pesan sukses dulu
//                 setSuccessMsg("Login berhasil! Mengalihkan ke dashboard...");

//                 // delay 3 detik sebelum pindah halaman
//                 setTimeout(() => {
//                     navigate("/admin/dashboard");
//                 }, 3000);
//             }
//         } catch (err) {
//             console.error("Login error:", err);
//             setErrorMsg(
//                 err?.response?.data?.message || "Terjadi kesalahan pada server saat login"
//             );
//         } finally {
//             setLoading(false);
//         }
//     };

//     return (
//         <PublicLayout>
//             <section className="section section--login-admin">
//                 <div className="section__inner section__inner--login">
//                     <div className="login-card">
//                         <h2>Login Admin SIGAP</h2>
//                         <p className="login-subtitle">
//                             Masuk untuk mengelola laporan kejadian, lokasi rawan, dan aktivitas
//                             pengguna aplikasi SIGAP.
//                         </p>

//                         {errorMsg && <div className="login-error">{errorMsg}</div>}
//                         {successMsg && <div className="login-success">{successMsg}</div>}

//                         <form onSubmit={handleSubmit} className="login-form">
//                             <div className="form-group">
//                                 <label htmlFor="username">Username</label>
//                                 <input
//                                     id="username"
//                                     name="username"
//                                     type="text"
//                                     value={form.username}
//                                     onChange={handleChange}
//                                     placeholder="Masukkan username admin"
//                                     required
//                                 />
//                             </div>

//                             <div className="form-group">
//                                 <label htmlFor="password">Kata Sandi</label>
//                                 <input
//                                     id="password"
//                                     name="password"
//                                     type="password"
//                                     value={form.password}
//                                     onChange={handleChange}
//                                     placeholder="Masukkan kata sandi"
//                                     required
//                                 />
//                             </div>

//                             <button type="submit" className="btn btn-primary" disabled={loading || !!successMsg}>
//                                 {loading
//                                     ? "Memproses..."
//                                     : successMsg
//                                         ? "Berhasil"
//                                         : "Login"}
//                             </button>
//                         </form>
//                     </div>
//                 </div>
//             </section>
//         </PublicLayout>
//     );
// };

// export default AdminLoginPage;

import React, { useEffect, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { loginAdmin } from "../../../../services/authService";

const AdminLoginPage = () => {
    const navigate = useNavigate();
    const redirectRef = useRef(null);

    const [form, setForm] = useState({
        username: "",
        password: "",
    });

    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    useEffect(() => {
        return () => {
            if (redirectRef.current) {
                clearTimeout(redirectRef.current);
            }
        };
    }, []);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        setErrorMsg("");
        setSuccessMsg("");
        setLoading(true);

        try {
            const res = await loginAdmin(form);

            if (!res.success) {
                setErrorMsg(res.message || "Login gagal");
                return;
            }

            localStorage.setItem("sigap_admin_token", res.data.token);
            localStorage.setItem(
                "sigap_admin_info",
                JSON.stringify(res.data.admin)
            );

            setSuccessMsg("Login berhasil! Mengalihkan ke dashboard...");

            redirectRef.current = setTimeout(() => {
                navigate("/admin/dashboard");
            }, 1800);
        } catch (err) {
            console.error("Login error:", err);
            setErrorMsg(
                err?.response?.data?.message ||
                "Terjadi kesalahan pada server saat login"
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="admin-login-page">
            <div className="admin-login-overlay" />

            <div className="admin-login-shell">
                <div className="admin-login-left">
                    {/* <div className="admin-login-badge">Admin Panel SIGAP</div> */}

                    <h1>Masuk ke Dashboard Admin</h1>
                    <p>
                        Kelola laporan kejadian, zona bahaya, data pengguna, dan
                        aktivitas sistem SIGAP dari satu dashboard terpusat.
                    </p>

                    <div className="admin-login-points">
                        <div className="admin-login-point">
                            <span className="admin-login-point__dot" />
                            <span>Monitoring laporan dan verifikasi data</span>
                        </div>
                        <div className="admin-login-point">
                            <span className="admin-login-point__dot" />
                            <span>Pengelolaan zona rawan kejahatan</span>
                        </div>
                        <div className="admin-login-point">
                            <span className="admin-login-point__dot" />
                            <span>Kontrol akses dan aktivitas pengguna</span>
                        </div>
                    </div>
                </div>

                <div className="admin-login-card">
                    <div className="admin-login-card__header">
                        <h2>Login Admin</h2>
                        <p>Masukkan akun admin untuk melanjutkan.</p>
                    </div>

                    {errorMsg && <div className="admin-login-alert admin-login-alert--error">{errorMsg}</div>}
                    {successMsg && <div className="admin-login-alert admin-login-alert--success">{successMsg}</div>}

                    <form onSubmit={handleSubmit} className="admin-login-form">
                        <div className="admin-login-form__group">
                            <label htmlFor="username">Username</label>
                            <input
                                id="username"
                                name="username"
                                type="text"
                                value={form.username}
                                onChange={handleChange}
                                placeholder="Masukkan username admin"
                                autoComplete="username"
                                required
                            />
                        </div>

                        <div className="admin-login-form__group">
                            <label htmlFor="password">Kata Sandi</label>
                            <div className="admin-login-password">
                                <input
                                    id="password"
                                    name="password"
                                    type={showPassword ? "text" : "password"}
                                    value={form.password}
                                    onChange={handleChange}
                                    placeholder="Masukkan kata sandi"
                                    autoComplete="current-password"
                                    required
                                />
                                <button
                                    type="button"
                                    className="admin-login-password__toggle"
                                    onClick={() => setShowPassword((prev) => !prev)}
                                >
                                    {showPassword ? "Sembunyikan" : "Lihat"}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            className="admin-login-submit"
                            disabled={loading || !!successMsg}
                        >
                            {loading
                                ? "Memproses..."
                                : successMsg
                                    ? "Berhasil"
                                    : "Login"}
                        </button>
                    </form>

                    
                </div>
            </div>
        </div>
    );
};

export default AdminLoginPage;
