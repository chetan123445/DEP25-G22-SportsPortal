import User from '../models/User.js';

export const getPlayerDetails = async (req, res) => {
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
