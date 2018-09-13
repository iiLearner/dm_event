/* Dependencies */
#include <a_samp>
#include <zcmd> // zeex?
#include <YSI\y_iterate> // Y-Less
#include <streamer> // Incognito

/* definations (you can change) */
#define m_color 	"{bba7db}"
#define MAX_USERS   10 // max players allowed to join

/* script variables */
new bool:dmIsOpen=false, dmcount=0, bool:dmEventJoinable=false, bool:IsInDMEvent[MAX_PLAYERS], EventTimer;

//required for saving and loading the data.
enum PlayerData
{
    Float:playerPos[3],
    playerWeapons[13],
    playerAmmo[13],
    Float:playerHealth,
    Float:playerArmour
};
new pInfo[MAX_PLAYERS][PlayerData];

// event spawns
new Float:DMEventSpawn[10][4] =
{	// ls atrium
	{1722.3654,-1671.7581,23.6953,355.3468},
	{1710.7773,-1669.0027,23.7008,266.3593},
	{1710.7764,-1654.3403,23.6953,268.5527},
	{1715.4836,-1642.3696,23.6797,210.8987},
	{1730.5991,-1641.6003,23.7452,174.5517},
	{1732.2913,-1648.4950,23.7352,111.5711},
	{1732.2872,-1658.9349,23.7148,73.6574},
	{1734.5336,-1659.5815,20.2419,96.2175},
	{1734.5359,-1640.5709,20.2314,101.2309},
	{1701.2657,-1650.8356,20.2194,271.6857}
};

/* samp callbacks */
public OnFilterScriptInit()
{
    CreateEventMap();
    foreach(new i : Player) {RemoveBuildingForEvent(i), IsInDMEvent[i]=false;}
    return 1;
}
public OnPlayerConnect(playerid)
{
    RemoveBuildingForEvent(playerid);
    return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
    if(IsInDMEvent[playerid])
        dmcount--, IsInDMEvent[playerid]=false;
    return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
    if(IsInDMEvent[playerid])
    {
        SetPlayerVirtualWorld(playerid, 0);	
        SendClientMessage(playerid, -1, "{F81414}[DM Event]{FFAF00} You died in event thus you've been ejected from the event!");
        SetTimerEx("ResetEvent", 1500, false, "i", playerid);
        dmcount--;
    }
    return 1;
}

/* commands */
CMD:adminevent(playerid, params[])
{	
	if(IsPlayerAdmin(playerid))
	{
		if(dmIsOpen) return SendClientMessage(playerid, -1, ""m_color"There's already an ongoing event!");
        SendClientMessageToAll(-1, "{F81414}[DM Event] {FFAF00}Deathmatch event has been opened! type {6EF83C}/join{FFAF00} to join!");
        SendClientMessageToAll(-1,"{F81414}[DM Event] {FFAF00}Event equipment: AK-47, Rifle & Shotgun.");
        SendClientMessageToAll(-1, "{F81414}[DM Event] {FFAF00}You will NOT lose your weapons/stats once the event is over!");
        dmIsOpen=true;
        dmcount=0;	
        dmEventJoinable=true;
        SetTimer("StartDMEvent", 30000, false);
        return 1;	
    }
    return 1;
}
CMD:join(playerid)
{
    if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)  return SendClientMessage(playerid, -1, "You can not do this while spectating, /specoff");
    if(!IsInDMEvent[playerid])
    {
        if(dmIsOpen)
        {
            if(dmEventJoinable)
            {
                if(dmcount<MAX_USERS)
                {
                    new st[128];
                    SavePlayerData(playerid);
                    format(st, sizeof st, "{F81414}[DM Event] {ABD0BC}%s(%i) has signed up for DM event! (/join)",PlayerName(playerid), playerid);
                    SendClientMessageToAll(-1, st);
                    SendClientMessage(playerid, -1, "{F81414}[DM Event] {DEB887}You've signed up for the event! event will start shortly...");
                    IsInDMEvent[playerid]=true;
                    dmcount++;
                }
                else
                    SendClientMessage(playerid, -1, ""m_color"Sorry, event is full!");
            }
            else
                SendClientMessage(playerid, -1, ""m_color"Event can no longer be joined!");
        }  
        else
            SendClientMessage(playerid, -1, ""m_color"There's no ongoing event!");
    }
    else
        SendClientMessage(playerid, -1, ""m_color"You-ve already signed up for the event");
    return 1;
}

