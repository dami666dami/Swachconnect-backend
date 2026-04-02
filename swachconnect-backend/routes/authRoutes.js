const express = require("express");
const router = express.Router();

const { protect } = require("../middleware/authMiddleware"); // ✅ FIXED

const authController = require("../controllers/authController");

const {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
  getMe,
} = authController;

/* --------------------------------------------------
   Validate controller exports
---------------------------------------------------*/

const requiredFunctions = [
  "register",
  "login",
  "forgotPassword",
  "verifyOtp",
  "resetPassword",
  "getMe",
];

requiredFunctions.forEach((fn) => {
  if (typeof authController[fn] !== "function") {
    console.error(`❌ Auth routes: Missing controller export → ${fn}`);
    throw new Error(`Auth controller export missing: ${fn}`);
  }
});

/* --------------------------------------------------
   AUTH ROUTES
---------------------------------------------------*/

/* Register new user */
router.post("/register", (req, res, next) => {
  console.log("📥 Register request received");
  next();
}, register);


/* Login user */
router.post("/login", (req, res, next) => {
  console.log("🔑 Login request received");

  /* 🔥 DEBUG TOKEN ISSUE */
  console.log("📦 Request Body:", req.body);

  next();
}, login);


/* Get current user */
router.get("/me", protect, (req, res, next) => {
  console.log("👤 Fetching current user:", req.user?._id);
  next();
}, getMe);


/* Forgot password - send OTP */
router.post("/forgot-password", (req, res, next) => {
  console.log("📧 Forgot password request:", req.body?.email);
  next();
}, forgotPassword);


/* Verify OTP */
router.post("/verify-otp", (req, res, next) => {
  console.log("🔐 OTP verification request");
  next();
}, verifyOtp);


/* Reset password */
router.post("/reset-password", (req, res, next) => {
  console.log("🔁 Reset password request");
  next();
}, resetPassword);


module.exports = router;