import express from 'express';
import { signup } from '../controllers/signup.js';
import { verify_email } from '../controllers/verify_email.js';
import { login } from '../controllers/login.js';
import { getProfile } from '../controllers/profile.js';
import { updateProfile, uploadProfilePic, removeProfilePic, upload } from '../controllers/editProfile.js';
import { addIYSCevent } from '../controllers/addIYSCevent.js';
import { addGCEvent } from '../controllers/addGCevent.js';
import { addIRCCevent } from '../controllers/addIRCCevent.js';
import { addPHLevent } from '../controllers/addPHLevent.js';
import { addBasketBrawlevent } from '../controllers/addBasketBrawlevent.js';
import { getLiveEvents, getUpcomingEvents, getPastEvents } from '../controllers/events.js';
import { getIYSCevent, getGCevent, getIRCCevent, getPHLevent, getBasketBrawlevent } from '../controllers/getParticularEvent.js';
import { updateIYSCevent, updateGCevent, updateIRCCevent, updatePHLevent, updateBasketBrawlevent } from '../controllers/updateParticularEvent.js';
import { addFavouriteEvent } from '../controllers/addFavouriteEvent.js';
import { removeFavouriteEvent } from '../controllers/removeFavouriteEvent.js';
import { verifyFavouriteEvent } from '../controllers/verifyFavouriteEvent.js';
import { getFavouriteEvent } from '../controllers/getFavouriteEvent.js';
import { getTeamDetails, getTeamDetailsByName } from '../controllers/teamController.js'; // Import the new controller
import { getEventParticipants } from '../controllers/participantsController.js'; // Import the new controller
import { addAdmin, verifyAdmin } from '../controllers/Admin.js'; // Import the verifyAdmin controller
import { getAllPlayersWithDetails, getAllPlayersFromTeams } from '../controllers/playersController.js'; // Import the updated controller
import { getPlayerDetails } from '../controllers/playerProfileController.js'; // Import the new controller
import { getUserEvents } from '../controllers/userEventsController.js'; // Import the new controller
import { getManagedEvents } from '../controllers/managedEventsController.js'; // Import the new controller
import { getAllEvents, updateEvent } from '../controllers/allEvents.js';

const router = express.Router();

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
router.get("/get-gc-events", getGCevent);
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
router.get("/all-players", getAllPlayersWithDetails); // Add route for fetching all players with details
router.get("/all-players-from-teams", getAllPlayersFromTeams); // Add route for fetching all players from teams
router.get("/player-details/:email", getPlayerDetails); // Add route to fetch player details
router.get("/my-events", getUserEvents); // Add route for fetching user-specific events
router.get("/managed-events", getManagedEvents); // Add route for fetching managed events

// Add these new routes
router.get("/all-events", getAllEvents);
router.patch("/update-event", updateEvent);

export default router;