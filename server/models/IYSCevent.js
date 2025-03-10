import mongoose from 'mongoose';

const IYSCeventSchema = new mongoose.Schema({
    gender: {type: String, required: true},
    type: { type: String, required: true },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    venue: { type: String, required: true },
    description: { type: String, required: true },
    winner: { type: String, required: false },
});

const IYSCevent = mongoose.model('IYSCevent', IYSCeventSchema);

export default IYSCevent;