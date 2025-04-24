import User from '../models/User.js';
import { otpStore } from '../utils/otpStore.js';

export const verify_email = async (req, res) => {
    try {
        const { email, otp } = req.body;

        // Get stored OTP data
        const storedData = otpStore.getOtp(email);
        
        if (!storedData) {
            return res.status(400).json({ message: "OTP expired or not found" });
        }

        // Compare OTPs
        if (parseInt(otp) !== parseInt(storedData.storedOtp)) {
            return res.status(400).json({ message: "Invalid OTP" });
        }

        // Create new user
        const newUser = new User({
            email,
            name: storedData.name,
            password: storedData.hashedPassword,
            verified: true
        });

        await newUser.save();
        
        // Clear OTP after successful verification
        otpStore.deleteOtp(email);

        return res.status(200).json({
            message: "Email verified successfully",
            user: {
                email: newUser.email,
                name: newUser.name
            }
        });

    } catch (error) {
        console.error('Error in verify_email:', error);
        return res.status(500).json({ 
            message: "Internal Server Error",
            error: error.message 
        });
    }
};