import User from '../models/User.js';
import { alternativeEmailOtpStore } from '../utils/alternativeEmailOtpStore.js';

export const verifyAlternativeEmail = async (req, res) => {
    try {
        const { email, otp, mainEmail } = req.body;
        console.log('Verifying alternative email:', { email, otp, mainEmail }); // Debug log

        const storedOtp = alternativeEmailOtpStore.getOtp(email);
        console.log('Stored OTP:', storedOtp, 'Received OTP:', otp); // Debug log

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

        alternativeEmailOtpStore.deleteOtp(email);

        res.status(200).json({ 
            message: 'Alternative email verified successfully',
            alternativeEmail: email
        });

    } catch (error) {
        console.error('Error in verifyAlternativeEmail:', error);
        res.status(500).json({ message: "Internal Server Error" });
    }
};
