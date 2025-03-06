import nodemailer from "nodemailer";
import bcrypt from "bcrypt";
import admin from "firebase-admin";
import User from '../models/User.js'; // Ensure consistent casing

// Configure Nodemailer
const transporter = nodemailer.createTransport({
    service: 'gmail', // Use your email service provider
    auth: {
        user: process.env.EMAIL, // Your email address
        pass: process.env.EMAIL_PASSWORD // Your email password
    }
});

export const signup = async (req, res) =>  {
    const { email, name, password } = req.body;

    try {
        // Ensure email is from IIT Ropar
        if (!email.endsWith("@iitrpr.ac.in")) {
            return res.status(400).json({ message: "Only IIT Ropar emails are allowed." });
        }

        // Check if user already exists in MongoDB
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "Email already registered." });
        }

        // Hash Password Before Storing
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create user in Firebase Authentication
        const firebaseUser = await admin.auth().createUser({
            email,
            password,
            displayName: name,
        });

        // Generate Firebase Email Verification Link with 20-second expiration
        const actionCodeSettings = {
            url: `http://localhost:3000/api/auth/check-email?email=${email}&expirationTime=${Date.now() + 20 * 1000}`,
            handleCodeInApp: false,
        };

        const link = await admin.auth().generateEmailVerificationLink(email, actionCodeSettings);

        // Send verification link via email
        const mailOptions = {
            from: process.env.EMAIL,
            to: email,
            subject: 'Email Verification',
            text: `Please verify your email by clicking on the following link: ${link}`
        };

        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.error("Error sending email:", error);
                return res.status(500).json({ message: "Error sending verification email." });
            } else {
                console.log('Email sent: ' + info.response);
                return res.status(200).json({ 
                    message: "Verification email sent. Please verify your email to complete registration."
                });
            }
        });

    } catch (error) {
        console.error("Error generating verification link:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};