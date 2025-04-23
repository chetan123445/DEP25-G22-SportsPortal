import User from '../models/User.js';
import Admin from '../models/admin.js';
import bcrypt from 'bcrypt';

export const deleteAccount = async (req, res) => {
    try {
        const { email } = req.body;
        
        // Delete user account
        const result = await User.findOneAndDelete({ email: email });
        
        if (!result) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Remove from admin table if they are an admin
        const admins = await Admin.find();
        for (let admin of admins) {
            const match = await bcrypt.compare(email, admin.email);
            if (match) {
                await Admin.findByIdAndDelete(admin._id);
                break;
            }
        }

        res.status(200).json({ message: 'Account deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting account', error: error.message });
    }
};
