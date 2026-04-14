import mongoose from "mongoose";

const structureSchema = new mongoose.Schema({
  name: { type: String, required: true },
  category: { type: String, required: true },
  lat: Number,
  lng: Number,
  status: { type: String, default: 'active' },
  expiry: String,
  revenue: { type: Number, default: 0 },
  images: [String],
  lockedBySuperAdmin: { type: Boolean, default: false },
  deleted: { type: Boolean, default: false }
}, { timestamps: true });

// Transformation pour Flutter (id au lieu de _id)
structureSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: (_, ret) => { delete (ret as any)._id; }
});

export const Structure = mongoose.model("Structure", structureSchema);