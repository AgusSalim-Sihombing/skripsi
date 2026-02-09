const express = require("express");
const cors = require("cors");
const http = require("http");
require("dotenv").config();

const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 3001;
const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const adminUserRoute = require("./src/routes/adminUserRoute");

const USER_JWT_SECRET = process.env.USER_JWT_SECRET || "user-secret-dev";

const mobilePanicRoute = require("./src/routes/mobilePanicRoute");


// init socket io
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST", "PATCH"] },
});

// Middleware
app.use(cors());
app.use(express.json({ limit: "20mb" }));
app.use(express.urlencoded({ extended: true, limit: "20mb" }));

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

app.use((err, req, res, next) => {
  console.error("[GLOBAL ERROR]", err);

  if (err.type === "entity.too.large") {
    return res.status(413).json({ message: "Payload terlalu besar" });
  }

  res.status(500).json({ message: "Internal server error" });
});

// Routes
const userRoutes = require("./src/routes/userRoute");
const testingRoute = require("./src/routes/testingRoute");
const adminLaporanRoute = require("./src/routes/adminLaporanRoute");
const mobileLaporanCepatRoute = require("./src/routes/mobileLaporanCepatRoute");
const mobileZonaBahayaRoute = require("./src/routes/mobileZonaBahayaRoute");
const communityPublicRoutes = require("./src/routes/comunityPublicRoute");
const communityAdminRoutes = require("./src/routes/adminRoute");
const mobileLaporanKepolisianRoute = require("./src/routes/mobileLaporanKepolisianRoute");
const mobileOfficerFieldReportRoute = require("./src/routes/mobileOfficerFieldReportRoute");
const mobileProfileRoute = require("./src/routes/mobileProfileRoute");





app.use("/api/mobile", mobileLaporanKepolisianRoute);
app.use("/api/mobile/officer", mobileOfficerFieldReportRoute);

// route admin baru
const adminRoute = require("./src/routes/adminRoute");
app.use("/api/users", userRoutes); // prefix: /api/users
app.use("/testing", testingRoute); // prefix: /testing
app.use("/api/admin", adminRoute); // prefix: /api/admin
app.use("/api/admin", adminUserRoute);


app.use("/api/admin", adminLaporanRoute);
app.use("/api/mobile", mobileLaporanCepatRoute);
app.use("/api/mobile", mobileProfileRoute);
app.use("/api/mobile", mobileZonaBahayaRoute);
app.use("/api/mobile", mobilePanicRoute);
app.use("/api/mobile", mobileLaporanKepolisianRoute);
app.use("/api/mobile/officer", mobileOfficerFieldReportRoute);

app.use("/api/public", communityPublicRoutes);
app.use("/api/admin", communityAdminRoutes);

// Root test endpoint 
app.get("/", (req, res) => {
  res.send("API running successfully");
});


// io.use((socket, next) => {
//   try {
//     const token =
//       socket.handshake.auth?.token ||
//       socket.handshake.query?.token ||
//       null;

//     if (!token) return next(new Error("Token tidak ditemukan"));

//     const decoded = jwt.verify(token, USER_JWT_SECRET);
//     socket.user = decoded; // { id, username, role, status_verifikasi }

//     next();
//   } catch (e) {
//     next(new Error("Token tidak valid"));
//   }
// });


// io.on("connection", (socket) => {
//   const { id, role } = socket.user || {};

//   console.log("✅ socket connected:", socket.id, "user:", id, "role:", role);

//   // join room
//   if (role === "officer") socket.join(`officer:${id}`);
//   if (role === "masyarakat") socket.join(`citizen:${id}`);

//   console.log("🏠 joined rooms:", Array.from(socket.rooms)); // <- penting

//   socket.emit("socket:ready", { ok: true, id, role });
// });


// biar controller bisa akses io via req.app.get("io")
app.set("io", io);

// io.use((socket, next) => {
//   try {
//     const token = socket.handshake.auth?.token || socket.handshake.query?.token || null;
//     if (!token) return next(new Error("Token tidak ditemukan"));

//     const decoded = jwt.verify(token, USER_JWT_SECRET);
//     socket.user = decoded; // { id, username, role, status_verifikasi }
//     next();
//   } catch (e) {
//     next(new Error("Token tidak valid"));
//   }
// });

