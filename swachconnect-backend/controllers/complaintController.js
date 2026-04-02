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

const DEMO_MODE = process.env.DEMO_MODE === "true";

const getDeadlineByAuthority = (authority = "Municipality / Panchayat") => {

  if (DEMO_MODE) {
    return new Date(Date.now() + 5 * 60 * 1000);
  }

  if (authority === "Municipality / Panchayat") {
    return new Date(Date.now() + 24 * 60 * 60 * 1000); 
  }

  return new Date(Date.now() + 48 * 60 * 60 * 1000); 
};

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
   CREATE COMPLAINT
---------------------------------------------------*/

exports.createComplaint = async (req, res) => {
  try {
    const user = req.user;
    const { description, lat, lng, isAnonymous } = req.body;

    if (!description || description.trim().length < 5) {
      return res.status(400).json({
        message: "Invalid complaint description"
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

    const images = Array.isArray(req.files)
      ? req.files.map((f) => `/uploads/${f.filename}`)
      : [];

    let duplicateWarning = null;

    if (latitude && longitude) {
      const recentTime = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const recentComplaints = await Complaint.find({
        createdAt: { $gte: recentTime },
        status: { $ne: "Resolved" },
        "location.lat": { $ne: null },
        "location.lng": { $ne: null }
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

    const emailActionToken = crypto.randomBytes(32).toString("hex");
    const emailActionExpires = Date.now() + 2 * 60 * 60 * 1000;

    const count = await Complaint.countDocuments();
    const complaintId = `SC-${1000 + count + 1}`;

    const complaint = await Complaint.create({
      complaintId,
      userId: user._id,
      reporterName: anonymous ? null : user.name,
      reporterEmail: user.email,
      description: description.trim(),
      images,
      location: { lat: latitude, lng: longitude },
      isAnonymous: anonymous,
      status: "Pending",
      progress: 10,
      assignedAuthority: authorityLevels[0],
      escalationLevel: 0,
      escalationEmailSent: false,
      finalEscalationReached: false,
      socialEscalated: false,
      deadline: getDeadlineByAuthority(authorityLevels[0]),
      emailActionToken,
      emailActionExpires
    });

    console.log(" Complaint saved:", complaint._id);

try {
  await sendEmail({
    to: complaint.reporterEmail,
    subject: `Complaint Registered (${complaintId}) – SwachConnect`,
    html: `
    <div style="font-family: Arial; padding:20px;">
      <h2 style="color:#2E7D32;">Complaint Registered ✅</h2>
      <p>Your complaint has been successfully submitted.</p>
      <hr/>
      <p><strong>Complaint ID:</strong> ${complaintId}</p>
      <p><strong>Description:</strong> ${complaint.description}</p>
      <p><strong>Location:</strong> ${latitude || "-"}, ${longitude || "-"}</p>
      <p><strong>Status:</strong> Pending</p>
      <hr/>
      <p><strong>Assigned Authority:</strong> ${complaint.assignedAuthority}</p>
      <p><strong>Expected Resolution Time:</strong> ${
        DEMO_MODE
          ? "5 minutes"
          : complaint.assignedAuthority === "Municipality / Panchayat"
          ? "24 hours"
          : "48 hours"
      }</p>
      <p style="color:#d32f2f;">
        ⚠ If not resolved within the time, your complaint will be automatically escalated to higher authorities.
      </p>
      ${
        images.length > 0
          ? `<p><strong>Attached Image:</strong></p>
             <img src="${process.env.BASE_URL}${images[0]}" width="200"/>`
          : ""
      }
      <hr/>
      <p>Thank you for using <strong>SwachConnect</strong>.</p>
    </div>
    `
  });
  console.log("📧 Email sent");
} catch (emailError) {
  console.log("⚠ Email failed but complaint saved:", emailError.message);
}

    res.status(201).json({
      success: true,
      data: complaint,
      duplicateWarning
    });

  } catch (err) {
    console.error("❌ Complaint error:", err);
    res.status(500).json({
      message: "Complaint submission failed"
    });
  }
};

/* --------------------------------------------------
   🔥 NEW: SOCIAL ESCALATION TRACKING
---------------------------------------------------*/

exports.socialEscalate = async (req, res) => {
  try {
    const { message } = req.body;

    const complaint = await Complaint.findById(req.params.id);

    if (!complaint) {
      return res.status(404).json({ message: "Complaint not found" });
    }

    complaint.socialEscalated = true;
    complaint.socialPostedAt = new Date();

    if (message) {
      complaint.socialPostContent = message;
    }

    await complaint.save();

    res.json({
      success: true,
      message: "Social escalation recorded",
      complaint,
    });

  } catch (err) {
    res.status(500).json({
      message: "Social escalation failed",
    });
  }
};

/* --------------------------------------------------
   GET USER COMPLAINTS
---------------------------------------------------*/

exports.getUserComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.find({
      userId: req.user._id
    }).sort({ createdAt: -1 });

    res.json(complaints);
  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch complaints"
    });
  }
};

/* --------------------------------------------------
   GET ALL COMPLAINTS
---------------------------------------------------*/

exports.getAllComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.find()
      .populate("userId", "name email")
      .sort({ createdAt: -1 });

    res.json(complaints);
  } catch (err) {
    res.status(500).json({
      message: "Failed to fetch complaints"
    });
  }
};