/* timers */
forward StartDMEvent();
public StartDMEvent()
{
	if(dmcount>=2)
	{
		new str[129];
		format(str, sizeof str, "{F81414}[DM Event]: {FFAF00}Death Match event is now starting with a total of %d players!",dmcount);
		SendClientMessageToAll(-1, str);
		PlaceInDM();
		foreach(new i : Player)
		{
			if(IsInDMEvent[i] && IsPlayerConnected(i))
			{
                		// setup the players
				TogglePlayerControllable(i, 0);
				ResetPlayerWeapons(i);	
				SetTimerEx("DmStart", 5000, false, "i", i);
				SetPlayerTeam(i, NO_TEAM);
				GivePlayerWeapon(i, 33, 20);
				GivePlayerWeapon(i, 25, 40);
				GivePlayerWeapon(i, 30, 100);
                		SetPlayerHealth(i, 100);
				SetPlayerSkin(i, 100);
				SetPlayerVirtualWorld(i, 1);
				dmEventJoinable=false;		
				//-----------------
					
			}
		}
		EventTimer = SetTimer("DmEventManager", 3000, true); //this function will manage the event
		SendClientMessageToAll(-1, "{F81414}[DM Event] {FFAF00}Event will start in 5 seconds... get ready!");
	}
	else
	{
		SendClientMessageToAll(-1,"{F81414}[DM Event] {FFAF00}Event did not start as there weren't enough players.");
		dmcount=0;
		dmIsOpen=false;
		dmEventJoinable=false;
		foreach(new i : Character)
		{
			if(IsInDMEvent[i])
			{
                //load back all players
				IsInDMEvent[i]=false;
				TogglePlayerControllable(i, 1);
				SetPlayerVirtualWorld(i, 0);
                LoadPlayerData(i);
			}
		}	
	}
}
forward DmEventManager();
public DmEventManager()
{
    if(dmcount==1)
    {
        new str[128], pid, Float:winner_health;
        SendClientMessageToAll(-1, "{F81414}[DM Event] {FFAF00}Event has ended.");
        foreach(new i : Player)
        {
            if(IsInDMEvent[i] && dmcount == 1)
            {
                pid = i;
                GetPlayerHealth(pid, winner_health);
                KillTimer(EventTimer);
                break;
            }
        }
        format(str, sizeof str, "{F81414}[DM Event] {FFAF00}%s(%i) has won the event with %f health! "m_color"(+3 weapons)",PlayerName(pid), pid, winner_health);
        SendClientMessageToAll(-1, str);
        SendClientMessage(pid, -1, "{F81414}[DM Event] {FFAF00} Congratulations! you won the event & +50 coins +3 weapons");
        ResetPlayerWeapons(pid);
        LoadPlayerData(pid);
        SetPlayerInterior(pid, 0);
        SetTimerEx("GiveRewards", 5000, false, "i", pid);
        dmIsOpen=false;
        IsInDMEvent[pid] = false;
    }
    return 1;
}
forward DmStart(playerid);
public DmStart(playerid)
{
	TogglePlayerControllable(playerid, 1);
	GameTextForPlayer(playerid, "Fight! Fight!", 3000, 4);
}
forward ResetEvent(playerid);
public ResetEvent(playerid)
{
    if(IsInDMEvent[playerid]) IsInDMEvent[playerid]=false, LoadPlayerData(playerid);
    return 1;
}
forward GiveRewards(playerid);
public GiveRewards(playerid)
{
	if(IsPlayerConnected(playerid))
	{
		SendClientMessage(playerid, -1, "{FFFFFF}The server has given you your rewards for winning the event!");
		GivePlayerWeapon(playerid, 34, 50);
		GivePlayerWeapon(playerid, 31, 100);
		GivePlayerWeapon(playerid, 29, 100);
	}
}

/* helpful functions */
PlaceInDM()
{
    new placed=0;
    foreach(new i : Player)
    {
        if(IsInDMEvent[i])
        {
            if(placed<MAX_USERS)
            {
                SetPlayerInterior(i, 18);
                new spawn = random(sizeof(DMEventSpawn));
                SetPlayerPos(i, DMEventSpawn[spawn][0], DMEventSpawn[spawn][1], DMEventSpawn[spawn][2]);
                SetPlayerFacingAngle(i, DMEventSpawn[spawn][3]);
                SendClientMessage(i, -1, "{FFFFFF}Los Santos Atrium map by: EpicDutchie");
                placed++;
            }
        }
    }
}
PlayerName(playerid)
{
    new pname[24];
    GetPlayerName(playerid, pname, sizeof pname);
    return pname;
}

