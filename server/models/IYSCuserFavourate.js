import mongoose from 'mongoose';
import User from './User';
import IYSCevent from './IYSCevent';

const IYSCuserFavourateSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'IYSCevent', required: true },
});

const IYSCuserFavourate = mongoose.model('IYSCuserFavourate', IYSCuserFavourateSchema);

export default IYSCuserFavourate;
