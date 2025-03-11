import mongoose from 'mongoose';

const userIRCCfavSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'IRCCevent', required: true },
});

const userIRCCfavEvent = mongoose.model('userIRCCfavEvent', userIRCCfavSchema);

export default userIRCCfavEvent;
