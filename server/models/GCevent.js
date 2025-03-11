import mongoose from 'mongoose';

const GCeventSchema = new mongoose.Schema({
    MainType: { type: String, required: true },
    type: { type: String, required: true },
    gender: { type: String, required: false },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    venue: { type: String, required: true },
    description: { type: String, required: false },
    winner: { type: String, required: false },
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false }], // Array of team IDs
});

const GCevent = mongoose.model('GCevent', GCeventSchema);

export default GCevent; // Use ES6 export syntax
