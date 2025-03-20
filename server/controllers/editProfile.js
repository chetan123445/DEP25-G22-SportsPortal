import User from '../models/User.js';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

export const upload = multer({ storage: storage });

export const updateProfile = async (req, res) => {
    const { name, email, mobileNo, DOB, Degree, Department, CurrentYear, profilePicture } = req.body;

    try {
        const updateFields = {};
        if (name !== undefined && name !== null) updateFields.name = name;
        if (mobileNo !== undefined && mobileNo !== null) updateFields.mobileNo = mobileNo;
        if (DOB !== undefined && DOB !== null) updateFields.DOB = DOB;
        if (Degree !== undefined && Degree !== null) updateFields.Degree = Degree;
        if (Department !== undefined && Department !== null) updateFields.Department = Department;
        if (CurrentYear !== undefined && CurrentYear !== null) {
            const parsedYear = parseInt(CurrentYear, 10);
            if (isNaN(parsedYear)) {
                return res.status(400).json({ error: 'CurrentYear must be a number' });
            }
            updateFields.CurrentYear = parsedYear;
        }
        if (profilePicture !== undefined && profilePicture !== null) updateFields.ProfilePic = profilePicture;

        const update_profile = await User.findOneAndUpdate(
            { email },
            { $set: updateFields },
            { new: true, runValidators: true }
        );

        if (!update_profile) {
            return res.status(404).json({ error: 'profile not found' });
        }

        res.status(200).json(update_profile);
    } catch (error) {
        console.error('Failed to update profile:', error);
        if (error.name === 'ValidationError') {
            return res.status(400).json({ error: error.message });
        }
        res.status(500).json({ error: 'Failed to update profile' });
    }
};

export const uploadProfilePic = async (req, res) => {
  const { email } = req.body;
  const profilePic = req.file.path;

  try {
    const user = await User.findOne({ email });
    if (user && user.ProfilePic) {
      // Remove the old profile picture
      fs.unlink(user.ProfilePic, (err) => {
        if (err) console.error('Failed to delete old profile picture:', err);
      });
    }

    const updatedUser = await User.findOneAndUpdate(
      { email },
      { ProfilePic: profilePic },
      { new: true }
    );
    res.status(200).json({ data: updatedUser });
  } catch (error) {
    console.error('Failed to upload profile picture:', error);
    res.status(500).json({ error: 'Failed to upload profile picture' });
  }
};

export const removeProfilePic = async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (user && user.ProfilePic) {
      // Remove the profile picture
      fs.unlink(user.ProfilePic, (err) => {
        if (err) console.error('Failed to delete profile picture:', err);
      });
    }

    const updatedUser = await User.findOneAndUpdate(
      { email },
      { ProfilePic: '' },
      { new: true }
    );
    res.status(200).json({ data: updatedUser });
  } catch (error) {
    console.error('Failed to remove profile picture:', error);
    res.status(500).json({ error: 'Failed to remove profile picture' });
  }
};
