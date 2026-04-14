import express from 'express';
import Activity from '../models/Activity.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = express.Router();

// Get all activities (Super Admin only)
router.get('/', authenticate, authorize(['super_admin']), async (req, res) => {
  try {
    const activities = await Activity.find()
      .populate('userId', 'name email')
      .sort({ timestamp: -1 })
      .limit(50);
    res.json(activities);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch activities' });
  }
});

// Get recent activities for a specific user or target
router.get('/recent', authenticate, async (req, res) => {
  try {
    const activities = await Activity.find()
      .populate('userId', 'name')
      .sort({ timestamp: -1 })
      .limit(10);
    res.json(activities);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch recent activities' });
  }
});

export default router;
