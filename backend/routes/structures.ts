import express, { Response } from 'express';
import mongoose from 'mongoose';
import Structure from '../models/Structure.js';
import Comment from '../models/Comment.js';
import Activity from '../models/Activity.js';
import Notification from '../models/Notification.js';
import User from '../models/User.js';
import { authenticate, optionalAuthenticate, authorize, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

// Get all structures
router.get('/', optionalAuthenticate, async (req: AuthRequest, res) => {
  try {
    let query: any = {};
    console.log('Structures request from user:', req.user?.userId, 'Role:', req.user?.role);
    if (req.user?.role === 'admin' || req.user?.role === 'super_admin') {
      // Admin and Super Admin see all structures
      query = {};
    } else {
      // Regular users see structures that are NOT blocked
      // We removed the isPremium requirement to ensure structures are visible as requested
      query = { isBlocked: false };
    }
    const structures = await Structure.find(query);
    console.log('Found structures:', structures.length);
    res.json(structures);
  } catch (error: any) {
    console.error('Fetch structures error:', error);
    res.status(500).json({ error: 'Failed to fetch structures', details: error.message });
  }
});

// Get single structure
router.get('/:id', optionalAuthenticate, async (req, res) => {
  try {
    const structure = await Structure.findById(req.params.id);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });
    res.json(structure);
  } catch (error: any) {
    console.error('Fetch single structure error:', error);
    res.status(400).json({ error: 'Invalid structure ID', details: error.message });
  }
});

// Create a structure
router.post('/', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const { name, type, location, description, address, telephone, products, services, ownerId, isPremium } = req.body;
    
    // Use ownerId as provided (string)
    let validOwnerId = ownerId;
    if (!validOwnerId && req.user?.role === 'admin') {
      validOwnerId = req.user.userId;
    }

    const structure = new Structure({ 
      name, 
      type, 
      location, 
      description, 
      address, 
      telephone,
      products,
      services,
      ownerId: validOwnerId, 
      isPremium,
      modifiedBySuperAdmin: req.user?.role === 'super_admin'
    });
    await structure.save();

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'CREATED_STRUCTURE',
      targetId: structure._id,
      targetType: 'Structure'
    }).save();

    res.status(201).json(structure);
  } catch (error: any) {
    console.error('Create structure error:', error);
    res.status(400).json({ error: 'Failed to create structure', details: error.message });
  }
});

// Update a structure
router.put('/:id', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    console.log(`Updating structure ${req.params.id} by user ${req.user?.userId} (${req.user?.role})`);
    const structure = await Structure.findById(req.params.id);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });

    // Restriction: Admin cannot modify a blocked structure
    if (req.user?.role === 'admin' && structure.isBlocked) {
      return res.status(403).json({ error: 'Action refusée : Cette structure est bloquée par le Super Admin.' });
    }

    const updates = req.body;

    if (req.user?.role === 'super_admin') {
      updates.modifiedBySuperAdmin = true;
    }

    const updatedStructure = await Structure.findByIdAndUpdate(req.params.id, updates, { new: true });
    console.log(`Structure ${req.params.id} updated successfully`);
    
    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'UPDATED_STRUCTURE',
      targetId: structure._id,
      targetType: 'Structure'
    }).save();

    res.json(updatedStructure);
  } catch (error: any) {
    console.error('Update structure error:', error);
    res.status(400).json({ error: 'Failed to update structure', details: error.message });
  }
});

// Delete a structure
router.delete('/:id', authenticate, authorize(['super_admin', 'admin']), async (req: AuthRequest, res: Response) => {
  try {
    const structure = await Structure.findById(req.params.id);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });

    // Restriction: Admin cannot delete a blocked structure
    if (req.user?.role === 'admin' && structure.isBlocked) {
      return res.status(403).json({ error: 'Action refusée : Cette structure est bloquée par le Super Admin.' });
    }

    await Structure.findByIdAndDelete(req.params.id);

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: 'DELETED_STRUCTURE',
      targetId: structure._id,
      targetType: 'Structure'
    }).save();

    res.json({ message: 'Structure deleted' });
  } catch (error: any) {
    console.error('Delete structure error:', error);
    res.status(500).json({ error: 'Failed to delete structure', details: error.message });
  }
});

// Block/Unblock a structure
router.patch('/:id/block', authenticate, authorize(['super_admin']), async (req: AuthRequest, res: Response) => {
  try {
    const structure = await Structure.findById(req.params.id);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });

    const { isBlocked } = req.body;
    const updates: any = { isBlocked, blockedBy: isBlocked ? req.user?.userId : null };
    
    if (req.user?.role === 'super_admin') {
      updates.modifiedBySuperAdmin = true;
    }

    const updatedStructure = await Structure.findByIdAndUpdate(req.params.id, updates, { new: true });

    // Log activity
    await new Activity({
      userId: req.user?.userId,
      action: isBlocked ? 'BLOCKED_STRUCTURE' : 'UNBLOCKED_STRUCTURE',
      targetId: structure._id,
      targetType: 'Structure'
    }).save();

    res.json(updatedStructure);
  } catch (error: any) {
    console.error('Block structure error:', error);
    res.status(400).json({ error: 'Failed to update block status', details: error.message });
  }
});

// Comments
router.post('/:id/comments', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const structure = await Structure.findById(req.params.id);
    if (!structure) return res.status(404).json({ error: 'Structure not found' });

    const comment = new Comment({
      structureId: req.params.id,
      userId: req.user?.userId,
      text: req.body.text
    });
    await comment.save();

    // Notify Admins and Super Admins
    const user = await User.findById(req.user?.userId);
    
    // Create notification for Super Admin
    await new Notification({
      targetRole: 'super_admin',
      title: 'Nouveau commentaire',
      message: `${user?.name || 'Un utilisateur'} a commenté sur ${structure.name}`
    }).save();

    // Create notification for Admin (if the structure has an owner who is an admin and it's a valid ID)
    if (structure.ownerId && mongoose.Types.ObjectId.isValid(structure.ownerId)) {
      await new Notification({
        userId: structure.ownerId,
        title: 'Nouveau commentaire',
        message: `${user?.name || 'Un utilisateur'} a commenté sur votre structure ${structure.name}`
      }).save();
    }

    res.status(201).json(comment);
  } catch (error: any) {
    console.error('Add comment error:', error);
    res.status(400).json({ error: 'Failed to add comment', details: error.message });
  }
});

router.get('/:id/comments', async (req, res) => {
  try {
    const comments = await Comment.find({ structureId: req.params.id }).populate('userId', 'name');
    res.json(comments);
  } catch (error: any) {
    console.error('Fetch comments error:', error);
    res.status(500).json({ error: 'Failed to fetch comments', details: error.message });
  }
});

// Debug route to see all structures (Super Admin only)
router.get('/debug/all', authenticate, authorize(['super_admin']), async (req: AuthRequest, res) => {
  try {
    const structures = await Structure.find({});
    res.json({
      count: structures.length,
      structures: structures.map(s => ({
        id: s._id,
        name: s.name,
        ownerId: s.ownerId,
        isPremium: s.isPremium,
        isBlocked: s.isBlocked
      }))
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
