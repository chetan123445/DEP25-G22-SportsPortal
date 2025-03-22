import Team from '../models/Team.js';

export const getTeamDetails = async (req, res) => {
    try {
        const { teamId } = req.params;

        if (!teamId) {
            return res.status(400).json({ message: 'Team ID is required' });
        }

        const team = await Team.findById(teamId).exec(); // Ensure .exec() is used for proper query execution

        if (!team) {
            return res.status(404).json({ message: 'Team not found' });
        }

        res.status(200).json({ team });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching team details', error });
    }
};
