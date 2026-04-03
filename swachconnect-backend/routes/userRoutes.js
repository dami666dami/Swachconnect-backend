const express = require("express");
const router = express.Router();

const { protect, adminOnly } = require("../middleware/authMiddleware");
const User = require("../models/User");

/* GET ALL USERS */
router.get("/all", protect, adminOnly, async (req, res) => {
  try {
    const users = await User.find().select("-password");

    res.json({
      success: true,
      users,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
    });
  }
});

/* UPDATE USER ROLE */
router.put("/:id/role", protect, adminOnly, async (req, res) => {
  try {
    const { role } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    user.role = role;
    await user.save();

    res.json({
      success: true,
      message: "Role updated",
      user,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: "Failed to update role",
    });
  }
});

module.exports = router;