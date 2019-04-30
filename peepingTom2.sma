#include <amxmodx>
#include <amxmisc>

#include <cstrike>

#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>

#include <xs>

#include <sqlx>

#define CanUseAlive 0

new const Plugin[] = "Peeping Tom - Jack86"
new const Author[] = "joaquimandrade"
new const Version[]	= "2.0"

new SpritesPath[CsTeams][] = {"","sprites/peeping_tom/t.spr","sprites/peeping_tom/ct.spr",""}
new SpritesCachedIDs[CsTeams]

const MaxSlots = 32

new bool:OnFirstPersonView[MaxSlots+1]
new HasPermissions[MaxSlots+1]

new SpectatingUser[MaxSlots+1]

const PermissionFlag = ADMIN_BAN

enum _:Vector
{
	X,
	Y,
	Z
}

enum Individual
{
	Spectated,
	Viewed
}

enum OriginOffset
{
	FrameSide,
	FrameTop,
	FrameBottom,
}

enum FramePoint
{
	TopLeft,
	TopRight,
	BottomLeft,
	BottomRight
}

new Float:OriginOffsets[OriginOffset] =  {_:13.0,_:25.0,_:36.0}

new Float:ScaleMultiplier = 0.013;
new Float:ScaleLower = 0.005

new Float:SomeNonZeroValue = 1.0

new EntitiesOwner

new MaxPlayers

enum StateViewOption
{
	StateViewSpec,
#if CanUseAlive
	StateViewAlways,
#endif
	StateViewDisabled

}

enum TeamViewOption
{
	TeamViewEnemies,
	TeamViewEverybody
}

enum _:Option
{
	OptionStateView,
	OptionTeamView
}

new OptionValuesLabels[Option][][] =
{
	{
	"Spectator",
#if CanUseAlive
	"Always",
#endif
	"Disabled"
	},
	
	{
	"Enemies",
	"Everybody"
#if CanUseAlive
	,""
#endif
	}
}

new OptionLabels[][] = 
{
	"State",
	"View"
}

new OptionsLen[Option] = {_:StateViewOption,_:TeamViewOption}

new UserOptions[MaxSlots+1][Option]

new DatabaseName[] = "peepingTom"
new TableName[] = "users"

new TableCreateQuery[] =
{
	"										\
	CREATE TABLE `%s`						\
	(										\
		`SteamID` VARCHAR(34) NOT NULL,		\
		`StateViewOption` INTEGER NOT NULL,	\
		`TeamViewOption` INTEGER NOT NULL,	\
		PRIMARY KEY(`SteamID`)				\
	)										\
	"
}

new DatabaseError[511]

new Handle:DatabaseInfoTuple

new Array:SteamIDsList
new Trie:SteamIDToListID
new Array:PlayerOptionsOriginal
new Array:PlayerOptionsFinal

new PlayerListID[MaxSlots+1]

#if !CanUseAlive 
new ForwardAddToFullPack
new OnFirstPersonViewN
#endif

public plugin_precache()
{
	for(new CsTeams:i=CS_TEAM_T;i<=CS_TEAM_CT;i++)
		SpritesCachedIDs[i] = precache_model(SpritesPath[i])
}

public plugin_init()
{
	register_plugin(Plugin,Version,Author)
	
	register_event("TextMsg","specMode","b","2&#Spec_Mode")
	register_event("StatusValue","specTarget","bd","1=2")
	register_event("SpecHealth2","specTarget","bd")
	
	RegisterHam(Ham_Spawn,"player","playerSpawn",1)
	
	register_clcmd("peepingTom","peepingTom",PermissionFlag)
	
	register_cvar("peepingTom_version",Version,FCVAR_SERVER|FCVAR_SPONLY);
	
	#if CanUseAlive
	register_forward(FM_AddToFullPack,"addToFullPackPost",1)
	#endif
}

