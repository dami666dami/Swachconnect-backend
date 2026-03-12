const Complaint = require("../models/Complaint");
const crypto = require("crypto");
const sendEmail = require("../utils/sendEmail");

const authorityLevels = [
  "Municipality / Panchayat",
  "Ward Councillor",
  "District Health Officer",
  "Pollution Control Board",
  "District Collector",
  "State Health Department",
  "National Authorities",
];

/* --------------------------------------------------
   Deadline (currently 2 minutes for testing)
---------------------------------------------------*/

const getDeadlineByAuthority = () => {
  return new Date(Date.now() + 2 * 60 * 1000);
};

/* --------------------------------------------------
   Distance calculation
---------------------------------------------------*/

const getDistanceInMeters = (lat1, lng1, lat2, lng2) => {
  const R = 6371e3;
  const toRad = (x) => (x * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) ** 2;

  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

/* --------------------------------------------------
   Create Complaint
---------------------------------------------------*/

exports.createComplaint = async (req, res) => {
  try {
    const user = req.user;
    const { description, lat, lng, isAnonymous } = req.body;

    if (!description || description.trim().length < 5) {
      return res.status(400).json({
        message: "Invalid complaint description",
      });
    }

    const anonymous =
      isAnonymous === true ||
      isAnonymous === "true" ||
      isAnonymous === 1 ||
      isAnonymous === "1";

    const latitude =
      lat !== undefined && lat !== "" && !isNaN(lat)
        ? Number(lat)
        : null;

    const longitude =
      lng !== undefined && lng !== "" && !isNaN(lng)
        ? Number(lng)
        : null;

    /* ---------------------------
       Image Handling
    ---------------------------*/

    const images = Array.isArray(req.files)
      ? req.files.map((f) => `/uploads/${f.filename}`)
      : [];

    console.log("📸 Uploaded Images:", images);

    /* ---------------------------
       Duplicate detection
    ---------------------------*/

    let duplicateWarning = null;

    if (latitude && longitude) {
      const recentTime = new Date(
        Date.now() - 7 * 24 * 60 * 60 * 1000
      );

      const recentComplaints = await Complaint.find({
        createdAt: { $gte: recentTime },
        status: { $ne: "Resolved" },
        "location.lat": { $ne: null },
        "location.lng": { $ne: null },
      });

      for (const c of recentComplaints) {
        const distance = getDistanceInMeters(
          latitude,
          longitude,
          c.location.lat,
          c.location.lng
        );

        if (distance <= 100) {
          duplicateWarning =
            "A similar complaint was reported recently near this location.";
          break;
        }
      }
    }

    /* ---------------------------
       Email action token
    ---------------------------*/

    const emailActionToken =
      crypto.randomBytes(32).toString("hex");

    const emailActionExpires =
      Date.now() + 2 * 60 * 60 * 1000;

    /* ---------------------------
       Create complaint
    ---------------------------*/

    const complaint = await Complaint.create({
      userId: user._id,
      reporterName: anonymous ? null : user.name,
      reporterEmail: user.email,
      description: description.trim(),
      images,
      location: {
        lat: latitude,
        lng: longitude,
      },
      isAnonymous: anonymous,
      status: "Pending",
      progress: 10,
      assignedAuthority: authorityLevels[0],
      escalationLevel: 0,
      escalationEmailSent: false,
      finalEscalationReached: false,
      socialEscalated: false,
      deadline: getDeadlineByAuthority(),
      emailActionToken,
      emailActionExpires,
    });

    /* ---------------------------
       Send confirmation email
    ---------------------------*/

    try {
      const emailHtml = anonymous
        ? `
          <h2>Complaint Registered</h2>
          <p>Your <b>anonymous complaint</b> has been registered.</p>
          <p><b>Authority:</b> ${complaint.assignedAuthority}</p>
          <p>— SwachConnect Team</p>
        `
        : `
          <h2>Complaint Registered</h2>
          <p>Dear ${user.name},</p>
          <p>Your complaint has been registered successfully.</p>
          <p><b>Authority:</b> ${complaint.assignedAuthority}</p>
          <p>— SwachConnect Team</p>
        `;

      await sendEmail({
        to: complaint.reporterEmail,
        subject: "Complaint Registered – SwachConnect",
        html: emailHtml,
      });

      console.log("📧 Registration email sent");
    } catch (emailError) {
      console.error(
        "⚠ Email sending failed:",
        emailError.message
      );
    }

    res.status(201).json({
      success: true,
      data: complaint,
      duplicateWarning,
    });
  } catch (err) {
    console.error("CREATE COMPLAINT ERROR:", err);
    res.status(500).json({
      message: "Complaint submission failed",
    });
  }
};

/* --------------------------------------------------
   Get user complaints
---------------------------------------------------*/

exports.getUserComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.find({
      userId: req.user._id,
    }).sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch {
    res.status(500).json({
      message: "Failed to fetch complaints",
    });
  }
};

/* --------------------------------------------------
   Get all complaints
---------------------------------------------------*/

exports.getAllComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.find()
      .populate("userId", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch {
    res.status(500).json({
      message: "Failed to fetch complaints",
    });
  }
};

/* --------------------------------------------------
   Delete complaint
---------------------------------------------------*/

exports.deleteComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!complaint)
      return res.status(404).json({
        message: "Complaint not found",
      });

    await complaint.deleteOne();

    res.status(200).json({
      message: "Complaint deleted successfully",
    });
  } catch {
    res.status(500).json({
      message: "Delete failed",
    });
  }
};

/* --------------------------------------------------
   Escalate complaint
---------------------------------------------------*/

exports.escalateComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findById(req.params.id);

    if (!complaint)
      return res.status(404).json({
        message: "Complaint not found",
      });

    if (new Date() < complaint.deadline)
      return res.status(400).json({
        message: "Deadline not passed yet",
      });

    if (complaint.escalationLevel >= authorityLevels.length - 1) {
      return res.status(400).json({
        message: "Final escalation reached",
      });
    }

    complaint.escalationLevel += 1;
    complaint.assignedAuthority =
      authorityLevels[complaint.escalationLevel];

    complaint.status = "Escalated";
    complaint.deadline = getDeadlineByAuthority();
    complaint.lastEscalatedAt = new Date();

    if (
      complaint.escalationLevel >=
      authorityLevels.length - 1
    ) {
      complaint.finalEscalationReached = true;
      complaint.socialEscalated = true;
    }

    await complaint.save();

    try {
      await sendEmail({
        to: complaint.reporterEmail,
        subject: "Complaint Escalated – SwachConnect",
        html: `
          <h2>Complaint Escalated</h2>
          <p>Your complaint has been escalated.</p>
          <p><b>Authority:</b> ${complaint.assignedAuthority}</p>
          <p>— SwachConnect Team</p>
        `,
      });
    } catch (emailError) {
      console.error(
        "Escalation email failed:",
        emailError.message
      );
    }

    res.status(200).json(complaint);
  } catch {
    res.status(500).json({
      message: "Escalation failed",
    });
  }
};