/* saving and loading data */
SavePlayerData(playerid)
{
    GetPlayerPos(playerid,pInfo[playerid][playerPos][0],pInfo[playerid][playerPos][1],pInfo[playerid][playerPos][2]);
    GetPlayerHealth(playerid, pInfo[playerid][playerHealth]);
    GetPlayerArmour(playerid, pInfo[playerid][playerArmour]);
    for (new i = 0; i < 13; i++)
    {
        GetPlayerWeaponData(playerid, i,  pInfo[playerid][playerWeapons][i], pInfo[playerid][playerAmmo][i]);
    }
    return 1;
}
LoadPlayerData(playerid)
{
    SetPlayerPos(playerid, pInfo[playerid][playerPos][0],pInfo[playerid][playerPos][1],pInfo[playerid][playerPos][2]);
    SetPlayerHealth(playerid, pInfo[playerid][playerHealth]);
    SetPlayerArmour(playerid, pInfo[playerid][playerArmour]);
    for (new i = 0; i < 13; i++)
    {
		GivePlayerWeapon(playerid, pInfo[playerid][playerWeapons][i], pInfo[playerid][playerAmmo][i]);
        pInfo[playerid][playerWeapons][i]=-1;
        pInfo[playerid][playerAmmo][i]=-1;
    }
    return 1;
}