public plugin_cfg()
{
	EntitiesOwner = create_entity("info_target")
	
	MaxPlayers = get_maxplayers()
	
	for(new id=1;id<=MaxPlayers;id++)
		createSprite(id,EntitiesOwner)	
	
	initializeDatabase()
	
	if(!databaseLayoutCreated())
	{
		createDatabaseLayout()
	}
	
	SteamIDsList = ArrayCreate(34)
	SteamIDToListID = TrieCreate()
	PlayerOptionsOriginal = ArrayCreate(_:Option)
	PlayerOptionsFinal = ArrayCreate(_:Option)
}

public createSprite(aiment,owner)	
{
	new sprite = create_entity("info_target")
	
	assert is_valid_ent(sprite);
	
	entity_set_edict(sprite,EV_ENT_aiment,aiment)	
	set_pev(sprite,pev_movetype,MOVETYPE_FOLLOW)
	
	entity_set_model(sprite,SpritesPath[CS_TEAM_T])
	
	set_pev(sprite,pev_owner,owner)

	set_pev(sprite,pev_solid,SOLID_NOT)
	
	fm_set_rendering(sprite,.render=kRenderTransAlpha,.amount=0)	
}

public addToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
	#if CanUseAlive
	if((1<=host<=MaxPlayers) && ((UserOptions[host][OptionStateView] == _:StateViewSpec) && ((OnFirstPersonView[host] && SpectatingUser[host])) || (UserOptions[host][OptionStateView] == _:StateViewAlways)) && is_valid_ent(ent))
	#else
	if((1<=host<=MaxPlayers) && (UserOptions[host][OptionStateView] == _:StateViewSpec) && ((OnFirstPersonView[host] && SpectatingUser[host])) && is_valid_ent(ent))
	#endif
	{		
		if(pev(ent,pev_owner) == EntitiesOwner)
		{
			if(engfunc(EngFunc_CheckVisibility,ent,pSet))
			{
				new spectated = OnFirstPersonView[host] ? SpectatingUser[host] : host
				
				new aiment = pev(ent,pev_aiment)
				
				static CsTeams:team
				
				if((spectated != aiment) && is_user_alive(aiment) && ((cs_get_user_team(spectated) != (team=cs_get_user_team(aiment))) || (UserOptions[host][OptionTeamView] == _:TeamViewEverybody)))
				{
					static ID[Individual]
		
					ID[Spectated] = spectated
					ID[Viewed] = ent
					
					static Float:origin[Individual][Vector]
					
					entity_get_vector(ID[Spectated],EV_VEC_origin,origin[Spectated])
					get_es(es,ES_Origin,origin[Viewed])
					
					static Float:diff[Vector]
					static Float:diffAngles[Vector]
					
					xs_vec_sub(origin[Viewed],origin[Spectated],diff)			
					xs_vec_normalize(diff,diff)         
					
					vector_to_angle(diff,diffAngles)
					
					diffAngles[0] = -diffAngles[0];
					
					static Float:framePoints[FramePoint][Vector]
					
					calculateFramePoints(origin[Viewed],framePoints,diffAngles)			
					
					static Float:eyes[Vector]
					
					xs_vec_copy(origin[Spectated],eyes)
					
					static Float:viewOfs[Vector]			
					entity_get_vector(ID[Spectated],EV_VEC_view_ofs,viewOfs);
					xs_vec_add(eyes,viewOfs,eyes);
					
					static Float:framePointsTraced[FramePoint][Vector]
					
					static FramePoint:closerFramePoint
					
					if(traceEyesFrame(ID[Spectated],eyes,framePoints,framePointsTraced,closerFramePoint))
					{
						static Float:otherPointInThePlane[Vector]
						static Float:anotherPointInThePlane[Vector]
						
						static Float:sideVector[Vector]
						static Float:topBottomVector[Vector]
						
						angle_vector(diffAngles,ANGLEVECTOR_UP,topBottomVector)
						angle_vector(diffAngles,ANGLEVECTOR_RIGHT,sideVector)
						
						xs_vec_mul_scalar(sideVector,SomeNonZeroValue,otherPointInThePlane)
						xs_vec_mul_scalar(topBottomVector,SomeNonZeroValue,anotherPointInThePlane)	
						
						xs_vec_add(otherPointInThePlane,framePointsTraced[closerFramePoint],otherPointInThePlane)
						xs_vec_add(anotherPointInThePlane,framePointsTraced[closerFramePoint],anotherPointInThePlane)
						
						static Float:plane[4]
						xs_plane_3p(plane,framePointsTraced[closerFramePoint],otherPointInThePlane,anotherPointInThePlane)
						
						moveToPlane(plane,eyes,framePointsTraced,closerFramePoint);
						
						static Float:middle[Vector]
						
						static Float:half = 2.0
						
						xs_vec_add(framePointsTraced[TopLeft],framePointsTraced[BottomRight],middle)
						xs_vec_div_scalar(middle,half,middle)
						
						new Float:scale = ScaleMultiplier * vector_distance(framePointsTraced[TopLeft],framePointsTraced[TopRight])
						
						if(scale < ScaleLower)
							scale = ScaleLower;
						
						set_es(es,ES_AimEnt,0)
						set_es(es,ES_MoveType,MOVETYPE_NONE)
						set_es(es,ES_ModelIndex,SpritesCachedIDs[team])
						set_es(es,ES_Scale,scale)
						set_es(es,ES_Angles,diffAngles)
						set_es(es,ES_Origin,middle)
						set_es(es,ES_RenderMode,kRenderNormal)
					}
				}
			}
		}
	}
}

