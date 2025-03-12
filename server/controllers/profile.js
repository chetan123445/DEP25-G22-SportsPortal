import User from "../models/User.js";
import multer from 'multer';
import path from 'path';

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ storage });

export const uploadProfilePic = async (req, res) => {
  const { email } = req.body;
  const profilePic = req.file.path;

  try {
    const user = await User.findOneAndUpdate(
      { email },
      { ProfilePic: profilePic },
      { new: true }
    );
    res.status(200).json({ data: user });
  } catch (error) {
    console.error('Failed to upload profile picture:', error);
    res.status(500).json({ error: 'Failed to upload profile picture' });
  }
};

export const getProfile = async (req, res) => {
    const { email } = req.query;
    console.log(`Received email to fetch users: ${email}`);
  
    try {
      const trimmedEmail = email.trim().toLowerCase();
      console.log(`Trimmed and lowercased email: ${trimmedEmail}`);
  
      const data = await User.find({ email: trimmedEmail }).select('-password');
      console.log(`Database query result: ${data}`);
  
      res.status(200).json({ data });
    } catch (error) {
      console.error('Failed to fetch users:', error);
      res.status(500).json({ error: 'Failed to fetch users' });
    }
};