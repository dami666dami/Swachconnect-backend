const nodemailer = require("nodemailer");
const axios = require("axios");

/* --------------------------------------------------
   Validate environment variables
---------------------------------------------------*/

if (!process.env.EMAIL_PASS) {
  console.warn("⚠ EMAIL_PASS not configured");
}

/* --------------------------------------------------
   🔥 PRIMARY SMTP (GMAIL)
---------------------------------------------------*/

const gmailTransporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "swachconnect@gmail.com",
    pass: process.env.EMAIL_PASS // Gmail App Password (no spaces)
  }
});

/* --------------------------------------------------
   OPTIONAL SMTP (Brevo backup)
---------------------------------------------------*/

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp-relay.brevo.com",
  port: Number(process.env.SMTP_PORT) || 465,
  secure: true,

  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  },

  tls: {
    rejectUnauthorized: false
  },

  connectionTimeout: 10000,
  greetingTimeout: 10000,
  socketTimeout: 10000
});

/* --------------------------------------------------
   🔥 PRIMARY METHOD: Gmail SMTP
---------------------------------------------------*/

const sendViaGmail = async (mailOptions) => {
  try {
    console.log("📤 Sending via Gmail...");
    await gmailTransporter.sendMail(mailOptions);
    console.log("✅ Email sent via Gmail");
    return true;
  } catch (error) {
    console.error("❌ Gmail failed:", error.message);
    return false;
  }
};

/* --------------------------------------------------
   🔥 SECOND METHOD: Brevo API
---------------------------------------------------*/

const sendViaAPI = async ({ to, subject, html, text }) => {
  try {
    console.log("📤 Sending email via Brevo API...");

    await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: "SwachConnect Support Team",
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
        },
        timeout: 15000
      }
    );

    console.log("✅ Email sent via API");
    return true;

  } catch (error) {
    console.error("❌ API failed:", error.response?.data || error.message);
    return false;
  }
};

/* --------------------------------------------------
   🔁 BACKUP METHOD: Brevo SMTP
---------------------------------------------------*/

const sendViaSMTP = async (mailOptions) => {
  try {
    console.log("📤 Trying SMTP backup...");
    await transporter.sendMail(mailOptions);
    console.log("✅ Email sent via SMTP");
    return true;
  } catch (error) {
    console.error("❌ SMTP backup failed:", error.message);
    return false;
  }
};

/* --------------------------------------------------
   FINAL SEND FUNCTION
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

    /* 🔥 STEP 1: TRY GMAIL (shows in your phone) */
    const gmailSuccess = await sendViaGmail(mailOptions);

    if (gmailSuccess) return true;

    /* 🔥 STEP 2: TRY BREVO API */
    const apiSuccess = await sendViaAPI({ to, subject, html, text });

    if (apiSuccess) return true;

    /* 🔁 STEP 3: FALLBACK SMTP */
    return await sendViaSMTP(mailOptions);

  } catch (error) {
    console.error("❌ Final email error:", error.message);
    return false;
  }
};

module.exports = sendEmail;