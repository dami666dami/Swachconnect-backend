const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");
const morgan = require("morgan");
const fs = require("fs");

const connectDB = require("./config/db");

// Load environment variables
dotenv.config();

console.log("📦 ENV LOADED");
console.log("📧 EMAIL_USER:", process.env.EMAIL_USER || "NOT SET");
console.log("🔐 EMAIL_PASS:", process.env.EMAIL_PASS ? "SET" : "NOT SET");

// Connect database
connectDB();

// Register escalation cron
require("./cron/escalationJob");
console.log("⏳ Escalation cron registered");

const app = express();

/* --------------------------------------------------
   Ensure uploads folder exists (important for Render)
---------------------------------------------------*/

const uploadsPath = path.join(__dirname, "uploads");

if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
  console.log("📁 uploads folder created");
}

/* --------------------------------------------------
   Middleware
---------------------------------------------------*/

app.set("trust proxy", 1);

app.use(morgan("dev"));

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

/* --------------------------------------------------
   Static file access for uploaded images
---------------------------------------------------*/

app.use("/uploads", express.static(uploadsPath));

/* --------------------------------------------------
   Routes
---------------------------------------------------*/

app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/auth", require("./routes/passwordRoutes"));
app.use("/api/complaints", require("./routes/complaintRoutes"));
app.use("/api/users", require("./routes/userRoutes"));
/* --------------------------------------------------
   Root route
---------------------------------------------------*/

app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "SwachConnect API is running",
    serverTime: new Date().toISOString(),
  });
});

/* --------------------------------------------------
   Health check
---------------------------------------------------*/

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "OK",
    uptime: process.uptime(),
    memory: process.memoryUsage().rss,
    envLoaded: !!process.env.EMAIL_USER,
  });
});

/* --------------------------------------------------
   404 handler
---------------------------------------------------*/

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

/* --------------------------------------------------
   Error handler
---------------------------------------------------*/

app.use((err, req, res, next) => {
  console.error("❌ Server Error:", err);

  if (err.name === "MulterError") {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  if (err.message && err.message.includes("image")) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  if (err.type === "entity.parse.failed") {
    return res.status(400).json({
      success: false,
      message: "Invalid JSON body",
    });
  }

  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Internal Server Error",
  });
});

/* --------------------------------------------------
   Start server
---------------------------------------------------*/

const PORT = process.env.PORT || 4000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 SwachConnect API running on http://0.0.0.0:${PORT}`);
});