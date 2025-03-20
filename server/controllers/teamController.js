import Team from '../models/Team.js';

export const getTeamDetails = async (req, res) => {
    const { teamId } = req.params;

    try {
        const team = await Team.findById(teamId).populate('members.userId', 'name email');
        if (!team) {
            return res.status(404).json({ message: 'Team not found' });
        }
        res.status(200).json({ team });
    } catch (error) {
        console.error('Error fetching team details:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
