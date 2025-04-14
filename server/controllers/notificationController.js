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

        // Only get unread notifications and sort by timestamp
        const unreadNotifications = user.notifications
            .filter(n => !n.read)
            .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        res.status(200).json({ 
            message: 'Notifications fetched successfully',
            notifications: unreadNotifications,
            unreadCount: unreadNotifications.length
        });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ 
            message: 'Error fetching notifications',
            error: error.message,
            notifications: [],
            unreadCount: 0
        });
    }
};

export const sendNotification = async (req, res) => {
    try {
        const { message, eventType, date, venue } = req.body;
        
        const notification = {
            message,
            timestamp: new Date(),
            read: false,  // Always set new notifications as unread
            eventType,
            date,
            venue
        };

        // Update all users with the new notification
        await User.updateMany(
            {},
            {
                $push: { 
                    notifications: { 
                        $each: [notification],
                        $position: 0
                    }
                }
            }
        );

        res.status(200).json({ message: 'Notifications sent successfully' });
    } catch (error) {
        res.status(500).json({ 
            message: 'Error sending notifications', 
            error: error.message 
        });
    }
};

export const markSingleNotificationAsRead = async (req, res) => {
    try {
        const { email, notificationId } = req.body;
        
        if (!email || !notificationId) {
            return res.status(400).json({ message: 'Email and notification ID are required' });
        }

        const user = await User.findOneAndUpdate(
            { 
                email,
                "notifications._id": notificationId 
            },
            { 
                $set: { "notifications.$.read": true }
            },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User or notification not found' });
        }

        const unreadCount = user.notifications.filter(n => !n.read).length;

        res.status(200).json({ 
            message: 'Notification marked as read',
            unreadCount
        });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({ message: 'Error updating notification' });
    }
};
