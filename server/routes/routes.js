import express from 'express';
import IRCCevent from '../models/IRCCevent.js';
import { signup } from '../controllers/signup.js';
import { verify_email } from '../controllers/verify_email.js';
import { login } from '../controllers/login.js';
import { getProfile } from '../controllers/profile.js';
import { updateProfile, uploadProfilePic, removeProfilePic, upload } from '../controllers/editProfile.js';
import { addIYSCevent, updateScore, addMatchCommentary as addIYSCCommentary, deleteCommentary as deleteIYSCCommentary, getEventDetails as getIYSCEventDetails, getIYSCStandings } from '../controllers/addIYSCevent.js';
import { addGCEvent, getGCEventsByMainType, addMatchCommentary as addGCCommentary, deleteCommentary as deleteGCCommentary, getEventDetails as getGCEventDetails, } from '../controllers/addGCevent.js';
import { addIRCCevent, updateScore as updateIRCCScore, addMatchCommentary as addIRCCCommentary, deleteCommentary as deleteIRCCCommentary, getEventDetails as getIRCCEventDetails, getIRCCStandings } from '../controllers/addIRCCevent.js';
import { addPHLevent, updateScore as updatePHLScore, addMatchCommentary as addPHLCommentary, deleteCommentary as deletePHLCommentary, getEventDetails as getPHLEventDetails, getPHLStandings } from '../controllers/addPHLevent.js';
import { addBasketBrawlevent, updateScore as updateBasketBrawlScore, addMatchCommentary as addBasketBrawlCommentary, deleteCommentary as deleteBasketBrawlCommentary, getEventDetails as getBasketBrawlEventDetails, getBasketBrawlStandings } from '../controllers/addBasketBrawlevent.js';
import { getLiveEvents, getUpcomingEvents, getPastEvents } from '../controllers/events.js';
import { getIYSCevent, getGCevent, getIRCCevent, getPHLevent, getBasketBrawlevent } from '../controllers/getParticularEvent.js';
import { updateIYSCevent, updateGCevent, updateIRCCevent, updatePHLevent, updateBasketBrawlevent } from '../controllers/updateParticularEvent.js';
import { addFavouriteEvent } from '../controllers/addFavouriteEvent.js';
import { removeFavouriteEvent } from '../controllers/removeFavouriteEvent.js';
import { verifyFavouriteEvent } from '../controllers/verifyFavouriteEvent.js';
import { getFavouriteEvent } from '../controllers/getFavouriteEvent.js';
import { getTeamDetails, getTeamDetailsByName, updateTeam, createTeam } from '../controllers/teamController.js'; // Import the new controller
import { getEventParticipants } from '../controllers/participantsController.js'; // Import the new controller
import { addAdmin, verifyAdmin, removeAdmin } from '../controllers/Admin.js'; // Import the verifyAdmin controller
import { getAllPlayersWithDetails, getAllPlayersFromTeams } from '../controllers/playersController.js'; // Import the updated controller
import { getPlayerDetails } from '../controllers/playerProfileController.js'; // Import the new controller
import { getUserEvents } from '../controllers/userEventsController.js'; // Import the new controller
import { getManagedEvents } from '../controllers/managedEventsController.js'; // Import the new controller
import { getAllEvents, updateEvent, deleteEvent } from '../controllers/allEvents.js';
import { getNotifications, sendNotification, markSingleNotificationAsRead, deleteAllNotifications } from '../controllers/notificationController.js'; // Add this importificationController.js';
import { addImage, getImages, deleteImages } from '../controllers/updateGallery.js'; // Import the functions from updateGallery.js
import { updateEventDetails } from '../controllers/updateEventController.js';
import { updateGCEventTeams } from '../controllers/GCeventController.js'; // Add new import for GC team management
import GC from '../models/GCevent.js'; // Change from GC.js to GCevent.js
import { sendOtp, verifyOtp, resetPassword } from '../controllers/forgotPasswordController.js';
import { getCurrentAdmins } from '../controllers/Admin.js'; // Import the getCurrentAdmins controller
import { getAdminProfile } from '../controllers/adminProfileController.js'; // Import the new controller
import { changePassword } from '../controllers/changePassword.js'; // Add this import

const router = express.Router();

