import User from "../models/User.js";

export const getProfile = async (req, res) => {
    const { email } = req.query;
    console.log(`Received email to fetch users: ${email}`);
  
    try {
        const trimmedEmail = email.trim().toLowerCase();
        console.log(`Trimmed and lowercased email: ${trimmedEmail}`);
  
        const user = await User.findOne({ email: trimmedEmail }).select('-password');
        
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Convert Buffer to Base64 string if ProfilePic exists
        const userData = user.toObject();
        if (userData.ProfilePic) {
            userData.ProfilePic = `data:image/jpeg;base64,${userData.ProfilePic.toString('base64')}`;
        }

        res.status(200).json({ data: [userData] });
    } catch (error) {
        console.error('Failed to fetch users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
};