calculateFramePoints(Float:origin[Vector],Float:framePoints[FramePoint][Vector],Float:perpendicularAngles[Vector])
{
	new Float:sideVector[Vector]
	new Float:topBottomVector[Vector]
	
	angle_vector(perpendicularAngles,ANGLEVECTOR_UP,topBottomVector)
	angle_vector(perpendicularAngles,ANGLEVECTOR_RIGHT,sideVector)
	
	new Float:sideDislocation[Vector]
	new Float:bottomDislocation[Vector]
	new Float:topDislocation[Vector]
	
	xs_vec_mul_scalar(sideVector,Float:OriginOffsets[FrameSide],sideDislocation)
	xs_vec_mul_scalar(topBottomVector,Float:OriginOffsets[FrameTop],topDislocation)	
	xs_vec_mul_scalar(topBottomVector,Float:OriginOffsets[FrameBottom],bottomDislocation)
	
	xs_vec_copy(topDislocation,framePoints[TopLeft])
	
	xs_vec_add(framePoints[TopLeft],sideDislocation,framePoints[TopRight])
	xs_vec_sub(framePoints[TopLeft],sideDislocation,framePoints[TopLeft])
	
	xs_vec_neg(bottomDislocation,framePoints[BottomLeft])
	
	xs_vec_add(framePoints[BottomLeft],sideDislocation,framePoints[BottomRight])
	xs_vec_sub(framePoints[BottomLeft],sideDislocation,framePoints[BottomLeft])
	
	for(new FramePoint:i = TopLeft; i <= BottomRight; i++)
		xs_vec_add(origin,framePoints[i],framePoints[i])
	
}

traceEyesFrame(id,Float:eyes[Vector],Float:framePoints[FramePoint][Vector],Float:framePointsTraced[FramePoint][Vector],&FramePoint:closerFramePoint)
{
	new Float:smallFraction = 1.0
	
	for(new FramePoint:i = TopLeft; i <= BottomRight; i++)
	{
		new trace;
		engfunc(EngFunc_TraceLine,eyes,framePoints[i],IGNORE_GLASS,id,trace)
		
		new Float:fraction
		get_tr2(trace, TR_flFraction,fraction);
		
		if(fraction == 1.0)
		{
			return false;
		}
		else
		{
			if(fraction < smallFraction)
			{
				smallFraction = fraction
				closerFramePoint = i;
			}
			
			get_tr2(trace,TR_EndPos,framePointsTraced[i]);
		}
	}
	
	return true;
}

