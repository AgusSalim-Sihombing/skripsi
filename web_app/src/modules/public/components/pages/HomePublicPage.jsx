// // src/modules/public/components/pages/HomePublicPage.jsx
// import React from "react";
// import PublicLayout from "../../../shared/layout/PublicLayout";
// import appPreview from "../../../../assets/phone_mockup.png";
// import appThemeMode from "../../../../assets/phone_theme.png";

// const HomePublicPage = () => {
//     return (
//         <PublicLayout>
//             <section id="aplikasi-sigap" className="landing-hero">
//                 {/* background decor */}
//                 <div className="landing-hero__bg-glow landing-hero__bg-glow--1"></div>
//                 <div className="landing-hero__bg-glow landing-hero__bg-glow--2"></div>



//                 <div className="landing-hero__inner">
//                     <div className="landing-hero__card">
//                         <div className="landing-hero__content">
//                             {/* kiri */}
//                             <div className="landing-hero__text">
//                                 <div className="landing-hero__brand">SIGAP Platform</div>

//                                 <h1>
//                                     Pantau, Laporkan, dan Waspadai
//                                     <span> Kejahatan Secara Real-Time</span>
//                                 </h1>

//                                 <p className="landing-hero__subtitle">
//                                     SIGAP (Sistem Informasi Geospasial Anti Kejahatan)
//                                     membantu masyarakat melaporkan kejadian, melihat titik rawan,
//                                     dan menerima notifikasi area berisiko langsung dari perangkat mobile.
//                                 </p>

//                                 <div className="landing-hero__actions">
//                                     <button className="btn btn-primary landing-btn-primary" type="button">
//                                         Lihat Demo Aplikasi
//                                     </button>
//                                     <button className="btn btn-outline landing-btn-outline" type="button">
//                                         Unduh Panduan PDF
//                                     </button>
//                                 </div>

//                                 <div className="landing-hero__mini-info">
//                                     <div className="mini-info-chip">
//                                         <span className="mini-info-chip__dot"></span>
//                                         Real-time laporan
//                                     </div>
//                                     <div className="mini-info-chip">
//                                         <span className="mini-info-chip__dot"></span>
//                                         Peta zona rawan
//                                     </div>
//                                     <div className="mini-info-chip">
//                                         <span className="mini-info-chip__dot"></span>
//                                         Dashboard admin
//                                     </div>
//                                 </div>
//                             </div>

//                             {/* kanan */}
//                             <div className="landing-hero__visual">
//                                 <div className="phone-orbit phone-orbit--1"></div>
//                                 <div className="phone-orbit phone-orbit--2"></div>
//                                 <div className="phone-orbit phone-orbit--3"></div>

//                                 <div className="orbit-icon orbit-icon--1">📍</div>
//                                 <div className="orbit-icon orbit-icon--2">🛡️</div>
//                                 <div className="orbit-icon orbit-icon--3">🚨</div>
//                                 <div className="orbit-icon orbit-icon--4">📡</div>

//                                 <div className="landing-hero__phone-wrap">
//                                     <img
//                                         src={appPreview}
//                                         alt="Tampilan Aplikasi SIGAP di perangkat mobile"
//                                         className="landing-hero__phone"
//                                     />
//                                 </div>
//                             </div>
//                         </div>

//                         {/* stats bawah */}
//                         <div className="landing-hero__stats">
//                             <div className="stat-card">
//                                 <h3>24/7</h3>
//                                 <p>Pemantauan Insiden</p>
//                             </div>
//                             <div className="stat-card">
//                                 <h3>Real-time</h3>
//                                 <p>Notifikasi & Lokasi</p>
//                             </div>
//                             <div className="stat-card">
//                                 <h3>Admin Web</h3>
//                                 <p>Monitoring & Validasi</p>
//                             </div>
//                             <div className="stat-card">
//                                 <h3>Mobile App</h3>
//                                 <p>Laporan Cepat Pengguna</p>
//                             </div>
//                         </div>
//                     </div>
//                     {/* ================== SECTION 2: TENTANG ================== */}
//                     <section id="tentang" className="section section--about">
//                         <div className="section__inner about-section__inner">
//                             <div className="about-section__text">
//                                 <h2>Tentang SIGAP</h2>
//                                 <p>
//                                     SIGAP dikembangkan sebagai solusi untuk membantu masyarakat lebih waspada
//                                     terhadap potensi kejahatan di sekitarnya. Melalui pemetaan kejadian
//                                     kejahatan dan area rawan, aplikasi ini diharapkan dapat:
//                                 </p>

