// Used to fix Fall in Death's Map 1 broken beginning safe room
// Refer to the corresponding stripper file.

function TeleSurvivors()
{
	zoey <- Entities.FindByModel(null, "models/survivors/survivor_teenangst.mdl");
	bill <- Entities.FindByModel(null, "models/survivors/survivor_namvet.mdl");
	francis <- Entities.FindByModel(null, "models/survivors/survivor_biker.mdl");
	louis <- Entities.FindByModel(null, "models/survivors/survivor_manager.mdl");
	
	
	if (!(zoey && bill && francis && louis)) {
		// For some reason not all survivors are available yet
		// so don't do anything.
		return;
	}
	
	pos <- zoey.GetOrigin();
	
	if (pos.x < 400.000000) {
		// Assume we already teleported the survivors and kill the timer
		EntFire( "saferoom_timer", "Disable", 0 );
		return;
	}
	
	//; Positions:
	//;151.643723 -1832.437866 271.428406;;
	//;207.540466 -1616.994995 286.031250;
	//;599.827576 -1711.944824 182.031250;
	//;532.110596 -1407.028809 290.492920;
	
	pos.x = 151.643723;
	pos.y = -1832.437866;
	pos.z = 271.428406;
	zoey.SetOrigin(pos);
	
	// 376.973969 -1731.328979 250.428452;
	pos <- bill.GetOrigin();
	pos.x = 207.540466;
	pos.y = -1616.994995;
	pos.z = 286.031250;
	bill.SetOrigin(pos);
	
	// 199.813202 -1341.973877 312.285370;
	pos <- francis.GetOrigin();
	pos.x = 599.827576;
	pos.y = -1711.944824;
	pos.z = 182.031250;
	francis.SetOrigin(pos);
	
	// 492.152100 -1599.604614 226.736008;
	pos <- louis.GetOrigin();
	pos.x = 532.110596;
	pos.y = -1407.028809;
	pos.z = 290.492920;
	louis.SetOrigin(pos);

}

TeleSurvivors();