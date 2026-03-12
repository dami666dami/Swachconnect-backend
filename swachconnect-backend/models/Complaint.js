const mongoose = require("mongoose");
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
      default: null,
      trim: true,
    },

    reporterEmail: {
      type: String,
      default: null,
      lowercase: true,
      trim: true,
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
    },

    images: {
      type: [String],
      default: [],
      validate: {
        validator: (arr) => arr.length <= 5,
        message: "Maximum 5 images allowed",
      },
    },

    location: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },

    status: {
      type: String,
      enum: [
        "Pending",
        "Escalated",
        "Resolved",
        "In Progress",
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

    escalationEmailSent: {
      type: Boolean,
      default: false,
    },

    resolutionEmailSent: {
      type: Boolean,
      default: false,
    },

    socialEscalated: {
      type: Boolean,
      default: false,
      index: true,
    },

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

    deadline: {
      type: Date,
      index: true,
    },

    escalationReason: {
      type: String,
      default: null,
    },

    internalNotes: {
      type: String,
      default: null,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

complaintSchema.index({ userId: 1, createdAt: -1 });
complaintSchema.index({ status: 1, deadline: 1 });
complaintSchema.index({ escalationLevel: 1, deadline: 1 });
complaintSchema.index({ escalationEmailSent: 1, deadline: 1 });
complaintSchema.index({ socialEscalated: 1, status: 1 });
complaintSchema.index({ isAnonymous: 1, status: 1 });
complaintSchema.index({ assignedAuthority: 1, escalationLevel: 1 });

module.exports = mongoose.model("Complaint", complaintSchema);
