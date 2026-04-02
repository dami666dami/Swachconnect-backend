const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const sendEmail = require("../utils/sendEmail");

/* ================= JWT TOKEN ================= */

const generateToken = (id) => {

  // 🔥 FIX: ensure JWT_SECRET exists
  if (!process.env.JWT_SECRET) {
    console.error("❌ JWT_SECRET not defined");
    throw new Error("JWT_SECRET missing");
  }

  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });
};



/* ================= REGISTER ================= */

exports.register = async (req, res) => {
  try {

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
    }

    const normalizedEmail = email.toLowerCase().trim();

    const exists = await User.findOne({ email: normalizedEmail });

    if (exists) {
      return res.status(400).json({
        success: false,
        message: "Email already exists",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: "user",
    });

    /* OPTIONAL WELCOME EMAIL */

    try {

      await sendEmail({
        to: user.email,
        subject: "Welcome to SwachConnect 🚀",
        html: `
        <div style="font-family: Arial; padding:20px;">
          
          <h2 style="color:#2E7D32;">Welcome to SwachConnect, ${user.name}! 🎉</h2>

          <p>Your account has been successfully created.</p>

          <hr/>

          <h3>🌍 What is SwachConnect?</h3>
          <p>
            SwachConnect is a smart civic complaint platform designed to help citizens
            report issues like waste management, sanitation problems, and environmental concerns.
          </p>

          <h3>🚀 What You Can Do</h3>
          <ul>
            <li>📸 Upload complaints with images</li>
            <li>📍 Track complaint status in real-time</li>
            <li>⚡ Automatic escalation to higher authorities</li>
            <li>📢 Social escalation for public awareness</li>
          </ul>

          <hr/>

          <h3>📌 How It Works</h3>
          <p>
            Once you submit a complaint, it is assigned to the nearest authority.
            If not resolved within the deadline, it will be automatically escalated
            to higher authorities.
          </p>

          <p style="color:#d32f2f;">
            ⚠ This ensures accountability and faster resolution.
          </p>

          <hr/>

          <p>
            Start reporting issues and make your city cleaner with <b>SwachConnect</b>.
          </p>

          <p><b>SwachConnect Team</b></p>

        </div>
        `,
      });

      console.log("📧 Welcome email sent");

    } catch (e) {

      console.log("⚠ Email failed but user registered:", e.message);

    }

    res.status(201).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });

  } catch (err) {

    console.error("REGISTER ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Server error during registration",
    });

  }
};

/* ================= LOGIN ================= */

exports.login = async (req, res) => {
  try {

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    const normalizedEmail = email.toLowerCase().trim();

    const user = await User.findOne({ email: normalizedEmail }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }

    res.status(200).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role, 
      },
    });

  } catch (err) {

    console.error("LOGIN ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Server error during login",
    });

  }
};




/* ================= GET CURRENT USER ================= */

exports.getMe = async (req, res) => {

  res.status(200).json({
    success: true,
    user: req.user,
  });

};




/* ================= FORGOT PASSWORD ================= */

exports.forgotPassword = async (req, res) => {
  try {

    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const normalizedEmail = email.toLowerCase().trim();

    const user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "No account found with this email",
      });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetOtp = otp;
    user.otpExpiry = Date.now() + 10 * 60 * 1000;
    user.otpVerified = false;

    await user.save();

    try {

      await sendEmail({
        to: user.email,
        subject: "SwachConnect – Password Reset OTP",
        html: `
        <p>Dear ${user.name},</p>
        <p>Your OTP for resetting your password is:</p>
        <h2>${otp}</h2>
        <p>This OTP is valid for <b>10 minutes</b>.</p>
        <p><b>SwachConnect Team</b></p>
        `,
      });

    } catch (emailError) {

      console.error("OTP EMAIL ERROR:", emailError.message);

    }

    res.status(200).json({
      success: true,
      message: "OTP sent to email",
    });

  } catch (err) {

    console.error("FORGOT PASSWORD ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Failed to send OTP",
    });

  }
};




/* ================= VERIFY OTP ================= */

exports.verifyOtp = async (req, res) => {
  try {

    const { email, otp } = req.body;

    const user = await User.findOne({
      email: email.toLowerCase().trim(),
    });

    if (
      !user ||
      user.resetOtp !== otp ||
      !user.otpExpiry ||
      user.otpExpiry < Date.now()
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid or expired OTP",
      });
    }

    user.otpVerified = true;

    await user.save();

    res.status(200).json({
      success: true,
      message: "OTP verified successfully",
    });

  } catch (err) {

    console.error("VERIFY OTP ERROR:", err);

    res.status(500).json({
      success: false,
      message: "OTP verification failed",
    });

  }
};




/* ================= RESET PASSWORD ================= */

exports.resetPassword = async (req, res) => {
  try {

    const { email, newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase().trim(),
    });

    if (!user || !user.otpVerified) {
      return res.status(400).json({
        success: false,
        message: "OTP verification required",
      });
    }

    user.password = await bcrypt.hash(newPassword, 10);

    user.resetOtp = null;
    user.otpExpiry = null;
    user.otpVerified = false;

    await user.save();

    res.status(200).json({
      success: true,
      message: "Password reset successful",
    });

  } catch (err) {

    console.error("RESET PASSWORD ERROR:", err);

    res.status(500).json({
      success: false,
      message: "Password reset failed",
    });

  }
};