import Admin from '../models/admin.js';
import User from '../models/User.js';
import jwt from 'jsonwebtoken';

const JWT_SECRET = 'your_jwt_secret_key'; // Replace with your actual secret key

export const addAdmin = async (req, res) => {
    const email = req.body.email?.trim().toLowerCase();
    const userEmail = req.body.user_email?.trim().toLowerCase();

    const allowedUsers = ['2022csb1090@iitrpr.ac.in', '2022csb1074@iitrpr.ac.in'];

    if (!email || !userEmail) {
        return res.status(400).json({ message: 'Email and user_email are required' });
    }

    if (!allowedUsers.includes(userEmail)) {
        return res.status(403).json({ message: 'You are not authorized to perform this action' });
    }

    console.log(`Request by: ${userEmail} to add admin: ${email}`);

    try {
        // Check if the email exists in the User model
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Only registered users are allowed to be added as Admins' });
        }

        // Check if the email already exists in the Admin model
        const existingAdmin = await Admin.findOne({ email });
        if (existingAdmin) {
            return res.status(400).json({ message: 'Email already exists' });
        }

        // Add the email directly to the Admin model
        const newAdmin = new Admin({ email });
        await newAdmin.save();
        res.status(201).json({ message: 'Admin added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error adding admin', error });
    }
};

export const verifyAdmin = async (req, res) => {
    const email = req.body.email?.trim().toLowerCase();

    if (!email) {
        return res.status(400).json({ message: 'Email is required' });
    }

    try {
        const admin = await Admin.findOne({ email });
        const isAdmin = !!admin;

        const token = jwt.sign({ isAdmin }, JWT_SECRET, { expiresIn: '50s' });
        res.status(200).json({ token });
    } catch (error) {
        res.status(500).json({ message: 'Error verifying admin', error });
    }
};

export const removeAdmin = async (req, res) => {
    const email = req.body.email?.trim().toLowerCase();
    const userEmail = req.body.user_email?.trim().toLowerCase();

    const allowedUsers = ['2022csb1090@iitrpr.ac.in', '2022csb1074@iitrpr.ac.in'];

    if (!email || !userEmail) {
        return res.status(400).json({ message: 'Email and user_email are required' });
    }

    if (!allowedUsers.includes(userEmail)) {
        return res.status(403).json({ message: 'You are not authorized to perform this action' });
    }

    console.log(`Request by: ${userEmail} to remove admin: ${email}`);

    const superAdmins = ['2022csb1090@iitrpr.ac.in', '2022csb1074@iitrpr.ac.in'];

    if (superAdmins.includes(email)) {
        return res.status(403).json({ message: 'Unable to remove super admins' });
    }

    try {
        const admin = await Admin.findOneAndDelete({ email });
        if (!admin) {
            return res.status(404).json({ message: 'Admin not found' });
        }
        res.status(200).json({ message: 'Admin removed successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error removing admin', error });
    }
};

export const getCurrentAdmins = async (req, res) => {
    try {
        const admins = await Admin.find();
        const adminEmails = admins.map(admin => admin.email); // Directly retrieve emails
        res.status(200).json({ admins: adminEmails });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching admins', error });
    }
};
