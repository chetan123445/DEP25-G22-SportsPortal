import nodemailer from "nodemailer";
import bcrypt from "bcrypt";
import User from '../models/User.js'; // Ensure consistent casing
import { otpStore } from '../utils/otpStore.js'; // Import the OTP store utility

// Configure Nodemailer
const transporter = nodemailer.createTransport({
    service: 'gmail', // Use your email service provider
    auth: {
        user: process.env.EMAIL, // Your email address
        pass: process.env.EMAIL_PASSWORD // Your email password
    }
});

export const signup = async (req, res) => {
    const { email: rawEmail, name, password } = req.body;
    const email = rawEmail?.trim().toLowerCase();

    // Log the request body to verify its contents
    console.log("Request Body:", req.body);

    try {
        // Ensure email is defined
        if (!email) {
            return res.status(400).json({ message: "Email is required." });
        }

        // Check if user already exists in MongoDB
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "Email already registered." });
        }

        // Hash Password Before Storing
        const hashedPassword = await bcrypt.hash(password, 10);

        // Generate a random 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000);

        // Store OTP, name, and hashed password in the temporary store
        otpStore.setOtp(email, otp, name, hashedPassword);

        // Send OTP via email
        const mailOptions = {
            from: process.env.EMAIL,
            to: email,
            subject: 'Email Verification OTP',
            text: `Your OTP for email verification is: ${otp}. It is valid for 10 minutes.`
        };

        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.error("Error sending email:", error);
                return res.status(500).json({ message: "Error sending OTP email." });
            } else {
                console.log('Email sent: ' + info.response);
                return res.status(200).json({ 
                    message: "OTP sent to your email. Please verify your email to complete registration."
                });
            }
        });

    } catch (error) {
        console.error("Error during signup process:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};