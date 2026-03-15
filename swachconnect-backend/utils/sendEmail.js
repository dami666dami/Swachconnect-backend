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
  host: "smtp-relay.brevo.com",
  port: 587,
  secure: false,

  auth: {
    user: process.env.EMAIL_USER, // Brevo login
    pass: process.env.EMAIL_PASS  // Brevo SMTP key
  },

  connectionTimeout: 30000,
  greetingTimeout: 30000,
  socketTimeout: 30000
});

/* --------------------------------------------------
   Verify SMTP connection
---------------------------------------------------*/

transporter.verify((error, success) => {
  if (error) {
    console.error("❌ SMTP connection failed:", error.message);
  } else {
    console.log("📧 SMTP server ready");
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

    if (!to || !subject) {
      console.error("❌ Missing email 'to' or 'subject'");
      return false;
    }

    const mailOptions = {
      from: `"SwachConnect" <swachconnect@gmail.com>`, // sender Gmail
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

    const info = await transporter.sendMail(mailOptions);

    console.log("📧 Email sent successfully");
    console.log("📨 To:", to);
    console.log("📌 Message ID:", info.messageId);

    return true;

  } catch (error) {

    console.error("❌ Email sending failed");
    console.error("Reason:", error.message);

    return false;
  }
};

module.exports = sendEmail;