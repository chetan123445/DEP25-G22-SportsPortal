import mongoose from 'mongoose';

const IYSCeventSchema = new mongoose.Schema({
    gender: { type: String, required: true },
    eventType: { type: String, required: true },
    type: { type: String, required: true },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    venue: { type: String, required: true },
    description: { type: String, required: false },
    winner: { type: String, required: false },
    team1: { type: String, required: true },
    team2: { type: String, required: true },
    team1Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false },
    team2Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false },
});

const IYSCevent = mongoose.model('IYSCevent', IYSCeventSchema);

export default IYSCevent; // Use ES6 export syntax