moveToPlane(Float:plane[4],Float:eyes[Vector],Float:framePointsTraced[FramePoint][Vector],FramePoint:alreadyInPlane)
{
	new Float:direction[Vector]
	
	for(new FramePoint:i=TopLeft;i<alreadyInPlane;i++)
	{
		xs_vec_sub(eyes,framePointsTraced[i],direction)
		xs_plane_rayintersect(plane,framePointsTraced[i],direction,framePointsTraced[i])
	}
	
	for(new FramePoint:i=alreadyInPlane+FramePoint:1;i<=BottomRight;i++)
	{
		xs_vec_sub(eyes,framePointsTraced[i],direction)
		xs_plane_rayintersect(plane,framePointsTraced[i],direction,framePointsTraced[i])
	}
}	
	
handleJoiningFirstPersonView(id)
{	
	OnFirstPersonView[id] = true
	
	#if !CanUseAlive 
	if(!OnFirstPersonViewN++)
	{
		ForwardAddToFullPack = register_forward(FM_AddToFullPack,"addToFullPackPost",1)
	}
	#endif
}

handleQuitingFirstPersonView(id)
{
	OnFirstPersonView[id] = false
	SpectatingUser[id] = 0
	
	#if !CanUseAlive 
	if(!--OnFirstPersonViewN)
	{
		unregister_forward(FM_AddToFullPack,ForwardAddToFullPack,1)
	}
	#endif
}

public playerSpawn(id)
{
	if(HasPermissions[id])
	{
		if(OnFirstPersonView[id] && is_user_alive(id))
		{
			handleQuitingFirstPersonView(id)
		}
	}
}

public client_authorized(id)
{
	if(get_user_flags(id) & PermissionFlag)
	{
		HasPermissions[id] = true
		
		static steamID[34]
		get_user_authid(id,steamID,charsmax(steamID))
		
		new listID
		
		UserOptions[id][OptionStateView] = UserOptions[id][OptionTeamView] = 0
		
		if(!TrieGetCell(SteamIDToListID,steamID,listID))
		{
			static queryString[] = "SELECT StateViewOption,TeamViewOption FROM `%s` WHERE `SteamID`= '%s'"
			
			new Handle:connection = getDatabaseConnection()
	
			new Handle:query = SQL_PrepareQuery(connection,queryString,TableName,steamID)
				
			if(!SQL_Execute(query))
			{
				SQL_QueryError(query,DatabaseError,charsmax(DatabaseError))
				set_fail_state(DatabaseError)
			}
			else
			{
				if(SQL_MoreResults(query))
				{
					UserOptions[id][OptionStateView] = clamp(SQL_ReadResult(query,0),0,OptionsLen[OptionStateView]-1)
					UserOptions[id][OptionTeamView] = clamp(SQL_ReadResult(query,1),0,OptionsLen[OptionTeamView]-1)
				}
			}
			
			TrieSetCell(SteamIDToListID,steamID,ArraySize(SteamIDsList))
			
			ArrayPushString(SteamIDsList,steamID)
			
			ArrayPushArray(PlayerOptionsOriginal,UserOptions[id])
			ArrayPushArray(PlayerOptionsFinal,UserOptions[id])
			
			SQL_FreeHandle(query)
			SQL_FreeHandle(connection)
		}
		else
		{
			ArrayGetArray(PlayerOptionsFinal,listID,UserOptions[id])
		}
		
		PlayerListID[id] = listID
	}
	else
	{
		HasPermissions[id] = false
	}
}

public client_disconnect(id)
{
	if(HasPermissions[id])
	{
		if(OnFirstPersonView[id])
		{
			handleQuitingFirstPersonView(id)
		}
		
		ArraySetArray(PlayerOptionsFinal,PlayerListID[id],UserOptions[id])
		
		HasPermissions[id] = false
	}
}

