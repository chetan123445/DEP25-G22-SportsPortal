import express from 'express';
import User from '../models/User.js';

const router = express.Router();

// Get user notifications
router.get('/', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ 
                message: 'Email is required',
                notifications: [] 
            });
        }

        const user = await User.findOne({ email: email });
        
        if (!user) {
            return res.status(200).json({ 
                message: 'No notifications found',
                notifications: [] 
            });
        }

        // Sort notifications by timestamp in descending order (newest first)
        const sortedNotifications = user.notifications.sort((a, b) => 
            new Date(b.timestamp) - new Date(a.timestamp)
        );

        res.status(200).json({ 
            message: 'Notifications fetched successfully',
            notifications: sortedNotifications 
        });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ 
            message: 'Error fetching notifications',
            error: error.message,
            notifications: []
        });
    }
});

// Send notifications to all users
router.post('/send', async (req, res) => {
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
        res.status(500).json({ message: 'Error sending notifications', error: error.message });
    }
});

// Add new route to mark notifications as read
router.post('/mark-read', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }

        const user = await User.findOne({ email });
        
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Update all notifications to read
        await User.updateOne(
            { email },
            { $set: { "notifications.$[].read": true } }
        );

        res.status(200).json({ message: 'Notifications marked as read' });
    } catch (error) {
        res.status(500).json({ 
            message: 'Error marking notifications as read', 
            error: error.message 
        });
    }
});

export default router;
