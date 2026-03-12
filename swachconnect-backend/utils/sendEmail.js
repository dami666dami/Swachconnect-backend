const nodemailer = require("nodemailer");

/* --------------------------------------------------
   Validate environment variables
---------------------------------------------------*/

if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
  console.warn("⚠ EMAIL_USER or EMAIL_PASS not configured");
}

/* --------------------------------------------------
   Create transporter
---------------------------------------------------*/

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,

  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },

  connectionTimeout: 20000,
  greetingTimeout: 20000,
  socketTimeout: 20000,

  tls: {
    rejectUnauthorized: false,
  },
});

/* --------------------------------------------------
   Verify SMTP connection
---------------------------------------------------*/

(async () => {
  try {
    await transporter.verify();
    console.log("📧 SMTP server ready");
  } catch (error) {
    console.error("❌ SMTP connection failed:", error.message);
  }
})();

/* --------------------------------------------------
   Send email function
---------------------------------------------------*/

const sendEmail = async ({
  to,
  subject,
  text = null,
  html = null,
  attachments = [],
  replyTo = null,
}) => {
  try {

    if (!to || !subject) {
      console.error("❌ Missing email 'to' or 'subject'");
      return false;
    }

    const mailOptions = {
      from: `"SwachConnect" <${process.env.EMAIL_USER}>`,
      to,
      subject,

      text:
        text ||
        (html
          ? "This is an official notification from SwachConnect."
          : "SwachConnect Notification"),

      html: html || undefined,

      attachments: Array.isArray(attachments) ? attachments : [],
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