import express from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Activity from '../models/Activity.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, role, phone } = req.body;
    const passwordHash = await bcrypt.hash(password, 10);
    const user = new User({ email, passwordHash, name, role, phone });
    await user.save();
    
    console.log(`User registered successfully: ${email}`);
    
    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });
    res.status(201).json({ 
      message: 'User created', 
      token, 
      user: { id: user._id, email: user.email, role: user.role, name: user.name } 
    });
  } catch (error: any) {
    console.error('Registration error:', error);
    res.status(400).json({ error: 'Registration failed', details: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Email non trouvé', field: 'email' });
    }
    if (user.isBlocked) {
      return res.status(403).json({ error: 'Compte bloqué', field: 'email' });
    }
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Mot de passe incorrect', field: 'password' });
    }
    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });
    res.json({ token, user: { id: user._id, email: user.email, role: user.role, name: user.name } });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// Get Profile
router.get('/profile', authenticate, async (req: AuthRequest, res) => {
  try {
    const user = await User.findById(req.user?.userId).select('-passwordHash');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update Profile
router.put('/profile', authenticate, async (req: AuthRequest, res) => {
  try {
    const { name, email, phone, profilePicture } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user?.userId, 
      { name, email, phone, profilePicture }, 
      { new: true }
    ).select('-passwordHash');
    
    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'UPDATED_PROFILE',
      targetId: user?._id,
      targetType: 'User'
    }).save();

    res.json(user);
  } catch (error: any) {
    console.error('Update profile error:', error);
    res.status(400).json({ error: 'Failed to update profile', details: error.message });
  }
});

// Change Password
router.post('/change-password', authenticate, async (req: AuthRequest, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user?.userId);
    if (!user || !(await bcrypt.compare(oldPassword, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid old password' });
    }
    const passwordHash = await bcrypt.hash(newPassword, 10);
    await User.findByIdAndUpdate(req.user?.userId, { passwordHash });

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'CHANGED_PASSWORD',
      targetId: user._id,
      targetType: 'User'
    }).save();

    res.json({ message: 'Password changed successfully' });
  } catch (error: any) {
    console.error('Change password error:', error);
    res.status(400).json({ error: 'Failed to change password', details: error.message });
  }
});

export default router;
