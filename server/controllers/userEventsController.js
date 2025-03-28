import IRCCevent from '../models/IRCCevent.js';
import IYSCevent from '../models/IYSCevent.js';
import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';
import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';
import User from '../models/User.js';

export const getUserEvents = async (req, res) => {
  const { email } = req.query;

  try {
    // Find teams where the user is a member based on email
    const teams = await Team.find({ 'members.email': email });
    const teamIds = teams.map(team => team._id);

    // Fetch non-GC events where the user's team is participating
    const irccEvents = await IRCCevent.find({
      $or: [{ team1Details: { $in: teamIds } }, { team2Details: { $in: teamIds } }],
    })
      .select('eventType venue description date time gender winner team1 team2')
      .populate('team1Details', 'teamName') // Fetch team1 name
      .populate('team2Details', 'teamName'); // Fetch team2 name

    const iyscEvents = await IYSCevent.find({
      $or: [{ team1Details: { $in: teamIds } }, { team2Details: { $in: teamIds } }],
    })
      .select('eventType venue description date time gender winner team1 team2')
      .populate('team1Details', 'teamName') // Fetch team1 name
      .populate('team2Details', 'teamName'); // Fetch team2 name

    const phlEvents = await PHLevent.find({
      $or: [{ team1Details: { $in: teamIds } }, { team2Details: { $in: teamIds } }],
    })
      .select('eventType venue description date time gender winner team1 team2')
      .populate('team1Details', 'teamName') // Fetch team1 name
      .populate('team2Details', 'teamName'); // Fetch team2 name

    const basketBrawlEvents = await BasketBrawlevent.find({
      $or: [{ team1Details: { $in: teamIds } }, { team2Details: { $in: teamIds } }],
    })
      .select('eventType venue description date time gender winner team1 team2')
      .populate('team1Details', 'teamName') // Fetch team1 name
      .populate('team2Details', 'teamName'); // Fetch team2 name

    // Fetch GC events where the user's team is participating
    const gcEvents = await GCevent.find({
      participants: { $in: teamIds },
    }).select('eventType venue description date time gender winner');

    // Combine all events into a single array
    const allEvents = [
      ...irccEvents,
      ...iyscEvents,
      ...phlEvents,
      ...basketBrawlEvents,
      ...gcEvents,
    ];

    if (allEvents.length === 0) {
      return res.status(200).json({ events: [], message: 'No events for you.' });
    }

    res.status(200).json({ events: allEvents });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error fetching user events' });
  }
};