// Add event manager verification middleware FIRST
const verifyEventManager = async (req, res, next) => {
  try {
    const { eventId } = req.body;
    const email = req.query.email; // Get email from query params
    
    console.log('Verifying event manager:', { eventId, email }); // Debug log

    if (!email) {
      console.log('No email provided');
      return res.status(403).json({ message: 'Email is required' });
    }

    const event = await IRCCevent.findById(eventId);
    if (!event) {
      console.log('Event not found:', eventId);
      return res.status(404).json({ message: 'Event not found' });
    }

    console.log('Event managers:', event.eventManagers); // Debug log
    // Check if the user's email matches any of the event managers' emails
    const isManager = event.eventManagers.some(manager => 
      manager.email.toLowerCase() === email.toLowerCase()
    );
    console.log('Is manager:', isManager, 'for email:', email); // Debug log

    if (!isManager) {
      return res.status(403).json({ message: 'Not authorized as event manager' });
    }

    req.event = event;
    next();
  } catch (error) {
    console.error('Error in verifyEventManager:', error);
    res.status(500).json({ message: 'Error verifying event manager', error });
  }
};

router.post("/signup", signup);
router.post("/verify-email", verify_email);
router.post("/login", login);

router.get("/profile", getProfile);
router.patch("/update-profile", updateProfile);

router.post("/add-IYSCevent", addIYSCevent);
router.post("/add-GCevent", addGCEvent);
router.post("/add-IRCCevent", addIRCCevent);
router.post("/add-PHLevent", addPHLevent);
router.post("/add-BasketBrawlevent", addBasketBrawlevent);

router.get("/live-events", getLiveEvents);
router.get("/upcoming-events", getUpcomingEvents);
router.get("/past-events", getPastEvents);

router.get("/get-iysc-events", getIYSCevent);
router.get("/get-gc-events", getGCEventsByMainType);
router.get("/get-ircc-events", getIRCCevent);
router.get("/get-phl-events", getPHLevent);
router.get("/get-basketbrawl-events", getBasketBrawlevent);

router.patch("/update-iysc-event", updateIYSCevent);
router.patch("/update-gc-event", updateGCevent);
router.patch("/update-ircc-event", updateIRCCevent);
router.patch("/update-phl-event", updatePHLevent);
router.patch("/update-basketbrawl-event", updateBasketBrawlevent);

router.post("/add-favourite-event", addFavouriteEvent);
router.delete("/remove-favourite-event", removeFavouriteEvent);
router.get("/verify-favourite-event", verifyFavouriteEvent);
router.get("/get-favourite-events", getFavouriteEvent);

router.post("/upload-profile-pic", upload.single('profilePic'), uploadProfilePic);
router.patch("/remove-profile-pic", removeProfilePic);

router.get("/get-team-details/:teamId", getTeamDetails); // Add route for fetching team details
router.get("/get-team-details-by-name/:teamName", getTeamDetailsByName); // Add route for fetching team details by name
router.get("/get-event-participants/:eventId", getEventParticipants); // Add route for fetching event participants
router.post("/add-admin", addAdmin); // Add route for adding an admin
router.post("/verify-admin", verifyAdmin); // Add route for verifying an admin
router.post("/remove-admin", removeAdmin); // Add route for removing an admin
router.get("/all-players", getAllPlayersWithDetails); // Add route for fetching all players with details
router.get("/all-players-from-teams", getAllPlayersFromTeams); // Add route for fetching all players from teams
router.get("/player-details/:email", getPlayerDetails); // Add route to fetch player details
router.get("/my-events", getUserEvents); // Add route for fetching user-specific events
router.get("/managed-events", getManagedEvents); // Add route for fetching managed events

// Add these new routes
router.get("/all-events", getAllEvents);
router.patch("/update-event", updateEvent);
router.delete("/delete-event/:eventId/:eventType", deleteEvent);

// Add these new routes for team management
router.put('/team/:teamId/players', updateTeam);
router.post('/create-team', createTeam);

// PHL Event Routes
router.post("/phl/update-score", updatePHLScore);
router.post("/phl/add-commentary", addPHLCommentary);
router.post("/phl/delete-commentary", deletePHLCommentary);
router.get("/phl/standings", getPHLStandings);
router.get("/phl/event/:eventId", getPHLEventDetails);

// BasketBrawl Event Routes
router.post("/basketbrawl/update-score", updateBasketBrawlScore);
router.post("/basketbrawl/add-commentary", addBasketBrawlCommentary);
router.post("/basketbrawl/delete-commentary", deleteBasketBrawlCommentary);
router.get("/basketbrawl/standings", getBasketBrawlStandings);
router.get("/basketbrawl/event/:eventId", getBasketBrawlEventDetails);

