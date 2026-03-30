const mongoose = require("mongoose");

/* --------------------------------------------------
   Complaint Schema
---------------------------------------------------*/

const complaintSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    reporterName: {
      type: String,
      trim: true,
      default: null,
    },

    reporterEmail: {
      type: String,
      lowercase: true,
      trim: true,
      default: null,
      match: [/^\S+@\S+\.\S+$/, "Invalid email format"],
    },

    isAnonymous: {
      type: Boolean,
      default: false,
      index: true,
    },

    description: {
      type: String,
      required: true,
      trim: true,
      minlength: 5,
      maxlength: 1000,
    },

    /* --------------------------------------------------
       Images
    ---------------------------------------------------*/

    images: {
      type: [String],
      default: [],
      validate: {
        validator: (arr) => arr.length <= 5,
        message: "Maximum 5 images allowed",
      },
    },

    /* --------------------------------------------------
       Location
    ---------------------------------------------------*/

    location: {
      lat: {
        type: Number,
        default: null,
      },
      lng: {
        type: Number,
        default: null,
      },
      address: {
        type: String,
        default: null,
      },
    },

    /* --------------------------------------------------
       Status tracking
    ---------------------------------------------------*/

    status: {
      type: String,
      enum: [
        "Pending",
        "In Progress",
        "Escalated",
        "Resolved",
        "Pending Escalation",
      ],
      default: "Pending",
      index: true,
    },

    progress: {
      type: Number,
      min: 0,
      max: 100,
      default: 10,
    },

    assignedAuthority: {
      type: String,
      default: "Municipality / Panchayat",
      index: true,
    },

    escalationLevel: {
      type: Number,
      default: 0,
      min: 0,
      index: true,
    },

    escalationPending: {
      type: Boolean,
      default: false,
      index: true,
    },

    lastEscalatedAt: {
      type: Date,
      default: null,
    },

    finalEscalationReached: {
      type: Boolean,
      default: false,
      index: true,
    },

    /* --------------------------------------------------
       Email flags
    ---------------------------------------------------*/

    escalationEmailSent: {
      type: Boolean,
      default: false,
    },

    resolutionEmailSent: {
      type: Boolean,
      default: false,
    },

    /* --------------------------------------------------
       Social escalation
    ---------------------------------------------------*/

    socialEscalated: {
      type: Boolean,
      default: false,
      index: true,
    },

    socialPostContent: {
      type: String,
      default: null,
    },

    socialPostedAt: {
      type: Date,
      default: null,
    },

    /* --------------------------------------------------
       Email action tokens
    ---------------------------------------------------*/

    emailActionToken: {
      type: String,
      default: null,
      index: true,
    },

    emailActionExpires: {
      type: Date,
      default: null,
      index: true,
    },

    /* --------------------------------------------------
       Escalation deadline
    ---------------------------------------------------*/

    deadline: {
      type: Date,
      index: true,
      default: function () {
        // auto deadline = 3 days
        return new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
      },
    },

    escalationReason: {
      type: String,
      default: null,
      maxlength: 500,
    },

    internalNotes: {
      type: String,
      default: null,
      select: false,
    },

    /* --------------------------------------------------
       Feedback (NEW 🔥)
    ---------------------------------------------------*/

    feedbackGiven: {
      type: Boolean,
      default: false,
    },

    feedbackRating: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },

    feedbackMessage: {
      type: String,
      default: null,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

/* --------------------------------------------------
   Indexes for performance
---------------------------------------------------*/

complaintSchema.index({ userId: 1, createdAt: -1 });
complaintSchema.index({ status: 1, deadline: 1 });
complaintSchema.index({ escalationLevel: 1, deadline: 1 });
complaintSchema.index({ escalationEmailSent: 1, deadline: 1 });
complaintSchema.index({ socialEscalated: 1, status: 1 });
complaintSchema.index({ isAnonymous: 1, status: 1 });
complaintSchema.index({ assignedAuthority: 1, escalationLevel: 1 });

/* --------------------------------------------------
   Virtual field for image URLs
---------------------------------------------------*/

complaintSchema.virtual("imageUrls").get(function () {
  const baseUrl =
    process.env.BASE_URL ||
    "http://localhost:4000";

  if (!this.images || this.images.length === 0) return [];

  return this.images.map((img) =>
    img.startsWith("http")
      ? img
      : `${baseUrl}${img}`
  );
});

/* --------------------------------------------------
   Ensure virtual fields are included in JSON
---------------------------------------------------*/

complaintSchema.set("toJSON", {
  virtuals: true,
});

/* --------------------------------------------------
   Pre-save hook (auto logic)
---------------------------------------------------*/

complaintSchema.pre("save", function (next) {
  // mark final escalation automatically
  if (this.escalationLevel >= 6) {
    this.finalEscalationReached = true;
  }
  next();
});

module.exports = mongoose.model("Complaint", complaintSchema);