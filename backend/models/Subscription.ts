import mongoose, { Schema, Document } from 'mongoose';

export interface ISubscription extends Document {
  structureId: mongoose.Types.ObjectId;
  type: 'Free' | 'Premium' | 'Gold';
  startDate: Date;
  endDate: Date;
  status: 'Active' | 'Expired' | 'Cancelled';
  createdAt: Date;
}

const SubscriptionSchema: Schema = new Schema({
  structureId: { type: Schema.Types.ObjectId, ref: 'Structure', required: true },
  type: { type: String, enum: ['Free', 'Premium', 'Gold'], default: 'Free' },
  startDate: { type: Date, default: Date.now },
  endDate: { type: Date, required: true },
  status: { type: String, enum: ['Active', 'Expired', 'Cancelled'], default: 'Active' },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model<ISubscription>('Subscription', SubscriptionSchema);
