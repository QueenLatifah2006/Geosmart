import mongoose, { Schema, Document } from 'mongoose';

export interface IStructure extends Document {
  name: string;
  type: string;
  location: {
    lat: number;
    lng: number;
  };
  description: string;
  address: string;
  telephone?: string;
  products?: { name: string; price: string; photo?: string }[];
  services?: { name: string; price: string; photo?: string }[];
  ownerId: string;
  isPremium: boolean;
  views: number;
  isBlocked: boolean;
  blockedBy?: mongoose.Types.ObjectId;
  modifiedBySuperAdmin: boolean;
  createdAt: Date;
}

const StructureSchema: Schema = new Schema({
  name: { type: String, required: true },
  type: { type: String, default: 'Autre' },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  description: { type: String },
  address: { type: String },
  telephone: { type: String },
  products: [{
    name: { type: String },
    price: { type: String },
    photo: { type: String }
  }],
  services: [{
    name: { type: String },
    price: { type: String },
    photo: { type: String }
  }],
  ownerId: { type: String },
  isPremium: { type: Boolean, default: false },
  views: { type: Number, default: 0 },
  isBlocked: { type: Boolean, default: false },
  blockedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  modifiedBySuperAdmin: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model<IStructure>('Structure', StructureSchema);
