// src/modules/public/components/pages/HomePublicPage.jsx
import React from "react";
import PublicLayout from "../../../shared/layout/PublicLayout";

import appPreview from "../../../../assets/Landing_page.png"; // ganti dengan path gambarmu

const HomePublicPage = () => {
    return (
        <PublicLayout>
            {/* ================== SECTION 1: APLIKASI SIGAP ================== */}
            <section id="aplikasi-sigap" className="section section--hero">
                <div className="section__inner section__inner--hero">
                    <div className="hero__text">
                        <h1>Aplikasi SIGAP</h1>
                        <p className="hero__subtitle">
                            SIGAP (Sistem Informasi Geospasial Anti Kejahatan) adalah aplikasi mobile
                            yang membantu masyarakat melaporkan dan memantau kejadian kejahatan secara
                            real-time berbasis lokasi.
                        </p>

                        <ul className="hero__features">
                            <li>Laporan kejadian kejahatan dari pengguna secara langsung.</li>
                            <li>Peta titik rawan kejahatan yang selalu diperbarui.</li>
                            <li>Notifikasi ketika pengguna memasuki area rawan.</li>
                            <li>Terintegrasi dengan dashboard admin untuk monitoring.</li>
                        </ul>

                        <div className="hero__actions">
                            <button className="btn btn-primary" type="button">
                                Lihat Demo Aplikasi
                            </button>
                            <button className="btn btn-outline" type="button">
                                Unduh Panduan PDF
                            </button>
                        </div>
                    </div>

                    <div className="hero__image">
                        {/* Gambar mockup mobile app */}
                        <img
                            src={appPreview}
                            alt="Tampilan Aplikasi SIGAP di perangkat mobile"
                            className="hero__image-preview"
                        />
                    </div>
                </div>
            </section>

            {/* ================== SECTION 2: TENTANG ================== */}
            <section id="tentang" className="section section--about">
                <div className="section__inner">
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
                </div>
            </section>

            {/* ================== SECTION 3: PANDUAN APLIKASI ================== */}
            <section id="panduan" className="section section--guide">
                <div className="section__inner">
                    <h2>Panduan Singkat Penggunaan Aplikasi</h2>

                    <ol className="guide__steps" >
                        <li>
                            <strong>Instal Aplikasi</strong>
                            <p>
                                Unduh aplikasi SIGAP melalui tautan resmi yang disediakan (Play Store /
                                link internal kampus). Pastikan Anda mengizinkan akses lokasi saat
                                pertama kali membuka aplikasi.
                            </p>
                        </li>
                        <li>
                            <strong>Registrasi & Login</strong>
                            <p>
                                Buat akun baru dengan mengisi data diri yang dibutuhkan. Setelah akun
                                aktif, login menggunakan username dan password yang sudah didaftarkan.
                            </p>
                        </li>
                        <li>
                            <strong>Melaporkan Kejadian</strong>
                            <p>
                                Ketika terjadi kejadian kejahatan di sekitar Anda, buka menu{" "}
                                <em>Lapor Kejadian</em>, isi kategori kejadian, deskripsi singkat, dan
                                pastikan lokasi sudah sesuai. Tambahkan foto pendukung jika diperlukan,
                                lalu kirim laporan.
                            </p>
                        </li>
                        <li>
                            <strong>Melihat Titik Rawan</strong>
                            <p>
                                Pada halaman peta, Anda dapat melihat titik-titik rawan kejahatan
                                berdasarkan data laporan yang telah diverifikasi oleh admin. Gunakan
                                informasi ini sebagai acuan untuk tetap waspada.
                            </p>
                        </li>
                        <li>
                            <strong>Notifikasi Area Rawan</strong>
                            <p>
                                Aktifkan izin notifikasi agar SIGAP dapat memberikan peringatan ketika
                                Anda memasuki area yang dikategorikan rawan kejahatan.
                            </p>
                        </li>
                    </ol>

                    <p>
                        Untuk panduan lengkap dalam bentuk PDF (beserta gambar langkah demi
                        langkah), silakan unduh melalui tombol{" "}
                        <strong>&quot;Unduh Panduan PDF&quot;</strong> pada bagian &quot;Aplikasi
                        SIGAP&quot; di atas.
                    </p>
                </div>
            </section>

            {/* ================== SECTION 4: KONTAK & TAUTAN PENDUKUNG ================== */}
            <section id="kontak" className="section section--contact">
                <div className="section__inner section__inner--contact">
                    <div className="contact__info">
                        <h2>Info Kontak</h2>
                        <p>
                            Jika Anda mengalami kendala dalam penggunaan aplikasi mobile maupun web,
                            silakan hubungi kami melalui kontak berikut:
                        </p>
                        <ul>
                            <li>
                                <strong>Email Helpdesk:</strong> helpdesk.sigap@example.com
                            </li>
                            <li>
                                <strong>WhatsApp:</strong> +62 812-3456-7890
                            </li>
                            <li>
                                <strong>Jam Layanan:</strong> Senin – Jumat, 09.00 – 17.00 WIB
                            </li>
                        </ul>
                    </div>

                    <div className="contact__links">
                        <h3>Tautan Pendukung</h3>
                        <ul>
                            <li>
                                <a href="#!" target="_blank" rel="noreferrer">
                                    Dokumentasi Teknis Aplikasi SIGAP
                                </a>
                            </li>
                            <li>
                                <a href="#!" target="_blank" rel="noreferrer">
                                    FAQ Penggunaan Aplikasi
                                </a>
                            </li>
                            <li>
                                <a href="#!" target="_blank" rel="noreferrer">
                                    Formulir Pelaporan Bug / Error
                                </a>
                            </li>
                            <li>
                                <a href="#!" target="_blank" rel="noreferrer">
                                    (Opsional) Tautan Unduh APK / Play Store
                                </a>
                            </li>
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
        </PublicLayout>
    );
};

export default HomePublicPage;
