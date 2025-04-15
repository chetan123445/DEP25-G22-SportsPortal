import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';

export const updateGCEventTeams = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { teams, eventManagers } = req.body;  // Add eventManagers to destructuring

        const event = await GCevent.findById(eventId).populate('participants');
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        // Update event managers if provided
        if (eventManagers) {
            event.eventManagers = eventManagers;
        }

        // Keep track of existing team IDs that are still in use
        const existingTeamIds = event.participants.map(p => p._id.toString());
        const updatedTeamIds = [];

        // Update or create teams
        for (const team of teams) {
            try {
                if (team._id) {
                    // Update existing team
                    await Team.findByIdAndUpdate(
                        team._id,
                        {
                            teamName: team.teamName,
                            members: team.members
                        },
                        { new: true }
                    );
                    updatedTeamIds.push(team._id);
                } else {
                    // Create new team
                    const newTeam = new Team({
                        teamName: team.teamName,
                        members: team.members
                    });
                    await newTeam.save();
                    updatedTeamIds.push(newTeam._id);
                }
            } catch (error) {
                console.error('Error updating/creating team:', error);
                throw error;
            }
        }

        // Only delete teams that are no longer in the updated list
        const teamsToDelete = existingTeamIds.filter(
            id => !updatedTeamIds.includes(id)
        );
        if (teamsToDelete.length > 0) {
            await Team.deleteMany({ _id: { $in: teamsToDelete } });
        }

        // Update event with team IDs and event managers
        event.participants = updatedTeamIds;
        await event.save();

        // Fetch updated event with populated data
        const updatedEvent = await GCevent.findById(eventId)
            .populate('participants');

        res.status(200).json({
            message: 'Event updated successfully',
            event: updatedEvent
        });
    } catch (error) {
        console.error('Error updating GC event:', error);
        res.status(500).json({ message: 'Error updating event', error: error.message });
    }
};
