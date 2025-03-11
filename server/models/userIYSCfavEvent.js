import mongoose from 'mongoose';

const userIYSCfavSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'IYSCevent', required: true },
});

const userIYSCfavEvent = mongoose.model('userIYSCfavEvent', userIYSCfavSchema);

export default userIYSCfavEvent;