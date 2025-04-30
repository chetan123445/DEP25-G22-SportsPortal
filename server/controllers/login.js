import User from '../models/User.js';
import bcrypt from 'bcrypt';
import generateToken from '../utils/token.js';

export const login = async (req, res) => {
    const { email: rawEmail, password } = req.body;
    const email = rawEmail?.trim().toLowerCase();

    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: "User not registered yet" });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Password incorrect" });
        }

        const token = generateToken(user);

        // Include userId and email in response
        res.status(200).json({ 
            message: "Login successful", 
            token,
            userId: user._id,
            email: user.email // Add email to response
        });
    } catch (error) {
        console.error('Login error:', error); // Add error logging
        res.status(500).json({ message: "Server error" });
    }
};
