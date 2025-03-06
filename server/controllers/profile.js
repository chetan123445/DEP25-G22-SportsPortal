import User from "../models/User.js";

export const getProfile = async (req, res) => {
    const { email } = req.query;
    console.log(`Received email to fetch users: ${email}`);
  
    try {
      const trimmedEmail = email.trim().toLowerCase();
      console.log(`Trimmed and lowercased email: ${trimmedEmail}`);
  
      const data = await User.find({ email: trimmedEmail }).select('-password');
      console.log(`Database query result: ${data}`);
  
      res.status(200).json({ data });
    } catch (error) {
      console.error('Failed to fetch users:', error);
      res.status(500).json({ error: 'Failed to fetch users' });
    }
};