exports.deleteComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!complaint) {
      return res.status(404).json({
        message: "Complaint not found"
      });
    }

    await complaint.deleteOne();

    res.json({
      message: "Complaint deleted successfully"
    });

  } catch (err) {
    res.status(500).json({
      message: "Delete failed"
    });
  }
};

/* --------------------------------------------------
   ESCALATE COMPLAINT
---------------------------------------------------*/

exports.escalateComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findById(req.params.id);

    if (!complaint) {
      return res.status(404).json({ message: "Complaint not found" });
    }

    complaint.escalationLevel += 1;
    complaint.assignedAuthority =
      authorityLevels[complaint.escalationLevel];
    complaint.status = "Escalated";
    complaint.deadline = getDeadlineByAuthority(complaint.assignedAuthority);

    await complaint.save();

    res.json(complaint);

  } catch (err) {
    res.status(500).json({
      message: "Escalation failed"
    });
  }
};

/* --------------------------------------------------
   EMAIL ESCALATE LINK
---------------------------------------------------*/

exports.emailEscalateComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      emailActionToken: req.params.token,
      emailActionExpires: { $gt: Date.now() }
    });

    if (!complaint) {
      return res.send(`<h2>❌ Invalid or expired link</h2>`);
    }

    complaint.escalationLevel += 1;
    complaint.assignedAuthority =
      authorityLevels[complaint.escalationLevel];
    complaint.status = "Escalated";
    complaint.deadline = getDeadlineByAuthority(complaint.assignedAuthority);
    complaint.emailActionToken = null;
    complaint.emailActionExpires = null;

    await complaint.save();

    res.send(`
      <html>
      <head>
        <title>Escalation Successful</title>
        <style>
          body {
            font-family: Arial;
            text-align: center;
            padding: 50px;
            background: #f4f6f8;
          }
          .box {
            background: white;
            padding: 30px;
            border-radius: 12px;
            display: inline-block;
            box-shadow: 0 0 15px rgba(0,0,0,0.1);
          }
          h2 { color: green; }
          h3 { color: #1976d2; }
        </style>
      </head>
      <body>
        <div class="box">
          <h2>✅ Complaint Escalated Successfully</h2>
          <p>Your complaint is now escalated to:</p>
          <h3>${complaint.assignedAuthority}</h3>
          <p>Higher authority will take action soon.</p>
        </div>
      </body>
      </html>
    `);

  } catch (err) {
    res.send("<h2>❌ Escalation failed</h2>");
  }
};

/* --------------------------------------------------
   EMAIL WAIT LINK
---------------------------------------------------*/

exports.emailWaitComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      emailActionToken: req.params.token
    });

    if (!complaint) {
      return res.send("<h2>Invalid request</h2>");
    }

    complaint.status = "In Progress";
    complaint.emailActionToken = null;
    complaint.emailActionExpires = null;

    await complaint.save();

    res.send(`
      <html>
      <body style="text-align:center;padding:50px;">
        <h2>⏳ You chose to wait</h2>
        <p>The authority still has time to resolve your complaint.</p>
      </body>
      </html>
    `);

  } catch (err) {
    res.send("Failed");
  }
};

/* --------------------------------------------------
   FEEDBACK
---------------------------------------------------*/

exports.submitFeedback = async (req, res) => {
  try {
    const { rating, feedback } = req.body;

    /* 🔥 VALIDATION */
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: "Rating must be between 1 and 5",
      });
    }

    const complaint = await Complaint.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found",
      });
    }

    if (complaint.status !== "Resolved") {
      return res.status(400).json({
        success: false,
        message: "Feedback allowed only after resolution",
      });
    }

    if (complaint.feedbackGiven) {
      return res.status(400).json({
        success: false,
        message: "Feedback already submitted",
      });
    }

    complaint.feedbackGiven = true;
    complaint.feedbackRating = rating;
    complaint.feedbackMessage = feedback || null;

    await complaint.save();

    res.json({
      success: true,
      message: "Feedback submitted successfully",
      complaint,
    });

  } catch (err) {
    console.error("❌ Feedback Error:", err.message);

    res.status(500).json({
      success: false,
      message: "Feedback submission failed",
    });
  }
};

/* --------------------------------------------------
   ADD REMARK
---------------------------------------------------*/

exports.addRemark = async (req, res) => {
  try {
    const { remark } = req.body;

    if (!remark || remark.trim() === "") {
      return res.status(400).json({ message: "Remark required" });
    }

    const complaint = await Complaint.findById(req.params.id);

    if (!complaint) {
      return res.status(404).json({ message: "Complaint not found" });
    }

    complaint.remark = remark;

    await complaint.save();

    res.json({
      success: true,
      message: "Remark added successfully",
      complaint,
    });

  } catch (err) {
    res.status(500).json({
      message: "Failed to add remark",
    });
  }
};