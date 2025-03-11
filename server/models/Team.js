import mongoose from 'mongoose';

const TeamMemberSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false }
});

const TeamSchema = new mongoose.Schema({
    teamName: { type: String, required: true },
    members: [TeamMemberSchema] // Array of team members
});

const Team = mongoose.model('Team', TeamSchema);

export { TeamSchema }; // Export the schema
export default Team;
