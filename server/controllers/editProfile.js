import User from '../models/User.js';

export const updateProfile = async (req, res) => {
    const { name, email, mobileNo, DOB, Degree, Department, CurrentYear } = req.body;

    try {
        const updateFields = {};
        if (name) updateFields.name = name;
        if (mobileNo) updateFields.mobileNo = mobileNo;
        if (DOB) updateFields.DOB = DOB;
        if (Degree) updateFields.Degree = Degree;
        if (Department) updateFields.Department = Department;
        if (CurrentYear) updateFields.CurrentYear = CurrentYear;

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
