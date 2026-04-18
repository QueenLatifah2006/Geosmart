import express from 'express';
import multer from 'multer';
import path from 'path';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|webp|gif/;
    const mimetype = filetypes.test(file.mimetype.toLowerCase());
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());

    console.log('Upload attempt:', {
      mimetype: file.mimetype,
      originalname: file.originalname,
      ext: path.extname(file.originalname),
      matchesMime: mimetype,
      matchesExt: extname
    });

    // Accept if either the mimetype matches OR the extension matches
    // Sometimes mobile clients or web blobs don't provide both perfectly
    if (mimetype || extname) {
      return cb(null, true);
    }
    cb(new Error('Only images (jpeg, jpg, png, webp, gif) are allowed'));
  }
});

// Upload single image
router.post('/', authenticate, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      console.error('Multer error:', err);
      return res.status(400).json({ error: `Upload error: ${err.message}` });
    } else if (err) {
      // If it's the validation error from fileFilter, return 400
      if (err.message.includes('Only images')) {
        return res.status(400).json({ error: err.message });
      }
      console.error('Other upload error:', err);
      return res.status(500).json({ error: `Internal Server Error: ${err.message}` });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Return the URL to the uploaded file
    const fileUrl = `/uploads/${req.file.filename}`;
    res.json({ url: fileUrl });
  });
});

export default router;
