const express = require("express");
const router = express.Router();

const upload = require("../middleware/upload");
const protect = require("../middleware/authMiddleware");

const complaintController = require("../controllers/complaintController");

const {
  createComplaint,
  getUserComplaints,
  getAllComplaints,
  deleteComplaint,
  escalateComplaint,
  emailEscalateComplaint,
  emailWaitComplaint,
} = complaintController;

/* --------------------------------------------------
   Validate controller exports (prevents server crash)
---------------------------------------------------*/

const requiredFunctions = [
  "createComplaint",
  "getUserComplaints",
  "getAllComplaints",
  "deleteComplaint",
  "escalateComplaint",
  "emailEscalateComplaint",
  "emailWaitComplaint",
];

requiredFunctions.forEach((fn) => {
  if (typeof complaintController[fn] !== "function") {
    console.error(`❌ Complaint routes: Missing controller export → ${fn}`);
    throw new Error(`Complaint controller export missing: ${fn}`);
  }
});

/* --------------------------------------------------
   CREATE COMPLAINT
---------------------------------------------------*/

router.post(
  "/",
  protect,
  upload.array("image", 5),

  (req, res, next) => {
    console.log("📨 Complaint upload request received");

    if (req.files && req.files.length > 0) {
      console.log(
        "📸 Uploaded files:",
        req.files.map((f) => f.filename)
      );
    } else {
      console.log("⚠ No images uploaded");
    }

    next();
  },

  createComplaint
);

/* --------------------------------------------------
   GET USER COMPLAINTS
---------------------------------------------------*/

router.get("/my", protect, getUserComplaints);

/* --------------------------------------------------
   GET ALL COMPLAINTS (ADMIN)
---------------------------------------------------*/

router.get("/all", protect, getAllComplaints);

/* --------------------------------------------------
   DELETE COMPLAINT
---------------------------------------------------*/

router.delete("/:id", protect, deleteComplaint);

/* --------------------------------------------------
   MANUAL ESCALATION
---------------------------------------------------*/

router.put("/escalate/:id", protect, escalateComplaint);

/* --------------------------------------------------
   EMAIL ESCALATE ACTION
---------------------------------------------------*/

router.get("/email/escalate/:token", emailEscalateComplaint);

/* --------------------------------------------------
   EMAIL WAIT ACTION
---------------------------------------------------*/

router.get("/email/wait/:token", emailWaitComplaint);

/* --------------------------------------------------
   ✅ FEEDBACK SUBMISSION (FIXED)
---------------------------------------------------*/

router.put(
  "/feedback/:id",
  protect,
  complaintController.submitFeedback
);

/* --------------------------------------------------
   ✅ NEW: AUTHORITY REMARK (IMPORTANT FEATURE)
---------------------------------------------------*/

router.put("/add-remark/:id", protect, async (req, res) => {
  try {
    const { remark } = req.body;

    if (!remark || remark.trim() === "") {
      return res.status(400).json({ error: "Remark is required" });
    }

    const updatedComplaint = await require("../models/Complaint").findByIdAndUpdate(
      req.params.id,
      { remark },
      { new: true }
    );

    if (!updatedComplaint) {
      return res.status(404).json({ error: "Complaint not found" });
    }

    res.json({
      message: "✅ Remark added successfully",
      complaint: updatedComplaint,
    });
  } catch (err) {
    console.error("❌ Add Remark Error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;