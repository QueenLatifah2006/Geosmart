import express from 'express';
import User from '../models/User.js';
import Structure from '../models/Structure.js';

import { authenticate, optionalAuthenticate, AuthRequest } from '../middleware/auth.js';

const router = express.Router();

router.get('/', optionalAuthenticate, async (req: AuthRequest, res) => {
  try {
    let userQuery = {};
    let structureQuery = {};
    
    console.log('Stats request from user:', req.user?.userId, 'Role:', req.user?.role);
    
    const [totalUsers, totalStructures, premiumStructures, blockedStructures, activeStructures] = await Promise.all([
      User.countDocuments(userQuery),
      Structure.countDocuments(structureQuery),
      Structure.countDocuments({ ...structureQuery, isPremium: true }),
      Structure.countDocuments({ ...structureQuery, isBlocked: true }),
      Structure.countDocuments({ ...structureQuery, isBlocked: false })
    ]);
    
    console.log(`Stats results for ${req.user?.role || 'guest'}: Users=${totalUsers}, Structures=${totalStructures}, Premium=${premiumStructures}`);

    const structures = await Structure.find(structureQuery);
    const totalViews = structures.reduce((acc, s) => acc + (s.views || 0), 0);
    
    res.json({
      totalUsers,
      totalStructures,
      premiumStructures,
      blockedStructures,
      activeStructures,
      totalViews,
      alerts: 0
    });
  } catch (error: any) {
    console.error('Stats error:', error);
    res.status(500).json({ error: 'Failed to fetch stats', details: error.message });
  }
});

export default router;