//                                 <ul>
//                                     <li>Meningkatkan kesadaran masyarakat terhadap keamanan lingkungan.</li>
//                                     <li>
//                                         Menjadi media pelaporan awal sebelum kasus ditindaklanjuti oleh pihak
//                                         berwenang.
//                                     </li>
//                                     <li>
//                                         Memberikan data pendukung bagi pihak kampus/instansi/komunitas dalam
//                                         mengambil keputusan terkait keamanan.
//                                     </li>
//                                 </ul>

//                                 <p>
//                                     Aplikasi ini juga didukung oleh sistem web admin, di mana admin dapat
//                                     memantau laporan, memverifikasi data, mengelola titik lokasi rawan, dan
//                                     menghasilkan rekapitulasi laporan untuk kebutuhan analisis.
//                                 </p>

//                                 <p>
//                                     Aplikasi ini juga dibantu dengan tema gelap/terang untuk meningkatkan best experience
//                                     pengguna.
//                                 </p>
//                             </div>

//                             <div className="about-section__visual">
//                                 <div className="about-section__phone-wrap">
//                                     <img
//                                         src={appThemeMode}
//                                         alt="Tampilan mode aplikasi SIGAP"
//                                         className="about-section__phone"
//                                     />
//                                 </div>
//                             </div>
//                         </div>
//                     </section>

//                     {/* ================== SECTION 3: PANDUAN APLIKASI ================== */}
//                     <section id="panduan" className="section section--guide">
//                         <div className="section__inner">
//                             <h2>Panduan Singkat Penggunaan Aplikasi</h2>

//                             <ol className="guide__steps">
//                                 <li>
//                                     <strong>Instal Aplikasi</strong>
//                                     <p>
//                                         Unduh aplikasi SIGAP melalui tautan resmi yang disediakan
//                                         dan izinkan akses lokasi saat pertama kali membuka aplikasi.
//                                     </p>
//                                 </li>
//                                 <li>
//                                     <strong>Registrasi & Login</strong>
//                                     <p>
//                                         Buat akun baru, lalu login menggunakan username dan password
//                                         yang telah didaftarkan.
//                                     </p>
//                                 </li>
//                                 <li>
//                                     <strong>Melaporkan Kejadian</strong>
//                                     <p>
//                                         Gunakan menu laporan cepat untuk mengirim detail kejadian,
//                                         lokasi, dan bukti pendukung.
//                                     </p>
//                                 </li>
//                                 <li>
//                                     <strong>Melihat Titik Rawan</strong>
//                                     <p>
//                                         Pantau titik-titik rawan kejahatan pada peta interaktif
//                                         berdasarkan data laporan yang telah diverifikasi.
//                                     </p>
//                                 </li>
//                                 <li>
//                                     <strong>Notifikasi Area Rawan</strong>
//                                     <p>
//                                         Aktifkan notifikasi agar aplikasi memberi peringatan saat
//                                         Anda berada di sekitar area berisiko.
//                                     </p>
//                                 </li>
//                             </ol>
//                         </div>
//                     </section>

//                     {/* ================== SECTION 4: KONTAK ================== */}
//                     <section id="kontak" className="section section--contact">
//                         <div className="section__inner section__inner--contact">
//                             <div className="contact__info">
//                                 <h2>Info Kontak</h2>
//                                 <p>
//                                     Jika Anda mengalami kendala dalam penggunaan aplikasi mobile maupun web,
//                                     silakan hubungi kami melalui kontak berikut:
//                                 </p>
//                                 <ul>
//                                     <li><strong>Email Helpdesk:</strong> helpdesk.sigap@example.com</li>
//                                     <li><strong>WhatsApp:</strong> +62 812-3456-7890</li>
//                                     <li><strong>Jam Layanan:</strong> Senin – Jumat, 09.00 – 17.00 WIB</li>
//                                 </ul>
//                             </div>

