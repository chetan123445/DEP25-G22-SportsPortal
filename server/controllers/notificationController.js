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
        const { message, eventType, date, time, venue, team1, team2 } = req.body;
        
        // Build notification object based on event type
        const notification = {
            message,
            eventType,
            date,
            time,
            venue,
            // Only include team1 and team2 if they are provided (non-GC events)
            ...(team1 && { team1 }),
            ...(team2 && { team2 }),
            read: false
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
            { email },
            { 
                $pull: { notifications: { _id: notificationId } }
            },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User or notification not found' });
        }

        const unreadCount = user.notifications.filter(n => !n.read).length;

        res.status(200).json({ 
            message: 'Notification deleted successfully',
            unreadCount
        });
    } catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({ message: 'Error deleting notification' });
    }
};

export const deleteAllNotifications = async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }

        const user = await User.findOneAndUpdate(
            { email },
            { $set: { notifications: [] } },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ 
            message: 'All notifications deleted successfully',
            unreadCount: 0
        });
    } catch (error) {
        console.error('Error deleting all notifications:', error);
        res.status(500).json({ message: 'Error deleting notifications' });
    }
};
