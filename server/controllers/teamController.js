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

// Fetch team details by team name
export const getTeamDetailsByName = async (req, res) => {
  try {
    const { teamName } = req.params;

    if (!teamName) {
      return res.status(400).json({ message: 'Team name is required' });
    }

    // Use a case-insensitive regex to match the team name
    const team = await Team.findOne({ teamName: { $regex: `^${teamName}$`, $options: 'i' } }).exec();

    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }

    res.status(200).json({ team });
  } catch (error) {
    console.error('Error fetching team details by name:', error);
    res.status(500).json({ message: 'Error fetching team details', error });
  }
};
