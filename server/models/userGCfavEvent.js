import mongoose from 'mongoose';

const userGCfavSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'GCevent', required: true },
});

const userGCfavEvent = mongoose.model('userGCfavEvent', userGCfavSchema);

export default userGCfavEvent;
