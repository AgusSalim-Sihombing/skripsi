// scripts/hashAdmin.js
const bcrypt = require("bcryptjs");

(async () => {
  const password = "admin123"; // password yang mau dipakai login
  const hash = await bcrypt.hash(password, 10);
  console.log("Hash password admin:", hash);
})();
