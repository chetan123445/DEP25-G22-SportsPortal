import User from '../models/User.js';

export const getPlayerDetails = async (req, res) => {
  const { email } = req.params;

  try {
    const user = await User.findOne({ email });

    if (user) {
      // If user is found, return all their details
      return res.status(200).json({
        success: true,
        data: {
          name: user.name,
          email: user.email,
          mobileNo: user.mobileNo || '',
          DOB: user.DOB ? user.DOB.toISOString().split('T')[0] : '',
          Degree: user.Degree || '',
          Department: user.Department || '',
          CurrentYear: user.CurrentYear || '',
          ProfilePic: user.ProfilePic || '',
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
