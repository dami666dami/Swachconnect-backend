const nodemailer = require("nodemailer");
const axios = require("axios");

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
  port: Number(process.env.SMTP_PORT) || 465,
  secure: true,

  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  },

  requireTLS: true,
  tls: {
    rejectUnauthorized: false
  },

  connectionTimeout: 60000,
  greetingTimeout: 60000,
  socketTimeout: 60000
});

/* --------------------------------------------------
   Verify SMTP connection
---------------------------------------------------*/

transporter.verify((error) => {
  if (error) {
    console.error("❌ SMTP connection failed:", error.message);
  } else {
    console.log("📧 SMTP ready");
  }
});

/* --------------------------------------------------
   🔥 Brevo API fallback
---------------------------------------------------*/

const sendViaAPI = async ({ to, subject, html, text }) => {
  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: "SwachConnect",
          email: "swachconnect@gmail.com"
        },
        to: [{ email: to }],
        subject,
        htmlContent: html,
        textContent: text
      },
      {
        headers: {
          "api-key": process.env.EMAIL_PASS,
          "Content-Type": "application/json"
        }
      }
    );

    console.log("✅ Email sent via Brevo API");
    return true;

  } catch (error) {
    console.error("❌ Brevo API failed:", error.response?.data || error.message);
    return false;
  }
};

/* --------------------------------------------------
   Send Email Function (SMART)
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
    if (!to || !subject) {
      console.error("❌ Missing 'to' or 'subject'");
      return false;
    }

    const mailOptions = {
      from: `"SwachConnect Support" <swachconnect@gmail.com>`,
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

    console.log("📤 Attempting SMTP email...");

    /* -------- TRY SMTP FIRST -------- */
    const info = await transporter.sendMail(mailOptions);

    console.log("✅ Email sent via SMTP");
    console.log("📌 Message ID:", info.messageId);

    return true;

  } catch (error) {
    console.error("❌ SMTP failed:", error.message);

    if (error.code === "ETIMEDOUT" || error.code === "ESOCKET") {
      console.log("⚠ Switching to Brevo API fallback...");
      return await sendViaAPI({ to, subject, html, text });
    }

    return false;
  }
};

module.exports = sendEmail;