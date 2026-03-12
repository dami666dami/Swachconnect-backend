const express = require("express");
const router = express.Router();

const {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
  getMe,
} = require("../controllers/authController");

const protect = require("../middleware/authMiddleware");

router.post("/register", register);

router.post("/login", login);

router.get("/me", protect, getMe);

router.post("/forgot-password", forgotPassword);

router.post("/verify-otp", verifyOtp);

router.post("/reset-password", resetPassword);

module.exports = router;
