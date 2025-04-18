import Admin from '../models/admin.js';
import User from '../models/User.js'; // Import the User model
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const JWT_SECRET = 'your_jwt_secret_key'; // Replace with your actual secret key

export const addAdmin = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email is required' });
    }

    try {
        // Check if the email exists in the User model
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Only registered users are allowed to be added as Admins' });
        }

        // Check if the email already exists in the Admin model
        const admins = await Admin.find();
        for (let admin of admins) {
            const match = await bcrypt.compare(email, admin.email);
            if (match) {
                return res.status(400).json({ message: 'Email already exists' });
            }
        }

        // Encrypt the email and add it to the Admin model
        const encryptedEmail = await bcrypt.hash(email, 10);
        const newAdmin = new Admin({ email: encryptedEmail });
        await newAdmin.save();
        res.status(201).json({ message: 'Admin added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error adding admin', error });
    }
};

export const verifyAdmin = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email is required' });
    }

    try {
        const admins = await Admin.find();
        for (let admin of admins) {
            const match = await bcrypt.compare(email, admin.email);
            if (match) {
                const token = jwt.sign({ isAdmin: true }, JWT_SECRET, { expiresIn: '50s' });
                return res.status(200).json({ token });
            }
        }
        const token = jwt.sign({ isAdmin: false }, JWT_SECRET, { expiresIn: '50s' });
        res.status(200).json({ token });
    } catch (error) {
        res.status(500).json({ message: 'Error verifying admin', error });
    }
};

export const removeAdmin = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email is required' });
    }

    const superAdmins = ['2022csb1090@iitrpr.ac.in', '2022csb1074@iitrpr.ac.in'];

    if (superAdmins.includes(email)) {
        return res.status(403).json({ message: 'Unable to remove super admins' });
    }

    try {
        const admins = await Admin.find();
        for (let admin of admins) {
            const match = await bcrypt.compare(email, admin.email);
            if (match) {
                await Admin.findByIdAndDelete(admin._id);
                return res.status(200).json({ message: 'Admin removed successfully' });
            }
        }
        res.status(404).json({ message: 'Admin not found' });
    } catch (error) {
        res.status(500).json({ message: 'Error removing admin', error });
    }
};
