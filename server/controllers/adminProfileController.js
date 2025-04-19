import Admin from '../models/admin.js';
import User from '../models/User.js';
import bcrypt from 'bcrypt';

export const getAdminProfile = async (req, res) => {
  const { email } = req.params;

  try {
    const user = await User.findOne({ email });

    if (user) {
      // Convert user to object and handle profile picture
      const userData = user.toObject();
      if (userData.ProfilePic) {
        userData.ProfilePic = `data:image/jpeg;base64,${userData.ProfilePic.toString('base64')}`;
      }

      return res.status(200).json({
        success: true,
        data: {
          name: userData.name,
          email: userData.email,
          mobileNo: userData.mobileNo || '',
          DOB: userData.DOB ? userData.DOB.toISOString().split('T')[0] : '',
          Degree: userData.Degree || '',
          Department: userData.Department || '',
          CurrentYear: userData.CurrentYear || '',
          ProfilePic: userData.ProfilePic || '',
          isAdmin: true, // Added to indicate admin status
          role: userData.role || 'Admin', // Added role field
          adminSince: userData.adminSince || new Date().toISOString().split('T')[0], // Added admin join date
        },
      });
    } else {
      // If user is not found, return only the email and name
      return res.status(404).json({
        success: false,
        message: 'User not registered',
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error fetching player details',
      error: error.message,
    });
  }
};
