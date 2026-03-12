const nodemailer = require("nodemailer");

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
      console.error(" Missing email 'to' or 'subject'");
      return false;
    }

    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.error(" EMAIL_USER or EMAIL_PASS is missing in .env");
      return false;
    }

    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 587,
      secure: false, 

      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },

      tls: {
        rejectUnauthorized: false, 
      },
    });

    await transporter.verify();
    console.log(" Gmail transporter verified");

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

    console.log(" Email sent successfully");
    console.log(" To:", to);
    console.log(" Message ID:", info.messageId);

    return true;
  } catch (error) {
    console.error(" Email sending failed");
    console.error(" Reason:", error.message);
    return false;
  }
};

module.exports = sendEmail;