//                             <div className="contact__links">
//                                 <h3>Tautan Pendukung</h3>
//                                 <ul>
//                                     <li><a href="#!" target="_blank" rel="noreferrer">Dokumentasi Teknis Aplikasi SIGAP</a></li>
//                                     <li><a href="#!" target="_blank" rel="noreferrer">FAQ Penggunaan Aplikasi</a></li>
//                                     <li><a href="#!" target="_blank" rel="noreferrer">Formulir Pelaporan Bug / Error</a></li>
//                                     <li><a href="#!" target="_blank" rel="noreferrer">(Opsional) Tautan Unduh APK / Play Store</a></li>
//                                 </ul>

//                                 <div className="contact__admin-login">
//                                     <p>Untuk pengelolaan data dan monitoring laporan:</p>
//                                     <a href="/login-admin" className="btn btn-secondary">
//                                         Login Admin Dashboard
//                                     </a>
//                                 </div>
//                             </div>
//                         </div>
//                     </section>

//                 </div>
//             </section>
//         </PublicLayout>
//     );
// };

// export default HomePublicPage;

// Kedua
// import React from "react";
// import PublicLayout from "../../../shared/layout/PublicLayout";
// import appPreview from "../../../../assets/phone_mockup.png";
// import appThemeMode from "../../../../assets/phone_theme.png";

// const HomePublicPage = () => {
//     return (
//         <PublicLayout>
//             <section id="aplikasi-sigap" className="crime-hero">
//                 <div className="crime-hero__inner">
//                     <div className="crime-hero__topbar">
//                         <span className="crime-hero__eyebrow">
//                             Zona Bahaya Real-Time
//                         </span>
//                     </div>

//                     <div className="crime-hero__heading">
//                         <h1>
//                             Pantau Kejahatan dan
//                             <br />
//                             Tingkatkan Kewaspadaan
//                             <span> Secara Real-Time</span>
//                         </h1>
//                         <p>
//                             SIGAP membantu masyarakat melihat titik rawan, mengirim laporan,
//                             dan menerima peringatan area berisiko langsung dari satu platform.
//                         </p>
//                     </div>

//                     {/* <div className="crime-hero__filters">
//                         <div className="crime-filter">
//                             <span className="crime-filter__label">Lokasi</span>
//                             <strong>Semua Area</strong>
//                         </div>
//                         <div className="crime-filter">
//                             <span className="crime-filter__label">Kategori</span>
//                             <strong>Semua Kejadian</strong>
//                         </div>
//                         <div className="crime-filter">
//                             <span className="crime-filter__label">Status</span>
//                             <strong>Aktif & Pending</strong>
//                         </div>
//                         <button className="crime-filter__search-btn" type="button">
//                             Cari
//                         </button>
//                     </div> */}

//                     <div className="crime-map-showcase">
//                         <div className="crime-map-showcase__canvas">
//                             {/* 
//                               Versi mirip desain referensi.
//                               Kalau mau LIVE MAP beneran, ganti area ini dengan Leaflet public map.
//                             */}

//                             <div className="crime-map-showcase__grid"></div>

//                             <span className="crime-map-marker crime-map-marker--1">🚨</span>
//                             <span className="crime-map-marker crime-map-marker--2">📍</span>
//                             <span className="crime-map-marker crime-map-marker--3">⚠️</span>
//                             <span className="crime-map-marker crime-map-marker--4">🚨</span>
//                             <span className="crime-map-marker crime-map-marker--5">📍</span>

//                             <div className="crime-map-card">
//                                 <div className="crime-map-card__image">
//                                     <img src={appPreview} alt="Preview SIGAP" />
//                                     <span className="crime-map-card__badge">Live</span>
//                                 </div>

//                                 <div className="crime-map-card__body">
//                                     <h3>Zona Rawan Pencurian</h3>
//                                     <p>Jl. Gatot Subroto, Medan</p>