// IRCC Event Routes - Remove verifyEventManager middleware
router.post("/ircc/update-score", updateIRCCScore);
router.post("/ircc/add-commentary", addIRCCCommentary); 
router.post("/ircc/delete-commentary", deleteIRCCCommentary);
router.get("/ircc/event/:eventId", getIRCCEventDetails);
router.get("/ircc/standings", getIRCCStandings);

// Add IYSC Event Routes
router.post("/iysc/update-score", updateScore);
router.post("/iysc/add-commentary", addIYSCCommentary);
router.post("/iysc/delete-commentary", deleteIYSCCommentary);
router.get("/iysc/standings", getIYSCStandings);
router.get("/iysc/event/:eventId", getIYSCEventDetails);

// Add GC Event Routes - Update the route parameter format
router.get("/gc/event/:id", getGCEventDetails); // Changed from :eventId to :id to match controller
router.post("/gc/add-commentary", addGCCommentary);
router.post("/gc/delete-commentary", deleteGCCommentary);

// Add notification routes
router.get("/notifications", getNotifications);
router.post("/notifications/send", sendNotification);
router.post("/notifications/mark-single-read", markSingleNotificationAsRead);
router.post("/notifications/delete-all", deleteAllNotifications);  // Add this new route
// Add routes for gallery
router.post('/add-image', upload.single('image'), addImage); // Route to add an image
router.get('/get-images', getImages); // Route to get all imagesRoute to add an image
router.post('/delete-images', deleteImages); // New route for deleting images
// Add this new route before export default routerget all images
router.patch("/update-event-details", updateEventDetails);
router.patch("/update-event-details", updateEventDetails);
// Add new routes for managing GC event teams
router.put('/gc-event/:eventId/teams', updateGCEventTeams);
router.get('/gc-event/:eventId/teams', async (req, res) => {
    try {
        const event = await GC.findById(req.params.eventId).populate('participants');
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        res.json({ teams: event.participants });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching teams', error: error.message });
    }
});

// Add new routes for team management
router.get('/event/:eventId/:eventType/teams', async (req, res) => {
    try {
        const { eventId, eventType } = req.params;
        let EventModel;
        
        switch (eventType) {
            case 'IYSC': EventModel = IYSC; break;
            case 'IRCC': EventModel = IRCC; break;
            case 'PHL': EventModel = PHL; break;
            case 'BasketBrawl': EventModel = BasketBrawl; break;
            default:
                return res.status(404).json({ message: 'Invalid event type' });
        }

        const event = await EventModel.findById(eventId)
            .populate('team1Details')
            .populate('team2Details');

        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        res.json({
            team1: {
                name: event.team1,
                details: event.team1Details
            },
            team2: {
                name: event.team2,
                details: event.team2Details
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching teams', error: error.message });
    }
});

// Add route to update team details for non-GC events
router.put('/event/:eventId/:eventType/team/:teamNumber', async (req, res) => {
    try {
        const { eventId, eventType, teamNumber } = req.params;
        const { members } = req.body;
        let EventModel;

        switch (eventType) {
            case 'IYSC': EventModel = IYSC; break;
            case 'IRCC': EventModel = IRCC; break;
            case 'PHL': EventModel = PHL; break;
            case 'BasketBrawl': EventModel = BasketBrawl; break;
            default:
                return res.status(404).json({ message: 'Invalid event type' });
        }

        const event = await EventModel.findById(eventId);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const teamField = teamNumber === '1' ? 'team1Details' : 'team2Details';
        const teamId = event[teamField];

        if (teamId) {
            await Team.findByIdAndUpdate(teamId, { members });
        } else {
            const newTeam = new Team({
                teamName: event[teamNumber === '1' ? 'team1' : 'team2'],
                members
            });
            const savedTeam = await newTeam.save();
            event[teamField] = savedTeam._id;
            await event.save();
        }

        const updatedEvent = await EventModel.findById(eventId)
            .populate('team1Details')
            .populate('team2Details');

        res.json({ message: 'Team updated successfully', event: updatedEvent });
    } catch (error) {
        res.status(500).json({ message: 'Error updating team', error: error.message });
    }
});

router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);

router.post("/changePassword", changePassword); // Add this route

router.get("/current-admins", getCurrentAdmins); // Add this line before export default router
router.get("/admin-profile/:email", getAdminProfile); // Add route for fetching admin profile

export default router;