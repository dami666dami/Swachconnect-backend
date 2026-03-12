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

router.get(
  "/my",
  protect,
  getUserComplaints
);



/* --------------------------------------------------
   GET ALL COMPLAINTS (ADMIN)
---------------------------------------------------*/

router.get(
  "/all",
  protect,
  getAllComplaints
);



/* --------------------------------------------------
   DELETE COMPLAINT
---------------------------------------------------*/

router.delete(
  "/:id",
  protect,
  deleteComplaint
);



/* --------------------------------------------------
   MANUAL ESCALATION
---------------------------------------------------*/

router.put(
  "/escalate/:id",
  protect,
  escalateComplaint
);



/* --------------------------------------------------
   EMAIL ESCALATE ACTION
---------------------------------------------------*/

router.get(
  "/email/escalate/:token",
  emailEscalateComplaint
);



/* --------------------------------------------------
   EMAIL WAIT ACTION
---------------------------------------------------*/

router.get(
  "/email/wait/:token",
  emailWaitComplaint
);



module.exports = router;