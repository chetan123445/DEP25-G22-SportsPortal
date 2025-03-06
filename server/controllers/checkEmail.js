import admin from "firebase-admin";
import User from "../models/User.js";

export const checkEmail = async (req, res) => {
    const { email, expirationTime } = req.query;

    try {
        if (Date.now() > parseInt(expirationTime)) {
            // Link has expired
            return res.status(400).json({ message: "Verification link has expired. Please sign up again." });
        }

        // Verify email in Firebase
        const user = await admin.auth().getUserByEmail(email);
        if (user.emailVerified) {
            // Email is verified
            return res.status(200).json({ message: "Email verified successfully." });
        } else {
            // Email is not verified
            return res.status(400).json({ message: "Email verification failed." });
        }
    } catch (error) {
        console.error("Error verifying email:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};
