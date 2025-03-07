import User from '../models/User.js';

export const updateProfile = async (req, res) => {
    const { name, email, mobileNo, DOB, Degree, Department, CurrentYear, profilePicture } = req.body;

    try {
        const updateFields = {};
        if (name !== undefined && name !== null) updateFields.name = name;
        if (mobileNo !== undefined && mobileNo !== null) updateFields.mobileNo = mobileNo;
        if (DOB !== undefined && DOB !== null) updateFields.DOB = DOB;
        if (Degree !== undefined && Degree !== null) updateFields.Degree = Degree;
        if (Department !== undefined && Department !== null) updateFields.Department = Department;
        if (CurrentYear !== undefined && CurrentYear !== null) updateFields.CurrentYear = CurrentYear;
        if (profilePicture !== undefined && profilePicture !== null) updateFields.profilePicture = profilePicture;

        const update_profile = await User.findOneAndUpdate(
            { email },
            { $set: updateFields },
            { new: true }
        );

        if (!update_profile) {
            return res.status(404).json({ error: 'profile not found' });
        }

        res.status(200).json(update_profile);
    } catch (error) {
        console.error('Failed to update profile:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
};
