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
   Validate controller exports
---------------------------------------------------*/

if (
  !createComplaint ||
  !getUserComplaints ||
  !getAllComplaints ||
  !deleteComplaint ||
  !escalateComplaint ||
  !emailEscalateComplaint ||
  !emailWaitComplaint
) {
  console.error("❌ Complaint routes: Missing controller exports");
  throw new Error("Complaint controller exports mismatch");
}

/* --------------------------------------------------
   Create Complaint (with image upload)
---------------------------------------------------*/

router.post(
  "/",
  protect,
  upload.array("image", 5), // allow up to 5 images
  (req, res, next) => {
    console.log("📨 Complaint upload request received");

    if (req.files && req.files.length > 0) {
      console.log(
        "📸 Uploaded files:",
        req.files.map((f) => f.filename)
      );
    }

    next();
  },
  createComplaint
);

/* --------------------------------------------------
   Get logged-in user's complaints
---------------------------------------------------*/

router.get(
  "/my",
  protect,
  getUserComplaints
);

/* --------------------------------------------------
   Get all complaints (admin)
---------------------------------------------------*/

router.get(
  "/all",
  protect,
  getAllComplaints
);

/* --------------------------------------------------
   Delete complaint
---------------------------------------------------*/

router.delete(
  "/:id",
  protect,
  deleteComplaint
);

/* --------------------------------------------------
   Escalate complaint manually
---------------------------------------------------*/

router.put(
  "/escalate/:id",
  protect,
  escalateComplaint
);

/* --------------------------------------------------
   Email escalation confirmation
---------------------------------------------------*/

router.get(
  "/email/escalate/:token",
  emailEscalateComplaint
);

/* --------------------------------------------------
   Email waiting confirmation
---------------------------------------------------*/

router.get(
  "/email/wait/:token",
  emailWaitComplaint
);

module.exports = router;