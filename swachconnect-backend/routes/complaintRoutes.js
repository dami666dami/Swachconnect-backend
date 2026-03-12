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

if (
  !createComplaint ||
  !getUserComplaints ||
  !getAllComplaints ||
  !deleteComplaint ||
  !escalateComplaint ||
  !emailEscalateComplaint ||
  !emailWaitComplaint
) {
  console.error(" Complaint routes: One or more handlers are undefined");
  throw new Error("Complaint controller exports mismatch");
}

router.post(
  "/",
  protect,
  upload.array("image", 5),
  createComplaint
);

router.get(
  "/my",
  protect,
  getUserComplaints
);

router.get(
  "/all",
  protect,
  getAllComplaints
);

router.delete(
  "/:id",
  protect,
  deleteComplaint
);

router.put(
  "/escalate/:id",
  protect,
  escalateComplaint
);

router.get(
  "/email/escalate/:token",
  emailEscalateComplaint
);

router.get(
  "/email/wait/:token",
  emailWaitComplaint
);

module.exports = router;
