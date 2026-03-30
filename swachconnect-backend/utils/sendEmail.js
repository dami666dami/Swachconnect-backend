const nodemailer = require("nodemailer");

/* --------------------------------------------------
   Validate environment variables
---------------------------------------------------*/

if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
  console.warn("⚠ EMAIL_USER or EMAIL_PASS not configured in environment");
}

/* --------------------------------------------------
   Create transporter (Brevo SMTP)
---------------------------------------------------*/

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp-relay.brevo.com",
  port: Number(process.env.SMTP_PORT) || 587,
  secure: false, // IMPORTANT: false for port 587

  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  },

  tls: {
    rejectUnauthorized: false // avoids TLS issues on Render
  },

  connectionTimeout: 30000,
  greetingTimeout: 30000,
  socketTimeout: 30000
});

/* --------------------------------------------------
   Verify SMTP connection (runs once)
---------------------------------------------------*/

transporter.verify((error) => {
  if (error) {
    console.error("❌ SMTP connection failed:", error.message);
  } else {
    console.log("📧 SMTP server is ready to send emails");
  }
});

/* --------------------------------------------------
   Send Email Function
---------------------------------------------------*/

const sendEmail = async ({
  to,
  subject,
  text = null,
  html = null,
  attachments = [],
  replyTo = null
}) => {
  try {
    /* -------- VALIDATION -------- */

    if (!to || !subject) {
      console.error("❌ Missing 'to' or 'subject'");
      return false;
    }

    /* -------- EMAIL OPTIONS -------- */

    const mailOptions = {
      from: `"SwachConnect Support" <swachconnect@gmail.com>`, // MUST match verified sender
      to,
      subject,

      text:
        text ||
        (html
          ? "This is an official notification from SwachConnect."
          : "SwachConnect Notification"),

      html: html || undefined,

      attachments: Array.isArray(attachments) ? attachments : []
    };

    if (replyTo) {
      mailOptions.replyTo = replyTo;
    }

    /* -------- SEND EMAIL -------- */

    const info = await transporter.sendMail(mailOptions);

    console.log("✅ Email sent successfully");
    console.log("📨 To:", to);
    console.log("📌 Message ID:", info.messageId);

    return true;

  } catch (error) {
    console.error("❌ Email sending failed");
    console.error("🔍 Full error:", error);

    return false;
  }
};

module.exports = sendEmail;