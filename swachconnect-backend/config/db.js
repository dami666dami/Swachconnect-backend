const mongoose = require("mongoose");

/* --------------------------------------------------
   MongoDB Connection
---------------------------------------------------*/

const connectDB = async () => {
  try {
    if (!process.env.MONGO_URI) {
      console.error("❌ MONGO_URI not found in environment variables");
      process.exit(1);
    }

    const conn = await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log("✅ MongoDB Connected");
    console.log(`📂 Database Host: ${conn.connection.host}`);
    console.log(`📦 Database Name: ${conn.connection.name}`);

  } catch (err) {
    console.error("❌ MongoDB Connection Error:");
    console.error(err.message);

    process.exit(1);
  }
};

/* --------------------------------------------------
   MongoDB Connection Events
---------------------------------------------------*/

mongoose.connection.on("connected", () => {
  console.log("📡 MongoDB connection established");
});

mongoose.connection.on("error", (err) => {
  console.error("❌ MongoDB runtime error:", err);
});

mongoose.connection.on("disconnected", () => {
  console.warn("⚠ MongoDB disconnected");
});

module.exports = connectDB;