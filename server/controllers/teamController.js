import mongoose from 'mongoose';
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

// Update team players
export const updateTeam = async (req, res) => {
    try {
        const { teamId } = req.params;
        const { players } = req.body;

        console.log('Updating team:', teamId);
        console.log('With players:', players);

        // Validate teamId
        if (!mongoose.isValidObjectId(teamId)) {
            return res.status(400).json({ message: 'Invalid team ID format' });
        }

        // Validate players array
        if (!Array.isArray(players)) {
            return res.status(400).json({ message: 'Players must be an array' });
        }

        // Find and update team
        const team = await Team.findById(teamId);
        if (!team) {
            return res.status(404).json({ message: 'Team not found' });
        }

        // Update members with the new players array
        team.members = players;
        await team.save();
        
        console.log('Team updated successfully:', team);

        res.status(200).json({
            message: 'Team updated successfully',
            team: {
                _id: team._id,
                teamName: team.teamName,
                members: team.members
            }
        });
    } catch (error) {
        console.error('Error updating team:', error);
        res.status(500).json({ 
            message: 'Error updating team', 
            error: error.message,
            stack: error.stack 
        });
    }
};

// Create new team
export const createTeam = async (req, res) => {
    try {
        const { teamName, members } = req.body;

        const newTeam = new Team({
            teamName,
            members: members.map(member => ({
                name: member.name,
                email: member.email
            }))
        });

        await newTeam.save();
        res.status(200).json({ message: 'Team created successfully', _id: newTeam._id });
    } catch (error) {
        console.error('Error creating team:', error);
        res.status(500).json({ message: 'Error creating team', error: error.message });
    }
};
