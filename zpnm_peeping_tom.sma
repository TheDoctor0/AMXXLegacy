#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <xs>
#include <zombieplague>

#define CanUseAlive 1

new const Plugin[] = "Peeping Tom - Jack86"
new const Author[] = "joaquimandrade"
new const Version[]	= "2.0"

new SpritesPath[CsTeams][] = {"","sprites/peeping_tom/t.spr","sprites/peeping_tom/ct.spr",""}
new SpritesCachedIDs[CsTeams]

const MaxSlots = 32

new bool:OnFirstPersonView[MaxSlots+1]
//new HasPermissions[MaxSlots+1]

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
/*
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

new OptionsLen[Option] = {_:StateViewOption,_:TeamViewOption}*/

new UserOptions[MaxSlots+1][Option]

/*new Array:SteamIDsList
new Trie:SteamIDToListID
new Array:PlayerOptionsOriginal
new Array:PlayerOptionsFinal

new PlayerListID[MaxSlots+1]
*/
//#if !CanUseAlive 
new ForwardAddToFullPack
new OnFirstPersonViewN
//#endif

//new g_pItem;

public plugin_precache()
{
	for(new CsTeams:i=CS_TEAM_T;i<=CS_TEAM_CT;i++)
		SpritesCachedIDs[i] = precache_model(SpritesPath[i])
}

public plugin_init()
{
	register_plugin(Plugin,Version,Author)
	
//	g_pItem = zp_register_extra_item("See Humans Through Walls", 0, ZP_TEAM_ZOMBIE);
	
	register_event("TextMsg","specMode","b","2&#Spec_Mode")
	register_event("StatusValue","specTarget","bd","1=2")
	register_event("SpecHealth2","specTarget","bd")
	
	RegisterHam(Ham_Spawn,"player","playerSpawn",1)
	
	register_cvar("peepingTom_version",Version,FCVAR_SERVER|FCVAR_SPONLY);
	
	//#if CanUseAlive
	register_forward(FM_AddToFullPack,"addToFullPackPost",1)
	//#endif
}

public plugin_cfg()
{
	EntitiesOwner = create_entity("info_target")
	
	MaxPlayers = get_maxplayers()
	
	for(new id=1;id<=MaxPlayers;id++)
		createSprite(id,EntitiesOwner)	
	
//	SteamIDsList = ArrayCreate(34)
//	SteamIDToListID = TrieCreate()
//	PlayerOptionsOriginal = ArrayCreate(_:Option)
//	PlayerOptionsFinal = ArrayCreate(_:Option)
}
/*
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_pItem)
	{
		if (UserOptions[id][OptionStateView] == _:StateViewAlways)
			return ZP_PLUGIN_HANDLED;
			
		UserOptions[id][OptionStateView] = _:StateViewAlways;
	}
	
	return PLUGIN_CONTINUE;
}*/

public zp_user_infected_post(id)
	UserOptions[id][OptionStateView] = _:StateViewAlways;

public zp_user_humanized_post(id)
{
	UserOptions[id][OptionStateView] = _:StateViewDisabled;
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
	if ((1<=host<=MaxPlayers))
	{
		if ((UserOptions[host][OptionStateView] == _:StateViewAlways) 
		|| (OnFirstPersonView[host] && UserOptions[SpectatingUser[host]][OptionStateView] == _:StateViewAlways))
		{
			if(is_valid_ent(ent) && pev(ent,pev_owner) == EntitiesOwner)
			{
				if(engfunc(EngFunc_CheckVisibility,ent,pSet))
				{
					new spectated = OnFirstPersonView[host] ? SpectatingUser[host] : host
					
					new aiment = pev(ent,pev_aiment)
					
					//static CsTeams:team
					
					if(is_user_alive(aiment) && !zp_get_user_zombie(aiment))
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
							set_es(es,ES_ModelIndex,SpritesCachedIDs[CS_TEAM_CT])
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
	
//	#if !CanUseAlive 
	if(!OnFirstPersonViewN++)
	{
		ForwardAddToFullPack = register_forward(FM_AddToFullPack,"addToFullPackPost",1)
	}
//	#endif
}

handleQuitingFirstPersonView(id)
{
	OnFirstPersonView[id] = false
	SpectatingUser[id] = 0
	
//	#if !CanUseAlive 
	if(!--OnFirstPersonViewN)
	{
		unregister_forward(FM_AddToFullPack,ForwardAddToFullPack,1)
	}
//	#endif
}

public playerSpawn(id)
{
	if(is_user_alive(id))
		UserOptions[id][OptionStateView] = _:StateViewDisabled;
}

public client_putinserver(id) //authorized
{
	UserOptions[id][OptionStateView] = _:StateViewDisabled;
}

public client_disconnect(id)
{
	if(OnFirstPersonView[id])
	{
		handleQuitingFirstPersonView(id)
	}
}

public specMode(id)
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