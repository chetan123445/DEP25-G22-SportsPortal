import User from '../models/User.js';
import { otpStore } from '../utils/otpStore.js';
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
    }
});

export const getAlternativeEmail = async (req, res) => {
    try {
        const { email } = req.params;
        const user = await User.findOne({ email });
        
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ 
            alternativeEmail: user.alternativeEmail 
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching alternative email', error: error.message });
    }
};

export const updateAlternativeEmail = async (req, res) => {
    try {
        const { email } = req.body;

        // Generate OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Store OTP with timestamp - store as direct value, not object
        otpStore.setOtp(email, otp);

        // Send OTP via email
        const mailOptions = {
            from: process.env.EMAIL,
            to: email,
            subject: 'Alternative Email Verification',
            text: `Your OTP for alternative email verification is: ${otp}. Valid for 10 minutes.`
        };

        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.error("Error sending email:", error);
                return res.status(500).json({ message: "Error sending OTP email." });
            }
            return res.status(200).json({ 
                message: "OTP sent to your alternative email",
                otp: otp // Send OTP in response for testing
            });
        });

    } catch (error) {
        res.status(500).json({ message: 'Error updating alternative email', error: error.message });
    }
};

export const verifyAlternativeEmail = async (req, res) => {
    const { email, otp } = req.body;

    try {
        // Get stored OTP directly
        const storedOtp = otpStore.getOtp(email);
        console.log("Stored OTP:", storedOtp, "Received OTP:", otp); // Debug log

        if (!storedOtp) {
            return res.status(400).json({ message: "OTP expired or not found" });
        }

        if (storedOtp.toString() !== otp.toString()) {
            return res.status(400).json({ message: "Invalid OTP" });
        }

        // Important change: Use the main email to find and update the user
        const mainEmail = req.body.mainEmail; // Add this to frontend request
        const user = await User.findOneAndUpdate(
            { email: mainEmail },
            { alternativeEmail: email },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Clear OTP after successful verification
        otpStore.deleteOtp(email);

        res.status(200).json({ 
            message: 'Alternative email verified and updated successfully',
            alternativeEmail: email
        });

    } catch (error) {
        console.error("Error verifying alternative email:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
};
