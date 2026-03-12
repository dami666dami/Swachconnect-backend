const express = require("express");
const router = express.Router();

const protect = require("../middleware/authMiddleware");

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
  next();
}, login);


/* Get current user */
router.get("/me", protect, getMe);


/* Forgot password - send OTP */
router.post("/forgot-password", forgotPassword);


/* Verify OTP */
router.post("/verify-otp", verifyOtp);


/* Reset password */
router.post("/reset-password", resetPassword);


module.exports = router;