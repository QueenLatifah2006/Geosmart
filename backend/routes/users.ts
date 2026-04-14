import express, { Response } from 'express';
import User from '../models/User.js';
import Activity from '../models/Activity.js';
import bcrypt from 'bcrypt';
import { authenticate, authorize, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

// Get all users
router.get('/', authenticate, authorize(['super_admin', 'admin']), async (req, res) => {
  try {
    const users = await User.find().select('-passwordHash');
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Create a user
router.post('/', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const { email, password, name, role, phone, profilePicture } = req.body;
    
    // Admin cannot create Super Admin
    if (role === 'super_admin' && req.user?.role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admin can create other Super Admins' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = new User({ 
      email, 
      passwordHash, 
      name, 
      role,
      phone,
      profilePicture,
      modifiedBySuperAdmin: req.user?.role === 'super_admin'
    });
    await user.save();

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'CREATED_USER',
      targetId: user._id,
      targetType: 'User'
    }).save();

    res.status(201).json({ message: 'User created', user: { id: user._id, email: user.email, name: user.name, role: user.role } });
  } catch (error: any) {
    console.error('Create user error:', error);
    res.status(400).json({ error: 'Failed to create user', details: error.message });
  }
});

// Update a user
router.put('/:id', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Super Admin Restriction
    if (user.modifiedBySuperAdmin && req.user?.role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admin can modify this user' });
    }

    const updates = req.body;
    if (updates.password) {
      updates.passwordHash = await bcrypt.hash(updates.password, 10);
      delete updates.password;
    }
    
    if (req.user?.role === 'super_admin') {
      updates.modifiedBySuperAdmin = true;
    }

    const updatedUser = await User.findByIdAndUpdate(req.params.id, updates, { new: true }).select('-passwordHash');

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'UPDATED_USER',
      targetId: user._id,
      targetType: 'User'
    }).save();

    res.json(updatedUser);
  } catch (error: any) {
    console.error('Update user error:', error);
    res.status(400).json({ error: 'Failed to update user', details: error.message });
  }
});

// Delete a user
router.delete('/:id', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Super Admin Restriction
    if (user.modifiedBySuperAdmin && req.user?.role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admin can delete this user' });
    }

    await User.findByIdAndDelete(req.params.id);

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'DELETED_USER',
      targetId: user._id,
      targetType: 'User'
    }).save();

    res.json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// Block/Unblock a user
router.patch('/:id/block', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Super Admin Restriction
    if (user.modifiedBySuperAdmin && req.user?.role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admin can block/unblock this user' });
    }

    const { isBlocked } = req.body;
    const updates: any = { isBlocked, blockedBy: isBlocked ? req.user?.userId : null };
    
    if (req.user?.role === 'super_admin') {
      updates.modifiedBySuperAdmin = true;
    }

    const updatedUser = await User.findByIdAndUpdate(req.params.id, updates, { new: true }).select('-passwordHash');

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: isBlocked ? 'BLOCKED_USER' : 'UNBLOCKED_USER',
      targetId: user._id,
      targetType: 'User'
    }).save();

    res.json(updatedUser);
  } catch (error: any) {
    console.error('Update user block status error:', error);
    res.status(400).json({ error: 'Failed to update block status', details: error.message });
  }
});

export default router;
