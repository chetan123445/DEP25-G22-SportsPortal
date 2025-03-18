import mongoose from 'mongoose';

const userPHLfavSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'PHLevent', required: true },
});

const userPHLfavEvent = mongoose.model('userPHLfavEvent', userPHLfavSchema);

export default userPHLfavEvent;
