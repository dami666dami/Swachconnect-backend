const cron = require("node-cron");
const mongoose = require("mongoose");
const Complaint = require("../models/Complaint");
const crypto = require("crypto");
const sendEmail = require("../utils/sendEmail");

/* --------------------------------------------------
   Authority levels
---------------------------------------------------*/

const authorities = [
  "Municipality / Panchayat",
  "Ward Councillor",
  "District Health Officer",
  "Pollution Control Board",
  "District Collector",
  "State Health Department",
  "National Authorities",
];

/* --------------------------------------------------
   Email expiry rules
---------------------------------------------------*/

const getEmailExpiryByAuthority = (authority) => {
  if (authority === "Municipality / Panchayat") {
    return Date.now() + 24 * 60 * 60 * 1000;
  }

  return Date.now() + 48 * 60 * 60 * 1000;
};

/* --------------------------------------------------
   Escalation logic
---------------------------------------------------*/

const runEscalationCron = async () => {
  try {
    console.log("⏳ Escalation cron started");

    /* ---------------------------
       Ensure MongoDB connected
    ---------------------------*/

    if (mongoose.connection.readyState !== 1) {
      console.log("⚠ MongoDB not connected. Skipping cycle.");
      return;
    }

    const now = new Date();

    /* ---------------------------
       Find complaints to escalate
    ---------------------------*/

    const complaints = await Complaint.find({
      deadline: { $lt: now },
      status: { $nin: ["Resolved", "Pending Escalation"] },
      escalationEmailSent: false,
      escalationLevel: { $lt: authorities.length - 1 },
    }).populate("userId", "name email");

    if (!complaints.length) {
      console.log("ℹ No complaints eligible for escalation");
      return;
    }

    console.log(`📊 ${complaints.length} complaints ready for escalation`);

    /* ---------------------------
       Process each complaint
    ---------------------------*/

    for (const complaint of complaints) {
      try {
        if (!complaint.userId || !complaint.userId.email) {
          console.warn(
            `⚠ Missing user/email for complaint ${complaint._id}`
          );
          continue;
        }

        const token = crypto.randomBytes(32).toString("hex");

        complaint.emailActionToken = token;
        complaint.emailActionExpires = getEmailExpiryByAuthority(
          complaint.assignedAuthority
        );

        complaint.escalationEmailSent = true;
        complaint.status = "Pending Escalation";

        await complaint.save();

        const escalateUrl = `${process.env.BASE_URL}/api/complaints/email/escalate/${token}`;
        const waitUrl = `${process.env.BASE_URL}/api/complaints/email/wait/${token}`;

        const greeting = complaint.isAnonymous
          ? "Hello,"
          : `Dear ${complaint.userId.name || "Citizen"},`;

        /* ---------------------------
           Send escalation email
        ---------------------------*/

        const emailSent = await sendEmail({
          to: complaint.userId.email,
          subject: "Action Required: Complaint Escalation – SwachConnect",
          html: `
            <p>${greeting}</p>

            <p>
              Your complaint has not been resolved within the expected timeframe.
            </p>

            <p>
              <b>Current Authority:</b><br/>
              ${complaint.assignedAuthority}
            </p>

            <p>Please choose how you want to proceed:</p>

            <a href="${escalateUrl}"
               style="padding:10px 18px;
                      background:#d32f2f;
                      color:#fff;
                      text-decoration:none;
                      border-radius:6px;
                      display:inline-block;">
              Escalate Complaint
            </a>

            &nbsp;&nbsp;

            <a href="${waitUrl}"
               style="padding:10px 18px;
                      background:#555;
                      color:#fff;
                      text-decoration:none;
                      border-radius:6px;
                      display:inline-block;">
              Wait
            </a>

            <p style="margin-top:20px;">
              Regards,<br/>
              <b>SwachConnect – Citizen Grievance System</b>
            </p>
          `,
        });

        if (emailSent) {
          console.log(
            `📧 Escalation email sent → ${complaint.userId.email}`
          );
        } else {
          console.warn(
            `⚠ Failed to send escalation email → ${complaint._id}`
          );
        }
      } catch (err) {
        console.error(
          `❌ Error processing complaint ${complaint._id}:`,
          err.message
        );
      }
    }

    console.log("✅ Escalation cron finished");
  } catch (err) {
    console.error("❌ Escalation cron error:", err.message);
  }
};

/* --------------------------------------------------
   Run cron every hour
---------------------------------------------------*/

cron.schedule("0 * * * *", runEscalationCron, {
  timezone: "Asia/Kolkata",
});

console.log("⏰ Escalation cron scheduled (runs hourly)");

module.exports = runEscalationCron;