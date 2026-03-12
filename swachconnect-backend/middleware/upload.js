const multer = require("multer");
const path = require("path");
const fs = require("fs");

/* --------------------------------------------------
   Ensure uploads directory exists
---------------------------------------------------*/

const uploadDir = path.join(__dirname, "..", "uploads");

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log("📁 Upload folder created:", uploadDir);
}

/* --------------------------------------------------
   Storage configuration
---------------------------------------------------*/

const storage = multer.diskStorage({

  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },

  filename: (req, file, cb) => {

    const ext = path.extname(file.originalname).toLowerCase() || ".jpg";

    const uniqueName =
      Date.now() + "-" + Math.round(Math.random() * 1e9) + ext;

    cb(null, uniqueName);

  },

});

/* --------------------------------------------------
   File validation
---------------------------------------------------*/

const fileFilter = (req, file, cb) => {

  const allowedExt = [
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".heic",
    ".heif",
  ];

  const allowedMime = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
    "application/octet-stream"
  ];

  const ext = path.extname(file.originalname).toLowerCase();

  if (!allowedExt.includes(ext)) {
    return cb(new Error("Only image files are allowed"), false);
  }

  if (!allowedMime.includes(file.mimetype)) {
    return cb(new Error("Invalid image type"), false);
  }

  cb(null, true);

};

/* --------------------------------------------------
   Multer instance
---------------------------------------------------*/

const upload = multer({

  storage,

  fileFilter,

  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }

});

/* --------------------------------------------------
   Error handler wrapper
---------------------------------------------------*/

const uploadMiddleware = (req, res, next) => {

  const uploader = upload.array("image", 5);

  uploader(req, res, function (err) {

    if (err instanceof multer.MulterError) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    next();

  });

};

module.exports = upload;