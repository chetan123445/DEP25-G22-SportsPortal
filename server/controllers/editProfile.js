import User from '../models/User.js';
import multer from 'multer';

// Configure multer to use memory storage
const storage = multer.memoryStorage();
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

    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Store the image in binary format
        const profilePic = req.file.buffer;

        const updatedUser = await User.findOneAndUpdate(
            { email },
            { ProfilePic: profilePic },
            { new: true }
        );

        if (updatedUser) {
            // Convert the ProfilePic buffer to a Base64 string
            const profilePicBase64 = updatedUser.ProfilePic
                ? `data:image/jpeg;base64,${updatedUser.ProfilePic.toString('base64')}`
                : null;

            return res.status(200).json({ 
                data: { 
                    ...updatedUser.toObject(), 
                    ProfilePic: profilePicBase64 
                } 
            });
        }

        res.status(500).json({ error: 'Failed to update profile picture' });
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
            // Remove the profile picture by setting it to null
            const updatedUser = await User.findOneAndUpdate(
                { email },
                { ProfilePic: null },
                { new: true }
            );
            return res.status(200).json({ data: updatedUser });
        }

        res.status(404).json({ error: 'Profile picture not found' });
    } catch (error) {
        console.error('Failed to remove profile picture:', error);
        res.status(500).json({ error: 'Failed to remove profile picture' });
    }
};
