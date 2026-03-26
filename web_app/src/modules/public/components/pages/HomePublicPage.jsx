// src/modules/public/components/pages/HomePublicPage.jsx
import React from "react";
import PublicLayout from "../../../shared/layout/PublicLayout";
import appPreview from "../../../../assets/phone_mockup.png";
import appThemeMode from "../../../../assets/phone_theme.png";

const HomePublicPage = () => {
    return (
        <PublicLayout>
            <section id="aplikasi-sigap" className="landing-hero">
                {/* background decor */}
                <div className="landing-hero__bg-glow landing-hero__bg-glow--1"></div>
                <div className="landing-hero__bg-glow landing-hero__bg-glow--2"></div>



                <div className="landing-hero__inner">
                    <div className="landing-hero__card">
                        <div className="landing-hero__content">
                            {/* kiri */}
                            <div className="landing-hero__text">
                                <div className="landing-hero__brand">SIGAP Platform</div>

                                <h1>
                                    Pantau, Laporkan, dan Waspadai
                                    <span> Kejahatan Secara Real-Time</span>
                                </h1>

                                <p className="landing-hero__subtitle">
                                    SIGAP (Sistem Informasi Geospasial Anti Kejahatan)
                                    membantu masyarakat melaporkan kejadian, melihat titik rawan,
                                    dan menerima notifikasi area berisiko langsung dari perangkat mobile.
                                </p>

                                <div className="landing-hero__actions">
                                    <button className="btn btn-primary landing-btn-primary" type="button">
                                        Lihat Demo Aplikasi
                                    </button>
                                    <button className="btn btn-outline landing-btn-outline" type="button">
                                        Unduh Panduan PDF
                                    </button>
                                </div>

                                <div className="landing-hero__mini-info">
                                    <div className="mini-info-chip">
                                        <span className="mini-info-chip__dot"></span>
                                        Real-time laporan
                                    </div>
                                    <div className="mini-info-chip">
                                        <span className="mini-info-chip__dot"></span>
                                        Peta zona rawan
                                    </div>
                                    <div className="mini-info-chip">
                                        <span className="mini-info-chip__dot"></span>
                                        Dashboard admin
                                    </div>
                                </div>
                            </div>

                            {/* kanan */}
                            <div className="landing-hero__visual">
                                <div className="phone-orbit phone-orbit--1"></div>
                                <div className="phone-orbit phone-orbit--2"></div>
                                <div className="phone-orbit phone-orbit--3"></div>

                                <div className="orbit-icon orbit-icon--1">📍</div>
                                <div className="orbit-icon orbit-icon--2">🛡️</div>
                                <div className="orbit-icon orbit-icon--3">🚨</div>
                                <div className="orbit-icon orbit-icon--4">📡</div>

                                <div className="landing-hero__phone-wrap">
                                    <img
                                        src={appPreview}
                                        alt="Tampilan Aplikasi SIGAP di perangkat mobile"
                                        className="landing-hero__phone"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* stats bawah */}
                        <div className="landing-hero__stats">
                            <div className="stat-card">
                                <h3>24/7</h3>
                                <p>Pemantauan Insiden</p>
                            </div>
                            <div className="stat-card">
                                <h3>Real-time</h3>
                                <p>Notifikasi & Lokasi</p>
                            </div>
                            <div className="stat-card">
                                <h3>Admin Web</h3>
                                <p>Monitoring & Validasi</p>
                            </div>
                            <div className="stat-card">
                                <h3>Mobile App</h3>
                                <p>Laporan Cepat Pengguna</p>
                            </div>
                        </div>
                    </div>
                    {/* ================== SECTION 2: TENTANG ================== */}
                    <section id="tentang" className="section section--about">
                        <div className="section__inner about-section__inner">
                            <div className="about-section__text">
                                <h2>Tentang SIGAP</h2>
                                <p>
                                    SIGAP dikembangkan sebagai solusi untuk membantu masyarakat lebih waspada
                                    terhadap potensi kejahatan di sekitarnya. Melalui pemetaan kejadian
                                    kejahatan dan area rawan, aplikasi ini diharapkan dapat:
                                </p>

                                <ul>
                                    <li>Meningkatkan kesadaran masyarakat terhadap keamanan lingkungan.</li>
                                    <li>
                                        Menjadi media pelaporan awal sebelum kasus ditindaklanjuti oleh pihak
                                        berwenang.
                                    </li>
                                    <li>
                                        Memberikan data pendukung bagi pihak kampus/instansi/komunitas dalam
                                        mengambil keputusan terkait keamanan.
                                    </li>
                                </ul>

                                <p>
                                    Aplikasi ini juga didukung oleh sistem web admin, di mana admin dapat
                                    memantau laporan, memverifikasi data, mengelola titik lokasi rawan, dan
                                    menghasilkan rekapitulasi laporan untuk kebutuhan analisis.
                                </p>

                                <p>
                                    Aplikasi ini juga dibantu dengan tema gelap/terang untuk meningkatkan best experience
                                    pengguna.
                                </p>
                            </div>

                            <div className="about-section__visual">
                                <div className="about-section__phone-wrap">
                                    <img
                                        src={appThemeMode}
                                        alt="Tampilan mode aplikasi SIGAP"
                                        className="about-section__phone"
                                    />
                                </div>
                            </div>
                        </div>
                    </section>

                    {/* ================== SECTION 3: PANDUAN APLIKASI ================== */}
                    <section id="panduan" className="section section--guide">
                        <div className="section__inner">
                            <h2>Panduan Singkat Penggunaan Aplikasi</h2>

                            <ol className="guide__steps">
                                <li>
                                    <strong>Instal Aplikasi</strong>
                                    <p>
                                        Unduh aplikasi SIGAP melalui tautan resmi yang disediakan
                                        dan izinkan akses lokasi saat pertama kali membuka aplikasi.
                                    </p>
                                </li>
                                <li>
                                    <strong>Registrasi & Login</strong>
                                    <p>
                                        Buat akun baru, lalu login menggunakan username dan password
                                        yang telah didaftarkan.
                                    </p>
                                </li>
                                <li>
                                    <strong>Melaporkan Kejadian</strong>
                                    <p>
                                        Gunakan menu laporan cepat untuk mengirim detail kejadian,
                                        lokasi, dan bukti pendukung.
                                    </p>
                                </li>
                                <li>
                                    <strong>Melihat Titik Rawan</strong>
                                    <p>
                                        Pantau titik-titik rawan kejahatan pada peta interaktif
                                        berdasarkan data laporan yang telah diverifikasi.
                                    </p>
                                </li>
                                <li>
                                    <strong>Notifikasi Area Rawan</strong>
                                    <p>
                                        Aktifkan notifikasi agar aplikasi memberi peringatan saat
                                        Anda berada di sekitar area berisiko.
                                    </p>
                                </li>
                            </ol>
                        </div>
                    </section>

                    {/* ================== SECTION 4: KONTAK ================== */}
                    <section id="kontak" className="section section--contact">
                        <div className="section__inner section__inner--contact">
                            <div className="contact__info">
                                <h2>Info Kontak</h2>
                                <p>
                                    Jika Anda mengalami kendala dalam penggunaan aplikasi mobile maupun web,
                                    silakan hubungi kami melalui kontak berikut:
                                </p>
                                <ul>
                                    <li><strong>Email Helpdesk:</strong> helpdesk.sigap@example.com</li>
                                    <li><strong>WhatsApp:</strong> +62 812-3456-7890</li>
                                    <li><strong>Jam Layanan:</strong> Senin – Jumat, 09.00 – 17.00 WIB</li>
                                </ul>
                            </div>

                            <div className="contact__links">
                                <h3>Tautan Pendukung</h3>
                                <ul>
                                    <li><a href="#!" target="_blank" rel="noreferrer">Dokumentasi Teknis Aplikasi SIGAP</a></li>
                                    <li><a href="#!" target="_blank" rel="noreferrer">FAQ Penggunaan Aplikasi</a></li>
                                    <li><a href="#!" target="_blank" rel="noreferrer">Formulir Pelaporan Bug / Error</a></li>
                                    <li><a href="#!" target="_blank" rel="noreferrer">(Opsional) Tautan Unduh APK / Play Store</a></li>
                                </ul>

                                <div className="contact__admin-login">
                                    <p>Untuk pengelolaan data dan monitoring laporan:</p>
                                    <a href="/login-admin" className="btn btn-secondary">
                                        Login Admin Dashboard
                                    </a>
                                </div>
                            </div>
                        </div>
                    </section>

                </div>
            </section>
        </PublicLayout>
    );
};

export default HomePublicPage;