// io.on("connection", (socket) => {
//   const { id, role } = socket.user || {};
//   console.log("✅ socket connected:", socket.id, "user:", id, "role:", role);

//   // join room user
//   if (role === "officer") socket.join(`officer:${id}`);
//   if (role === "masyarakat") socket.join(`citizen:${id}`);

//   // ✅ join room komunitas
//   socket.on("community:join", ({ communityId }) => {
//     if (!communityId) return;
//     socket.join(`community:${communityId}`);
//     console.log("🏠 join community room:", `community:${communityId}`);
//   });

//   socket.on("community:leave", ({ communityId }) => {
//     if (!communityId) return;
//     socket.leave(`community:${communityId}`);
//     console.log("🚪 leave community room:", `community:${communityId}`);
//   });

//   socket.emit("socket:ready", { ok: true, id, role });
// });

// io.on("connection", (socket) => {
//   // citizen join room panic
//   socket.on("panic:join", ({ panicId }) => {
//     if (!panicId) return;
//     socket.join(`panic:${panicId}`);
//   });

//   socket.on("panic:leave", ({ panicId }) => {
//     if (!panicId) return;
//     socket.leave(`panic:${panicId}`);
//   });

//   // officer kirim lokasi
//   socket.on("officer:location", (payload) => {
//     const { panicId, lat, lng, speed, updatedAt } = payload || {};
//     if (!panicId || lat == null || lng == null) return;

//     // broadcast ke citizen yang follow panic ini
//     io.to(`panic:${panicId}`).emit("officer:location", {
//       panicId,
//       lat,
//       lng,
//       speed: speed ?? null,
//       updatedAt: updatedAt ?? new Date().toISOString(),
//     });
//   });
// });

io.use((socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.query?.token ||
      null;

    if (!token) return next(new Error("Token tidak ditemukan"));

    const decoded = jwt.verify(token, USER_JWT_SECRET);
    socket.user = decoded; // { id, username, role, status_verifikasi }

    next();
  } catch (e) {
    next(new Error("Token tidak valid"));
  }
});

io.on("connection", (socket) => {
  const { id, role } = socket.user || {};
  console.log("✅ socket connected:", socket.id, "user:", id, "role:", role);

  // join room user
  if (role === "officer") socket.join(`officer:${id}`);
  if (role === "masyarakat") socket.join(`citizen:${id}`);

  console.log("🏠 joined rooms:", Array.from(socket.rooms));
  socket.emit("socket:ready", { ok: true, id, role });

  // ===== COMMUNITY =====
  socket.on("community:join", ({ communityId }) => {
    if (!communityId) return;
    socket.join(`community:${communityId}`);
    console.log("🏠 join community:", `community:${communityId}`);
  });

  socket.on("community:leave", ({ communityId }) => {
    if (!communityId) return;
    socket.leave(`community:${communityId}`);
    console.log("🚪 leave community:", `community:${communityId}`);
  });

  // ===== PANIC ROOMS =====
  socket.on("panic:join", ({ panicId }) => {
    if (!panicId) return;
    socket.join(`panic:${panicId}`);
    console.log("🚨 join panic:", `panic:${panicId}`, "socket:", socket.id);
  });

  socket.on("panic:leave", ({ panicId }) => {
    if (!panicId) return;
    socket.leave(`panic:${panicId}`);
    console.log("🚪 leave panic:", `panic:${panicId}`, "socket:", socket.id);
  });

  // ===== OFFICER LOCATION REALTIME =====
  socket.on("officer:location", (payload) => {
    const { panicId, lat, lng, speed, updatedAt } = payload || {};
    if (!panicId || lat == null || lng == null) return;

    console.log("📍 officer:location IN =>", { panicId, lat, lng });

    io.to(`panic:${panicId}`).emit("officer:location", {
      panicId,
      lat,
      lng,
      speed: speed ?? null,
      updatedAt: updatedAt ?? new Date().toISOString(),
    });
  });

  socket.on("disconnect", (reason) => {
    console.log("🧯 socket disconnected:", socket.id, reason);
  });
});


// Start server
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});