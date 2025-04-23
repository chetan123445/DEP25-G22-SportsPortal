import User from '../models/User.js';
import bcrypt from 'bcrypt';

const validatePassword = (password) => {
  // Length check
  if (password.length < 6 || password.length > 15) {
    return {
      isValid: false,
      message: 'Password length must be between 6 and 15 characters'
    };
  }

  // Regex for password requirements
  const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/;
  if (!passwordRegex.test(password)) {
    return {
      isValid: false,
      message: 'Password must contain at least one letter, one number, and one special character'
    };
  }

  return { isValid: true };
};

export const changePassword = async (req, res) => {
    try {
        const { email, oldPassword, newPassword } = req.body;

        // Validate new password format
        const validationResult = validatePassword(newPassword);
        if (!validationResult.isValid) {
            return res.status(400).json({ message: validationResult.message });
        }

        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Verify old password
        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Incorrect old password' });
        }

        // Check if new password is same as old password
        const isSamePassword = await bcrypt.compare(newPassword, user.password);
        if (isSamePassword) {
            return res.status(400).json({ message: 'New password cannot be the same as old password' });
        }

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        user.password = hashedPassword;
        await user.save();

        res.status(200).json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error('Error in changePassword:', error);
        res.status(500).json({ message: 'Error changing password', error: error.message });
    }
};
