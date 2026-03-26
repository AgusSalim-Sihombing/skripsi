import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import PublicLayout from "../../../shared/layout/PublicLayout";
import { loginAdmin } from "../../../../services/authService";

const AdminLoginPage = () => {
    const navigate = useNavigate();
    const [form, setForm] = useState({ username: "", password: "" });
    const [loading, setLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const handleChange = (e) => {
        setForm((prev) => ({
            ...prev,
            [e.target.name]: e.target.value,
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
            } else {
                // simpan token & info admin
                localStorage.setItem("sigap_admin_token", res.data.token);
                localStorage.setItem(
                    "sigap_admin_info",
                    JSON.stringify(res.data.admin)
                );

                // tampilkan pesan sukses dulu
                setSuccessMsg("Login berhasil! Mengalihkan ke dashboard...");

                // delay 3 detik sebelum pindah halaman
                setTimeout(() => {
                    navigate("/admin/dashboard");
                }, 3000);
            }
        } catch (err) {
            console.error("Login error:", err);
            setErrorMsg(
                err?.response?.data?.message || "Terjadi kesalahan pada server saat login"
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <PublicLayout>
            <section className="section section--login-admin">
                <div className="section__inner section__inner--login">
                    <div className="login-card">
                        <h2>Login Admin SIGAP</h2>
                        <p className="login-subtitle">
                            Masuk untuk mengelola laporan kejadian, lokasi rawan, dan aktivitas
                            pengguna aplikasi SIGAP.
                        </p>

                        {errorMsg && <div className="login-error">{errorMsg}</div>}
                        {successMsg && <div className="login-success">{successMsg}</div>}

                        <form onSubmit={handleSubmit} className="login-form">
                            <div className="form-group">
                                <label htmlFor="username">Username</label>
                                <input
                                    id="username"
                                    name="username"
                                    type="text"
                                    value={form.username}
                                    onChange={handleChange}
                                    placeholder="Masukkan username admin"
                                    required
                                />
                            </div>

                            <div className="form-group">
                                <label htmlFor="password">Kata Sandi</label>
                                <input
                                    id="password"
                                    name="password"
                                    type="password"
                                    value={form.password}
                                    onChange={handleChange}
                                    placeholder="Masukkan kata sandi"
                                    required
                                />
                            </div>

                            <button type="submit" className="btn btn-primary" disabled={loading || !!successMsg}>
                                {loading
                                    ? "Memproses..."
                                    : successMsg
                                        ? "Berhasil"
                                        : "Login"}
                            </button>
                        </form>
                    </div>
                </div>
            </section>
        </PublicLayout>
    );
};

export default AdminLoginPage;