public specMode(id)
{
	if(HasPermissions[id])
	{
		new specMode[12]
		read_data(2,specMode,11)
			
		if(specMode[10] == '4')
		{
			handleJoiningFirstPersonView(id)
		}
		else if(OnFirstPersonView[id])
		{
			handleQuitingFirstPersonView(id)
		}
	}
}

public specTarget(id)
{
	new spectated = read_data(2);
		
	if(spectated)
	{
		if(OnFirstPersonView[id])
		{
			if(spectated != SpectatingUser[id])
			{
				handleQuitingFirstPersonView(id)
				SpectatingUser[id] = spectated;				
				handleJoiningFirstPersonView(id)
			}
		}
		else
		{
			SpectatingUser[id] = spectated;
		}
	}
}

public plugin_end()
{
	for(new i=0;i<ArraySize(SteamIDsList);i++)
	{
		new optionsOriginal[Option]
		new optionsFinal[Option]
		
		ArrayGetArray(PlayerOptionsOriginal,i,optionsOriginal)
		ArrayGetArray(PlayerOptionsFinal,i,optionsFinal)
		
		new bool:differs
		new sumOriginal
		new sumFinal
		
		for(new j=0;j<Option;j++)
		{
			if(optionsOriginal[j] != optionsFinal[j])
			{
				differs = true
			}
			
			sumOriginal += optionsOriginal[j]
			sumFinal += optionsFinal[j]
		}
		
		if(differs)
		{
			static Handle:query
			
			static steamID[34]
			
			ArrayGetString(SteamIDsList,i,steamID,charsmax(steamID))
			
			new Handle:connection = getDatabaseConnection()
	
			if(!sumOriginal)
			{
				static queryString[] = "INSERT INTO `%s` (SteamID,StateViewOption,TeamViewOption) VALUES ('%s','%d','%d')"
				
				query = SQL_PrepareQuery(connection,queryString,TableName,steamID,optionsFinal[_:OptionStateView],optionsFinal[_:OptionTeamView])
			}
			else if(!sumFinal)
			{
				static queryString[] = "DELETE FROM `%s` WHERE SteamID ='%s'"
				
				query = SQL_PrepareQuery(connection,queryString,TableName,steamID)
			}
			else
			{
				static queryString[] = "UPDATE `%s` SET StateViewOption = '%d' ,TeamViewOption = '%d'  WHERE SteamID ='%s'"
				
				query = SQL_PrepareQuery(connection,queryString,TableName,optionsFinal[_:OptionStateView],optionsFinal[_:OptionTeamView],steamID)
			}
			
			if(!SQL_Execute(query))
			{
				SQL_QueryError(query,DatabaseError,charsmax(DatabaseError))
				set_fail_state(DatabaseError)
			}
			
			SQL_FreeHandle(query)
			SQL_FreeHandle(connection)
		}
	}
}

public peepingTom(id,level,cid) 
{
	if(cmd_access(id,level,cid,0))
	{
		peepingTomMenu(id)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

peepingTomMenu(id)
{	
	new menu = menu_create("Peeping Tom User Options","handlePeepingTomMenu")
	
	new optionString[2]
	
	static itemFormat[] = "%s: ^"\r%s\w^""
	static itemText[sizeof itemFormat + 20 + 20]
	
	for(new i=0;i<Option;i++)
	{
		optionString[0] = i + 48
		formatex(itemText,charsmax(itemText),itemFormat,OptionLabels[i],OptionValuesLabels[i][UserOptions[id][i]])
		
		menu_additem(menu,itemText,optionString)
	}
	
	menu_display(id,menu)
}
public handlePeepingTomMenu(id,menu,item)
{
	if(item >= 0) 
	{
		new access, callback; 
		
		new actionString[2];		
		menu_item_getinfo(menu,item,access, actionString,1,_,_, callback);		
		new action = str_to_num(actionString);	
		
		UserOptions[id][action] = (UserOptions[id][action] + 1) % OptionsLen[action]
		
		peepingTomMenu(id)		
	}
	
	menu_destroy(menu)
}