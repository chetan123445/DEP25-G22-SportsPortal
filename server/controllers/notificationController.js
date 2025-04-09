import User from '../models/User.js';

export const getNotifications = async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ 
                message: 'Email is required',
                notifications: [] 
            });
        }

        const user = await User.findOne({ email });
        
        if (!user) {
            return res.status(200).json({ 
                message: 'No notifications found',
                notifications: [] 
            });
        }

        res.status(200).json({ 
            message: 'Notifications fetched successfully',
            notifications: user.notifications || [] 
        });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ 
            message: 'Error fetching notifications',
            error: error.message,
            notifications: []
        });
    }
};

export const sendNotification = async (req, res) => {
    try {
        const { message, eventType, date, venue } = req.body;
        
        // Find all users
        const users = await User.find({});
        
        // Add notification to each user
        const notification = {
            message,
            timestamp: new Date(),
            read: false,
            eventType,
            date,
            venue
        };

        await Promise.all(users.map(user => 
            User.findByIdAndUpdate(user._id, {
                $push: { 
                    notifications: { 
                        $each: [notification],
                        $position: 0  // Add new notifications at the beginning
                    }
                }
            })
        ));

        res.status(200).json({ message: 'Notifications sent successfully' });
    } catch (error) {
        res.status(500).json({ 
            message: 'Error sending notifications', 
            error: error.message 
        });
    }
};
