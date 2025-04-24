import User from '../models/User.js';
import { alternativeEmailOtpStore } from '../utils/alternativeEmailOtpStore.js';
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
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        
        alternativeEmailOtpStore.setOtp(email, otp);
        console.log('Stored OTP:', otp, 'for email:', email); // Debug log

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
                message: "OTP sent to your alternative email"
            });
        });

    } catch (error) {
        console.error('Error in updateAlternativeEmail:', error);
        res.status(500).json({ message: 'Error updating alternative email', error: error.message });
    }
};

export const verifyAlternativeEmail = async (req, res) => {
    const { email, otp, mainEmail } = req.body;

    try {
        // Use the new store
        const storedOtp = alternativeEmailOtpStore.getOtp(email);
        console.log("Stored OTP:", storedOtp, "Received OTP:", otp);

        if (!storedOtp) {
            return res.status(400).json({ message: "OTP expired or not found" });
        }

        if (storedOtp !== otp.toString()) {
            return res.status(400).json({ message: "Invalid OTP" });
        }

        const user = await User.findOneAndUpdate(
            { email: mainEmail },
            { alternativeEmail: email },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Clear OTP after successful verification
        alternativeEmailOtpStore.deleteOtp(email);

        res.status(200).json({ 
            message: 'Alternative email verified and updated successfully',
            alternativeEmail: email
        });

    } catch (error) {
        console.error("Error verifying alternative email:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
};
