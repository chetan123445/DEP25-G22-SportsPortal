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
        type: String, 
        required: false,
        validate: {
            validator: function(v) {
                // Allow null/empty values since it's not required
                if (!v) return true;
                // Basic path validation
                return v.match(/^uploads\/.*\.(jpg|jpeg|png|gif)$/i);
            },
            message: 'Invalid profile picture path format'
        }
    },
});

const User = mongoose.model('User', userSchema);

export default User;