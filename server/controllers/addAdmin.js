import Admin from '../models/admin.js';
import bcrypt from 'bcrypt';

export const addAdmin = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email is required' });
    }

    try {
        const existingAdmin = await Admin.findOne({ email });
        if (existingAdmin) {
            return res.status(400).json({ message: 'Email already exists' });
        }

        const encryptedEmail = await bcrypt.hash(email, 10);
        const newAdmin = new Admin({ email: encryptedEmail });
        await newAdmin.save();
        res.status(201).json({ message: 'Admin added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error adding admin', error });
    }
};
