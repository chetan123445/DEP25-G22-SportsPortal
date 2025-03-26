import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema({
  eventType: { type: String, required: true },
  team1Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
  team2Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
  participants: [
    {
      name: { type: String, required: true },
      email: { type: String, required: true },
    },
  ],
  // ...other fields as needed...
});

export default mongoose.model('Event', eventSchema);
