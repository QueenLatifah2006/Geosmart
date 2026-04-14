import mongoose from "mongoose";

export const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI || "mongodb://localhost:27017/geosmart";
    await mongoose.connect(uri);
    console.log("✅ MongoDB connecté avec succès");
  } catch (err) {
    console.error("❌ Erreur de connexion MongoDB:", err);
    process.exit(1);
  }
};