import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  email: string;
  passwordHash: string;
  role: 'super_admin' | 'admin' | 'user';
  name: string;
  phone?: string;
  profilePicture?: string;
  isBlocked: boolean;
  blockedBy?: mongoose.Types.ObjectId;
  modifiedBySuperAdmin: boolean;
  createdAt: Date;
}

const UserSchema: Schema = new Schema({
  email: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['super_admin', 'admin', 'user'], default: 'user' },
  name: { type: String, required: true },
  phone: { type: String, required: false },
  profilePicture: { type: String },
  isBlocked: { type: Boolean, default: false },
  blockedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  modifiedBySuperAdmin: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model<IUser>('User', UserSchema);
