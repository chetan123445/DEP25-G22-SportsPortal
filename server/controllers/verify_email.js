import bcrypt from "bcrypt";
import User from '../models/User.js'; // Ensure consistent casing
import { otpStore } from '../utils/otpStore.js'; // Utility to handle OTP storage (e.g., Redis or in-memory)

export const verify_email = async (req, res) => {
    const { email, otp } = req.body;

    try {
        // Ensure email and OTP are provided
        if (!email || !otp) {
            return res.status(400).json({ message: "Email and OTP are required." });
        }

        // Normalize email to lowercase
        const normalizedEmail = email.toLowerCase();

        // Retrieve the stored OTP data for the email
        const otpData = await otpStore.getOtpData(normalizedEmail);

        // Log the stored and received OTP for debugging
        console.log("Stored OTP Data:", otpData);
        console.log("Received OTP:", otp);

        // Check if OTP matches
        if (!otpData || otpData.otp.toString() !== otp.toString()) {
            return res.status(400).json({ message: "Invalid or expired OTP." });
        }

        // Check if user already exists in MongoDB (to prevent duplicates)
        const existingUser = await User.findOne({ email: normalizedEmail });
        if (existingUser) {
            return res.status(400).json({ message: "User already registered!" });
        }

        // Mark the user as verified and save to MongoDB
        const newUser = new User({
            email: normalizedEmail,
            name: otpData.name,
            password: otpData.hashedPassword, // Save the hashed password
            isVerified: true,
        });

        await newUser.save();

        // Remove the OTP from the store after successful verification
        await otpStore.deleteOtp(normalizedEmail);

        return res.status(200).json({ message: "Email verified and user registered successfully!" });

    } catch (error) {
        console.error("Error verifying email:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};