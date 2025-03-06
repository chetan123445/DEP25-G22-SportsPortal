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
    CurrentYear: { type: Number, required: false },
    ProfilePic: { type: String, required: false },
});

const User = mongoose.model('User', userSchema);

export default User;