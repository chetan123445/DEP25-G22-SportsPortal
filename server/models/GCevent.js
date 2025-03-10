import mongoose from 'mongoose';

const GCeventSchema = new mongoose.Schema({
    MainType: { type: String, required: true },
    type: { type: String, required: true },
    date: { type: Date, required: true } // Add date attribute
});

const GCevent = mongoose.model('GCevent', GCeventSchema);

export default GCevent; // Use ES6 export syntax
