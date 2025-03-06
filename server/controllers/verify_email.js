import bcrypt from "bcrypt";
import admin from "firebase-admin";
import User from '../models/User.js'; // Ensure consistent casing

export const verify_email = async (req, res) => {
    const { email, name, password } = req.body;

    try {
        // Check if the email is verified in Firebase
        const firebaseUser = await admin.auth().getUserByEmail(email);

        if (!firebaseUser.emailVerified) {
            return res.status(400).json({ message: "Email not verified yet!" });
        }

        // Check if user already exists in MongoDB (to prevent duplicates)
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "User already registered!" });
        }

        // Store user in MongoDB
        const newUser = new User({
            name,
            email,
            password: await bcrypt.hash(password, 10), // Hash this before storing in real applications
            isVerified: true,
        });

        await newUser.save();

        return res.status(200).json({ message: "User registered successfully!" });

    } catch (error) {
        console.error("Error verifying email:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};