/* map related stuff */
CreateEventMap()
{
    CreateDynamicObject(944,1726.6701700,-1642.1031500,20.0897000,0.0000000,0.0000000,-1.0000000, 1); //
	CreateDynamicObject(944,1731.7543900,-1644.8342300,20.0897000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(944,1713.7297400,-1644.3764600,20.0897000,0.0000000,0.0000000,-140.0000000, 1); //
	CreateDynamicObject(1431,1732.2799100,-1650.1484400,19.7395000,0.0000000,0.0000000,91.0000000, 1); //
	CreateDynamicObject(1431,1732.2600100,-1652.9353000,19.7395000,0.0000000,0.0000000,91.0000000, 1); //
	CreateDynamicObject(1431,1732.2598900,-1658.0333300,19.7395000,0.0000000,0.0000000,88.0000000, 1); //
	CreateDynamicObject(1431,1732.1662600,-1660.9654500,19.7395000,0.0000000,0.0000000,77.0000000, 1); //
	CreateDynamicObject(1431,1711.1339100,-1649.6980000,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1711.1723600,-1652.6456300,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(944,1710.6372100,-1659.3751200,20.0897000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1431,1711.0376000,-1666.4215100,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1710.9719200,-1669.2843000,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1720.9318800,-1671.2094700,19.7395000,0.0000000,0.0000000,33.0000000, 1); //
	CreateDynamicObject(672,1721.9489700,-1655.7229000,19.7202000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(892,1712.7387700,-1663.5288100,19.7759000,0.0000000,0.0000000,-135.0000000, 1); //
	CreateDynamicObject(892,1730.2729500,-1655.3908700,19.7759000,0.0000000,0.0000000,-127.0000000, 1); //
	CreateDynamicObject(892,1712.8136000,-1655.4552000,19.7759000,0.0000000,0.0000000,120.0000000, 1); //
	CreateDynamicObject(892,1730.2219200,-1647.7417000,19.7759000,0.0000000,0.0000000,-127.0000000, 1); //
	CreateDynamicObject(864,1715.7907700,-1663.5190400,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1714.1395300,-1658.5002400,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1713.9782700,-1668.6534400,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1719.1944600,-1668.5271000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1720.8536400,-1663.7404800,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1729.1955600,-1659.0946000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1725.1790800,-1662.4126000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1729.7194800,-1650.6577100,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1727.1743200,-1645.3880600,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1722.4876700,-1647.8526600,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1714.6279300,-1648.2008100,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1715.1008300,-1653.3595000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1717.9925500,-1645.4126000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1431,1718.9912100,-1651.9793700,19.5955000,0.0000000,0.0000000,215.0000000, 1); //
	CreateDynamicObject(1431,1724.5855700,-1658.6324500,19.5955000,0.0000000,0.0000000,215.0000000, 1); //
	CreateDynamicObject(1431,1722.1575900,-1651.5434600,19.5955000,0.0000000,0.0000000,180.0000000, 1); //
	CreateDynamicObject(1431,1721.5245400,-1659.4887700,19.5955000,0.0000000,0.0000000,180.0000000, 1); //
	CreateDynamicObject(1431,1718.8158000,-1658.8237300,19.5955000,0.0000000,0.0000000,127.0000000, 1); //
	CreateDynamicObject(1431,1724.8591300,-1652.1618700,19.5955000,0.0000000,0.0000000,127.0000000, 1); //
	CreateDynamicObject(1431,1725.3942900,-1655.1174300,19.5955000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1431,1718.2086200,-1655.3947800,19.5955000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(760,1721.5629900,-1655.1081500,19.8183000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1659.9126000,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1655.9326200,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1651.9526400,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1648.3706100,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1644.7885700,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7583000,-1641.2065400,20.3691000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1431,1731.3355700,-1639.8802500,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1724.4901100,-1639.9298100,19.7395000,0.0000000,0.0000000,113.0000000, 1); //
	CreateDynamicObject(1431,1718.2587900,-1639.7534200,19.7395000,0.0000000,0.0000000,80.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1671.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1668.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1665.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1662.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1659.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(934,1703.9731400,-1656.9447000,20.4745000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1464,1703.0494400,-1648.2496300,20.3691000,0.0000000,0.0000000,1.0000000, 1); //
	CreateDynamicObject(1464,1706.0494400,-1648.2496300,20.3691000,0.0000000,0.0000000,1.0000000, 1); //
	CreateDynamicObject(1464,1701.0380900,-1650.6947000,20.3691000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1464,1701.0380900,-1653.6947000,20.3691000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1431,1707.3205600,-1651.1206100,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1707.4224900,-1653.7473100,19.7395000,0.0000000,0.0000000,270.0000000, 1); //
	CreateDynamicObject(1431,1705.7066700,-1654.7402300,19.7395000,0.0000000,0.0000000,180.0000000, 1); //
	CreateDynamicObject(1431,1703.1864000,-1654.8370400,19.7395000,0.0000000,0.0000000,180.0000000, 1); //
	CreateDynamicObject(1420,1702.9903600,-1651.2113000,19.2164000,0.0000000,0.0000000,52.0000000, 1); //
	CreateDynamicObject(1420,1705.4617900,-1652.7760000,19.2164000,0.0000000,0.0000000,84.0000000, 1); //
	CreateDynamicObject(1420,1705.2728300,-1651.1765100,19.6464000,0.0000000,91.0000000,127.0000000, 1); //
	CreateDynamicObject(1420,1703.4433600,-1653.3689000,19.6464000,0.0000000,91.0000000,47.0000000, 1); //
	CreateDynamicObject(864,1708.6483200,-1663.0939900,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1709.1104700,-1672.5918000,19.0565900,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1464,1709.8835400,-1642.9266400,20.3691000,0.0000000,0.0000000,45.0000000, 1); //
	CreateDynamicObject(1464,1712.4902300,-1640.4310300,20.3691000,0.0000000,0.0000000,43.0000000, 1); //
	CreateDynamicObject(864,1728.7648900,-1670.4029500,21.2860000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(864,1731.1055900,-1668.6738300,21.2860000,0.0000000,0.0000000,-80.0000000, 1); //
	CreateDynamicObject(1431,1733.6352500,-1660.8450900,23.2363000,0.0000000,0.0000000,18.0000000, 1); //
	CreateDynamicObject(1431,1733.7401100,-1643.8564500,23.2363000,0.0000000,0.0000000,-18.0000000, 1); //
	CreateDynamicObject(1464,1734.7376700,-1654.4661900,23.8044000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7376700,-1651.0701900,23.8044000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1734.7376700,-1647.9571500,23.8044000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1431,1732.3426500,-1653.0426000,23.2363000,0.0000000,0.0000000,84.0000000, 1); //
	CreateDynamicObject(1431,1732.3596200,-1649.7573200,23.2363000,0.0000000,0.0000000,84.0000000, 1); //
	CreateDynamicObject(1431,1731.7064200,-1640.6268300,23.2363000,0.0000000,0.0000000,-84.0000000, 1); //
	CreateDynamicObject(1431,1717.1728500,-1639.8587600,23.2363000,0.0000000,0.0000000,-84.0000000, 1); //
	CreateDynamicObject(1464,1728.0656700,-1639.6573500,23.8044000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1464,1723.9016100,-1639.6618700,23.8044000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1431,1709.3081100,-1646.8127400,23.2363000,0.0000000,0.0000000,-28.0000000, 1); //
	CreateDynamicObject(1464,1713.7487800,-1641.6469700,23.8044000,0.0000000,0.0000000,45.0000000, 1); //
	CreateDynamicObject(1464,1711.0250200,-1644.2656300,23.8044000,0.0000000,0.0000000,45.0000000, 1); //
	CreateDynamicObject(1431,1709.4083300,-1649.9738800,23.2363000,0.0000000,0.0000000,14.0000000, 1); //
	CreateDynamicObject(1431,1710.0958300,-1670.1912800,23.2363000,0.0000000,0.0000000,14.0000000, 1); //
	CreateDynamicObject(1464,1709.0914300,-1653.2346200,23.8044000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1464,1709.0914300,-1658.2346200,23.8044000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1464,1709.0914300,-1663.2346200,23.8044000,0.0000000,0.0000000,90.0000000, 1); //
	CreateDynamicObject(1431,1712.8184800,-1672.6754200,23.2363000,0.0000000,0.0000000,-68.0000000, 1); //
	CreateDynamicObject(1431,1710.8322800,-1666.8527800,23.2363000,0.0000000,0.0000000,-90.0000000, 1); //
	CreateDynamicObject(1464,1715.5592000,-1673.5678700,23.8044000,0.0000000,0.0000000,-180.0000000, 1); //
	CreateDynamicObject(1431,1720.3175000,-1671.6700400,23.2363000,0.0000000,0.0000000,0.0000000, 1); //
	CreateDynamicObject(1464,1721.3620600,-1675.0550500,23.8044000,0.0000000,0.0000000,-180.0000000, 1); //
	CreateDynamicObject(1431,1711.6127900,-1675.6965300,26.7397000,0.0000000,0.0000000,-120.0000000, 1); //
	CreateDynamicObject(1431,1729.3017600,-1666.7835700,22.1351000,0.0000000,0.0000000,45.0000000, 1); //
	CreateDynamicObject(1431,1727.0462600,-1668.9456800,22.1351000,0.0000000,0.0000000,45.0000000, 1); //
	CreateDynamicObject(1431,1725.3847700,-1673.2858900,23.2262000,0.0000000,0.0000000,-45.0000000, 1); //
	CreateDynamicObject(1431,1733.4305400,-1665.3914800,23.2262000,0.0000000,0.0000000,-45.0000000, 1); //
	CreateDynamicObject(1464,1718.7059300,-1675.0693400,23.8044000,0.0000000,0.0000000,-180.0000000, 1); //
	CreateDynamicObject(19975,1723.5183100,-1674.2849100,21.5647000,0.0000000,0.0000000,-180.0000000, 1); //
	CreateDynamicObject(19975,1717.6627200,-1674.2834500,21.5647000,0.0000000,0.0000000,-180.0000000, 1); //
	CreateDynamicObject(970,1720.5258800,-1674.6807900,25.3827000,0.0000000,0.0000000,0.0000000, 1); //
}
RemoveBuildingForEvent(playerid)
{
    	RemoveBuildingForPlayer(playerid, 2744, 1721.6172, -1655.6641, 21.6641, 0.25);
	RemoveBuildingForPlayer(playerid, 2756, 1712.5938, -1655.6016, 21.1641, 0.25);
	RemoveBuildingForPlayer(playerid, 2756, 1730.5000, -1655.5078, 21.1641, 0.25);
	RemoveBuildingForPlayer(playerid, 2759, 1715.7266, -1655.6016, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2759, 1727.3672, -1655.5078, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2757, 1715.6719, -1655.6016, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2757, 1727.4219, -1655.5078, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2761, 1716.3438, -1655.6016, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2761, 1726.7500, -1655.5078, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2758, 1715.6250, -1655.6016, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2758, 1727.4688, -1655.5078, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2760, 1715.8125, -1655.6016, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2760, 1727.2813, -1655.5078, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2756, 1730.5469, -1647.6484, 21.1641, 0.25);
	RemoveBuildingForPlayer(playerid, 2759, 1727.4141, -1647.6484, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2757, 1727.4688, -1647.6484, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2761, 1726.7969, -1647.6484, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2758, 1727.5156, -1647.6484, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2760, 1727.3281, -1647.6484, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2756, 1712.5469, -1663.4688, 21.1641, 0.25);
	RemoveBuildingForPlayer(playerid, 2757, 1715.6250, -1663.4688, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2758, 1715.5781, -1663.4688, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2759, 1715.6797, -1663.4688, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2760, 1715.7656, -1663.4688, 21.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 2761, 1716.2969, -1663.4688, 21.1563, 0.25);
}
