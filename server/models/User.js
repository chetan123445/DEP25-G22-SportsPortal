import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    isVerified: { type: Boolean, default: false },
    mobileNo: { type: Number, required: false },
    DOB: { type: Date, required: false },
    Degree: { type: String, required: false },
    Department: { type: String, required: false },
    CurrentYear: { 
        type: Number, 
        required: false,
        validate: {
            validator: function(v) {
                // Ensure the value is a number
                return !isNaN(v);
            },
            message: 'CurrentYear must be a number'
        }
    },
    ProfilePic: { 
        type: Buffer, // Changed from String to Buffer to store binary data
        required: false
    },
    notifications: [{
        message: { type: String, required: true },
        timestamp: { type: Date, default: Date.now },
        read: { type: Boolean, default: false },
        eventType: String,
        date: String,
        venue: String
    }],
});

const User = mongoose.model('User', userSchema);

export default User;