//                                     <div className="crime-map-card__meta">
//                                         <span>Radius 500 m</span>
//                                         <span>Risiko Tinggi</span>
//                                         <span>12 laporan</span>
//                                     </div>

//                                     <div className="crime-map-card__footer">
//                                         <strong>Aktif dipantau</strong>
//                                         <button type="button">Lihat Zona</button>
//                                     </div>
//                                 </div>
//                             </div>

//                             <div className="crime-map-pin crime-map-pin--main">24</div>
//                         </div>
//                     </div>

//                     <div className="crime-hero__stats">
//                         <div className="crime-stat">
//                             <h3>120+</h3>
//                             <p>Zona Terdata</p>
//                         </div>
//                         <div className="crime-stat">
//                             <h3>24/7</h3>
//                             <p>Pemantauan</p>
//                         </div>
//                         <div className="crime-stat">
//                             <h3>Real-time</h3>
//                             <p>Notifikasi Area</p>
//                         </div>
//                         <div className="crime-stat">
//                             <h3>Admin Web</h3>
//                             <p>Validasi & Monitoring</p>
//                         </div>
//                     </div>
//                 </div>
//             </section>

//             <section id="tentang" className="section section--clean">
//                 <div className="section-clean__inner section-clean__inner--about">
//                     <div className="section-clean__content">
//                         <span className="section-clean__eyebrow">- Tentang SIGAP</span>
//                         <h2>
//                             Solusi digital untuk membantu masyarakat lebih waspada
//                             terhadap kejahatan di sekitarnya
//                         </h2>
//                         <p>
//                             SIGAP dikembangkan sebagai platform pemetaan dan pelaporan
//                             kejadian kriminal berbasis lokasi. Melalui aplikasi ini,
//                             pengguna dapat melihat area rawan, mengirim laporan cepat,
//                             serta memperoleh informasi yang mendukung keputusan keamanan
//                             secara lebih akurat.
//                         </p>
//                         <p>
//                             Sistem ini juga terhubung dengan dashboard admin untuk
//                             memverifikasi laporan, mengelola zona bahaya, dan memantau
//                             data insiden secara terpusat.
//                         </p>
//                     </div>

//                     <div className="section-clean__visual">
//                         <div className="feature-mini-card">
//                             <div className="feature-mini-card__icon">🗺️</div>
//                             <h4>Peta Interaktif</h4>
//                             <p>Memantau titik rawan dan area berisiko secara visual.</p>
//                         </div>

//                         <div className="feature-mini-card">
//                             <div className="feature-mini-card__icon">📢</div>
//                             <h4>Laporan Cepat</h4>
//                             <p>Pengguna dapat mengirim kejadian secara langsung.</p>
//                         </div>

//                         <div className="feature-mini-card feature-mini-card--wide">
//                             <img src={appThemeMode} alt="Mode aplikasi SIGAP" />
//                         </div>
//                     </div>
//                 </div>
//             </section>

//             <section id="panduan" className="section section--clean">
//                 <div className="section-clean__inner section-clean__inner--guide">
//                     <div className="section-clean__content">
//                         <span className="section-clean__eyebrow">- Panduan aplikasi</span>
//                         <h2>
//                             Langkah penggunaan SIGAP yang sederhana dan cepat dipahami
//                         </h2>
//                         <p>
//                             Pengguna cukup melakukan registrasi, mengaktifkan izin lokasi,
//                             lalu dapat mulai melihat peta, membuat laporan, dan menerima
//                             peringatan saat memasuki area rawan.
//                         </p>

//                         <button className="section-clean__cta" type="button">
//                             Lihat Panduan Lengkap
//                         </button>
//                     </div>

//                     <div className="guide-clean-grid">
//                         <div className="guide-clean-card">
//                             <h4>Instal & Login</h4>
//                             <p>
//                                 Unduh aplikasi, buat akun, lalu masuk untuk mengakses
//                                 semua fitur utama SIGAP.
//                             </p>
//                         </div>

//                         <div className="guide-clean-card">
//                             <h4>Lihat Crime Map</h4>
//                             <p>
//                                 Pantau titik rawan kejahatan melalui peta interaktif yang
//                                 telah diverifikasi.
//                             </p>
//                         </div>

