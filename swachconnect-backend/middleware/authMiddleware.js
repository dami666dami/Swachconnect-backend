const jwt = require("jsonwebtoken");
const User = require("../models/User");

/* --------------------------------------------------
   Authentication Middleware
---------------------------------------------------*/

const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Authorization token missing",
      });
    }

    const token = authHeader.split(" ")[1]?.trim();

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Invalid authorization format",
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error("❌ JWT_SECRET not configured");
      return res.status(500).json({
        success: false,
        message: "Server configuration error",
      });
    }

    let decoded;

    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      console.warn("⚠ Invalid or expired token:", err.message);

      let message = "Token expired or invalid";

      if (err.name === "TokenExpiredError") {
        message = "Token expired";
      } else if (err.name === "JsonWebTokenError") {
        message = "Invalid token signature";
      }

      return res.status(401).json({
        success: false,
        message,
      });
    }

    const user = await User.findById(decoded.id).select("-password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User account not found",
      });
    }

    /* --------------------------------------------------
       Attach user to request
    ---------------------------------------------------*/

    req.user = user;

    next();

  } catch (error) {
    console.error("❌ AUTH MIDDLEWARE ERROR:", error);

    return res.status(401).json({
      success: false,
      message: "Authentication failed",
    });
  }
};

/* --------------------------------------------------
   ADMIN ONLY MIDDLEWARE (NEW)
---------------------------------------------------*/

const adminOnly = (req, res, next) => {
  try {

    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Not authenticated",
      });
    }

    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin only",
      });
    }

    next();

  } catch (error) {
    console.error("❌ ADMIN MIDDLEWARE ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Server error in admin check",
    });
  }
};

module.exports = { protect, adminOnly };