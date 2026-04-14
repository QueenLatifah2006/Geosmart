import express, { Response } from 'express';
import Notification from '../models/Notification.js';
import { authenticate, authorize, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

// Get notifications for current user
router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const notifications = await Notification.find({
      $or: [
        { userId: req.user?.userId },
        { targetRole: req.user?.role },
        { targetRole: 'all' }
      ]
    }).sort({ createdAt: -1 });
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Create a notification (Admin only)
router.post('/', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const { userId, targetRole, title, message } = req.body;
    const notification = new Notification({
      userId,
      targetRole,
      title,
      message
    });
    await notification.save();
    res.status(201).json(notification);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create notification' });
  }
});

// Mark as read
router.patch('/:id/read', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const notification = await Notification.findByIdAndUpdate(req.params.id, { isRead: true }, { new: true });
    res.json(notification);
  } catch (error) {
    res.status(400).json({ error: 'Failed to update notification' });
  }
});

export default router;