//                         <div className="guide-clean-card">
//                             <h4>Kirim Laporan</h4>
//                             <p>
//                                 Tambahkan detail kejadian, lokasi, dan bukti pendukung
//                                 secara cepat.
//                             </p>
//                         </div>

//                         <div className="guide-clean-card">
//                             <h4>Terima Notifikasi</h4>
//                             <p>
//                                 Dapatkan peringatan otomatis saat berada di sekitar zona
//                                 rawan.
//                             </p>
//                         </div>
//                     </div>
//                 </div>
//             </section>

//             <section id="kontak" className="section section--clean">
//                 <div className="section-clean__inner section-clean__inner--contact">
//                     <div className="contact-clean-card">
//                         <span className="section-clean__eyebrow">- Info kontak</span>
//                         <h2>Butuh bantuan?</h2>
//                         <p>
//                             Jika mengalami kendala dalam penggunaan aplikasi mobile maupun
//                             web, hubungi tim SIGAP melalui kanal berikut.
//                         </p>

//                         <ul className="contact-clean-list">
//                             <li><strong>Email:</strong> helpdesk.sigap@example.com</li>
//                             <li><strong>WhatsApp:</strong> +62 812-3456-7890</li>
//                             <li><strong>Jam Layanan:</strong> Senin – Jumat, 09.00 – 17.00 WIB</li>
//                         </ul>
//                     </div>

//                     <div className="contact-clean-card">
//                         <span className="section-clean__eyebrow">- Tautan pendukung</span>
//                         <h2>Akses cepat</h2>

//                         <div className="contact-clean-links">
//                             <a href="#!" target="_blank" rel="noreferrer">
//                                 Dokumentasi Teknis SIGAP
//                             </a>
//                             <a href="#!" target="_blank" rel="noreferrer">
//                                 FAQ Penggunaan Aplikasi
//                             </a>
//                             <a href="#!" target="_blank" rel="noreferrer">
//                                 Form Pelaporan Bug / Error
//                             </a>
//                             <a href="#!" target="_blank" rel="noreferrer">
//                                 Tautan Unduh APK / Play Store
//                             </a>
//                         </div>

//                         <div className="contact-clean-admin">
//                             <p>Untuk pengelolaan laporan dan validasi data:</p>
//                             <a href="/login-admin" className="contact-clean-admin__btn">
//                                 Login Admin Dashboard
//                             </a>
//                         </div>
//                     </div>
//                 </div>
//             </section>
//         </PublicLayout>
//     );
// };

// export default HomePublicPage;

import React from "react";
import PublicLayout from "../../../shared/layout/PublicLayout";
import crimeMapBg from "../../../../assets/crime-map-bg.png";

const mockZones = [
    {
        id: 1,
        title: "Zona Rawan Pencurian",
        risk: "Risiko Tinggi",
        radius: "500 m",
        location: "Jl. Gatot Subroto, Medan",
        status: "Aktif",
        date: "12 Januari 2026 • 21:30",
        top: "23%",
        left: "18%",
        type: "danger",
    },
    {
        id: 2,
        title: "Zona Laporan Pending",
        risk: "Pending Verifikasi",
        radius: "300 m",
        location: "Jl. Iskandar Muda, Medan",
        status: "Pending",
        date: "10 Januari 2026 • 18:10",
        top: "34%",
        left: "43%",
        type: "pending",
    },
    {
        id: 3,
        title: "Zona Rawan Begal",
        risk: "Risiko Sedang",
        radius: "420 m",
        location: "Jl. Ring Road, Medan",
        status: "Aktif",
        date: "09 Januari 2026 • 23:40",
        top: "61%",
        left: "28%",
        type: "danger",
    },
    {
        id: 4,
        title: "Laporan Baru",
        risk: "Butuh Monitoring",
        radius: "250 m",
        location: "Jl. Setiabudi, Medan",
        status: "Baru",
        date: "08 Januari 2026 • 17:20",
        top: "27%",
        left: "76%",
        type: "info",
    },
    {
        id: 5,
        title: "Zona Rawan Malam Hari",
        risk: "Risiko Tinggi",
        radius: "600 m",
        location: "Jl. SM Raja, Medan",
        status: "Aktif",
        date: "07 Januari 2026 • 22:15",
        top: "74%",
        left: "72%",
        type: "danger",
    },
];

