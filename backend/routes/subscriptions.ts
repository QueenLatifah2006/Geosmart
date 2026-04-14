import express, { Response } from 'express';
import Subscription from '../models/Subscription.js';
import Structure from '../models/Structure.js';
import Activity from '../models/Activity.js';
import { authenticate, authorize, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

// Get all subscriptions
router.get('/', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res) => {
  try {
    let query = {};
    console.log('Subscriptions request from user:', req.user?.userId, 'Role:', req.user?.role);
    if (req.user?.role === 'admin') {
      // Admin now sees all subscriptions just like super admin
      query = {};
    }
    const subscriptions = await Subscription.find(query).populate('structureId', 'name isBlocked');
    console.log('Found subscriptions:', subscriptions.length);
    res.json(subscriptions);
  } catch (error: any) {
    console.error('Fetch subscriptions error:', error);
    res.status(500).json({ error: 'Failed to fetch subscriptions', details: error.message });
  }
});

// Create a subscription
router.post('/', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const { structureId, type, durationInDays } = req.body;
    
    const structure = await Structure.findById(structureId);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });

    // Restriction: Admin cannot create subscription for a blocked structure
    if (req.user?.role === 'admin' && structure.isBlocked) {
      return res.status(403).json({ error: 'Action refusée : Cette structure est bloquée par le Super Admin.' });
    }

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(startDate.getDate() + (durationInDays || 30));

    const subscription = new Subscription({
      structureId,
      type,
      startDate,
      endDate,
      status: 'Active'
    });
    await subscription.save();

    // Update structure's premium status if applicable
    if (type !== 'Free') {
      await Structure.findByIdAndUpdate(structureId, { isPremium: true });
    }

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'CREATED_SUBSCRIPTION',
      targetId: subscription._id,
      targetType: 'Subscription'
    }).save();

    res.status(201).json(subscription);
  } catch (error: any) {
    console.error('Create subscription error:', error);
    res.status(400).json({ error: 'Failed to create subscription', details: error.message });
  }
});

// Update a subscription
router.put('/:id', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    console.log(`Updating subscription ${req.params.id} by user ${req.user?.userId} (${req.user?.role})`);
    const subscription = await Subscription.findById(req.params.id).populate('structureId');
    if (!subscription) return res.status(404).json({ error: 'Subscription not found' });

    // Restriction: Admin cannot modify subscription for a blocked structure
    const structure = subscription.structureId as any;
    if (req.user?.role === 'admin' && structure && structure.isBlocked) {
      return res.status(403).json({ error: 'Action refusée : Cette structure est bloquée par le Super Admin.' });
    }

    const updatedSubscription = await Subscription.findByIdAndUpdate(req.params.id, req.body, { new: true });
    console.log(`Subscription ${req.params.id} updated successfully`);

    // Sync structure premium status if status or type changed
    if (updatedSubscription) {
      const isPremium = updatedSubscription.status === 'Active' && updatedSubscription.type !== 'Free';
      await Structure.findByIdAndUpdate(updatedSubscription.structureId, { isPremium });
    }

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'UPDATED_SUBSCRIPTION',
      targetId: subscription._id,
      targetType: 'Subscription'
    }).save();

    res.json(updatedSubscription);
  } catch (error: any) {
    console.error('Update subscription error:', error);
    res.status(400).json({ error: 'Failed to update subscription', details: error.message });
  }
});

export default router;