const HomePublicPage = () => {
    const featuredZone = mockZones[0];

    return (
        <PublicLayout>
            <section id="aplikasi-sigap" className="visitor-map-hero">
                <div
                    className="visitor-map-hero__map"
                    style={{ backgroundImage: `url(${crimeMapBg})` }}
                >
                    <div className="visitor-map-hero__overlay" />

                    {mockZones.map((zone) => (
                        <button
                            key={zone.id}
                            type="button"
                            className={`visitor-map-marker visitor-map-marker--${zone.type}`}
                            style={{ top: zone.top, left: zone.left }}
                            aria-label={zone.title}
                        >
                            <span className="visitor-map-marker__pulse" />
                            <span className="visitor-map-marker__icon">
                                {zone.type === "pending" ? "?" : zone.type === "info" ? "i" : "!"}
                            </span>
                        </button>
                    ))}

                    {/* <div className="visitor-map-card">
                        <div className="visitor-map-card__status-row">
                            <span className="visitor-map-card__badge">
                                {featuredZone.status}
                            </span>
                            <span className="visitor-map-card__tag">
                                {featuredZone.risk}
                            </span>
                        </div>

                        <h3>{featuredZone.title}</h3>
                        <p className="visitor-map-card__location">
                            {featuredZone.location}
                        </p>

                        <div className="visitor-map-card__meta">
                            <span>Radius {featuredZone.radius}</span>
                            <span>Monitoring aktif</span>
                        </div>

                        <div className="visitor-map-card__footer">
                            <strong>{featuredZone.date}</strong>
                            <button type="button">Lihat Detail</button>
                        </div>
                    </div> */}

                    <div className="visitor-map-hero__headline">
                        <span className="visitor-map-hero__eyebrow">
                            Sistem Informasi Geospasial Anti Kejahatan
                        </span>
                        <h1>
                            Peta Kejahatan untuk
                            <br />
                            Waspada Lebih Awal
                        </h1>
                        <p style={{
                            fontSize: "20px"
                        }}>
                            SIGAP membantu masyarakat melihat area rawan, memahami tingkat
                            risiko, dan mengenal kondisi keamanan sekitar secara visual.
                        </p>
                    </div>
                </div>

                <div className="crime-hero__stats">
                    <div className="crime-stat">
                        <h3>120+</h3>
                        <p>Total Zona</p>
                    </div>
                    <div className="crime-stat">
                        <h3>48+</h3>
                        <p>Zona Aktif</p>
                    </div>
                    <div className="crime-stat">
                        <h3>24/7</h3>
                        <p>Pemantauan</p>
                    </div>
                    <div className="crime-stat">
                        <h3>Real-time</h3>
                        <p>Informasi Risiko</p>
                    </div>
                </div>
            </section>

            <section id="tentang" className="section section--clean">
                <div className="section-clean__inner section-clean__inner--about">
                    <div className="section-clean__content">
                        <span className="section-clean__eyebrow">Tentang SIGAP</span>
                        <h2>
                            Platform yang membantu masyarakat memahami kondisi keamanan
                            lingkungannya secara lebih cepat dan visual
                        </h2>
                        <p style={{
                            fontSize: "20px"
                        }}>
                            SIGAP dirancang untuk menghadirkan informasi kriminal berbasis
                            lokasi agar pengguna bisa lebih waspada terhadap potensi bahaya
                            di sekitarnya. Melalui peta interaktif, laporan kejadian, dan
                            pemantauan zona rawan, pengguna memperoleh gambaran yang lebih
                            jelas terhadap lingkungan yang sedang dihadapi.
                        </p>
                        <p style={{
                            fontSize: "20px"
                        }}>
                            Selain itu, SIGAP juga mendukung proses monitoring melalui
                            dashboard admin, sehingga data yang ditampilkan dapat dikelola
                            dan dipantau secara terpusat.
                        </p>
                    </div>

                    <div className="section-clean__visual">
                        <div className="feature-mini-card">
                            <div className="feature-mini-card__icon">🗺️</div>
                            <h4>Peta Interaktif</h4>
                            <p>Menampilkan titik rawan dan area dengan tingkat risiko tertentu.</p>
                        </div>

                        <div className="feature-mini-card">
                            <div className="feature-mini-card__icon">📢</div>
                            <h4>Laporan Cepat</h4>
                            <p>Masyarakat dapat mengirim informasi kejadian secara langsung.</p>
                        </div>

                        <div className="feature-mini-card feature-mini-card--large">
                            <div className="feature-mini-card__icon">🛡️</div>
                            <h4>Monitoring Terpusat</h4>
                            <p>
                                Data laporan dan zona dapat dikelola admin untuk mendukung
                                proses validasi dan pengawasan.
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            <section id="panduan" className="section section--clean">
                <div className="section-clean__inner section-clean__inner--guide">
                    <div className="section-clean__content">
                        <span className="section-clean__eyebrow">Panduan aplikasi</span>
                        <h2>Penggunaan SIGAP yang singkat, jelas, dan mudah dipahami</h2>
                        <p style={{
                            fontSize: "20px"
                        }}>
                            Alur penggunaan aplikasi dibuat sederhana agar pengguna bisa
                            langsung memantau peta, mengirim laporan, dan memahami area
                            berisiko tanpa proses yang rumit.
                        </p>
                    </div>

                    <div className="guide-clean-grid">
                        <div className="guide-clean-card">
                            <h4>1. Registrasi & Login</h4>
                            <p>Buat akun dan masuk ke aplikasi untuk mengakses fitur utama.</p>
                        </div>
                        <div className="guide-clean-card">
                            <h4>2. Pantau Crime Map</h4>
                            <p>Lihat area rawan dan pahami kondisi keamanan sekitar.</p>
                        </div>
                        <div className="guide-clean-card">
                            <h4>3. Kirim Laporan</h4>
                            <p>Laporkan kejadian dengan lokasi dan deskripsi singkat.</p>
                        </div>
                        <div className="guide-clean-card">
                            <h4>4. Terima Informasi Risiko</h4>
                            <p>Dapatkan wawasan area rawan untuk meningkatkan kewaspadaan.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section id="kontak" className="section section--clean">
                <div className="section-clean__inner section-clean__inner--contact">
                    <div className="contact-clean-card">
                        <span className="section-clean__eyebrow">Info kontak</span>
                        <h2>Bantuan penggunaan</h2>
                        <p style={{
                            fontSize: "20px"
                        }}>
                            Jika mengalami kendala dalam penggunaan aplikasi SIGAP, silakan
                            hubungi tim bantuan melalui kontak berikut.
                        </p>

                        <ul className="contact-clean-list">
                            <li><strong>Email:</strong> helpdesk.sigap@example.com</li>
                            <li><strong>WhatsApp:</strong> +62 812-3456-7890</li>
                            <li><strong>Jam Layanan:</strong> Senin – Jumat, 09.00 – 17.00 WIB</li>
                        </ul>
                    </div>

                    <div className="contact-clean-card">
                        <span className="section-clean__eyebrow">Tautan pendukung</span>
                        <h2>Akses cepat</h2>

                        <div className="contact-clean-links">
                            <a href="#!" target="_blank" rel="noreferrer">
                                Dokumentasi Teknis SIGAP
                            </a>
                            <a href="#!" target="_blank" rel="noreferrer">
                                FAQ Penggunaan
                            </a>
                            <a href="#!" target="_blank" rel="noreferrer">
                                Form Pelaporan Bug / Error
                            </a>
                            <a href="#!" target="_blank" rel="noreferrer">
                                Tautan Unduh APK
                            </a>
                        </div>

                        <div className="contact-clean-admin">
                            <p>Untuk monitoring dan validasi data:</p>
                            <a href="/login-admin" className="contact-clean-admin__btn">
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