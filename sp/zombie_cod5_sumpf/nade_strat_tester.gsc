#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
    //return;
    level endon( "game_ended" );

    if ( GetDvar( "zombiemode" ) != "1" ) return;

    precacheShader( "damage_feedback" );

    level thread onplayerconnect();

    level thread init_hud();
    level thread luisete_credits();

    while(!isDefined(level.callbackActorDamage)) wait 0.1;

    level.old_callbackActorDamage = level.callbackActorDamage;
    level.callbackActorDamage = ::Hit_Monitor;

    level thread disable_zombies();
    level thread replace_chests();

}


onplayerconnect()
{
    level endon( "game_ended" );

    for (;;)
	{
        level waittill( "connected", player ); 
	    player thread onplayerspawned();

        player thread nade_monitor();
        player thread spawn_selection();
        player thread god();

        if(!isDefined(player.hud_damagefeedback)){
            player.hud_damagefeedback = newclientHudElem( player );
	        player.hud_damagefeedback.horzAlign = "center";
	        player.hud_damagefeedback.vertAlign = "middle";
	        player.hud_damagefeedback.x = -12;
	        player.hud_damagefeedback.y = -12;
	        player.hud_damagefeedback.alpha = 0;
	        player.hud_damagefeedback.archived = true;
	        player.hud_damagefeedback setShader("damage_feedback", 24, 48);
        }

	}
}

onplayerspawned()
{
    level endon( "game_ended" );
    self endon( "disconnect" );

    for(;;)
    {
        self waittill( "spawned_player" );
        self iPrintLn( "Welcome ^6"+self.playername+"^7 to ^1Lui^3se^1te's^7 trainer!" );
    }

}


luisete_credits(){

    level endon( "game_ended" );

    flag_wait( "starting final intro screen fadeout" );
    wait 7;

    if(!isdefined(level.luisete_credits)){

	    level.luisete_credits = newHudElem();
            level.luisete_credits.alignx = "left";
            level.luisete_credits.aligny = "top";
            level.luisete_credits.horzalign = "user_center";
            level.luisete_credits.vertalign = "user_top";
            level.luisete_credits.x = -350;
            level.luisete_credits.y = 5;
            level.luisete_credits.fontscale = 2;
            level.luisete_credits.alpha = 1;
            level.luisete_credits.color = (1,1,1);
            level.luisete_credits.hidewheninmenu = 1;
        level.luisete_credits.label = "SR Trainer V1 made by ^1Luis^3ete^12105^7! link on ^0Github^7 and ^6Discord^7 for some support";

        level thread flashing();
    }

}

flashing(){
    level endon( "game_ended" );

    while(true){

        level.luisete_credits fadeOverTime(7);
        level.luisete_credits.alpha = 0;

        wait 7;

        level.luisete_credits fadeOverTime(7);
        level.luisete_credits.alpha = 1;

        wait 7;
    }

}

replace_chests(){

    while(level.chests.size == 0) wait 0.1;
    wait 1;

    if(!isDefined(level.zombie_weapons_keys)) level.zombie_weapons_keys = GetArrayKeys( level.zombie_weapons );


    for(i=0;i<level.chests.size;i++){

        if(level.chests[i].hidden) level.chests[i] thread custom_show_chest();

        level.chests[i] notify("kill_chest_think");
        level.chests[i] thread custom_chest_think();
    }



}

custom_chest_think(){

    self setCursorHint( "HINT_NOICON" );
    self.index = 0;
    self.using = false;
    self.weapon_string = level.zombie_weapons_keys[self.index];

    self.weapon_model = spawn( "script_model", self.origin + ( 0, 0, 40));
    self.weapon_model.angles = self.angles +( 0, 90, 0 );

    modelname = GetWeaponModel( self.weapon_string );
    self.weapon_model setmodel( modelname ); 
    self.weapon_model useweaponhidetags( self.weapon_string );
    
    while(1){
        wait 0.05;
        self waittill( "trigger", user ); 

        if(self.using) continue;


        if( user GetCurrentWeapon() == "none" )
		{
            user iPrintLnBold("Invalid weapon");
			wait( 0.1 );
			continue;
		}

        self.using = true;

        if(user attackButtonPressed()){
            self custom_change_weapon(true);
        }else if(user adsButtonPressed()){
            self custom_change_weapon(false);
        }else{
            user custom_give_weapon(self.weapon_string);
        }

        wait 0.2;

        self.using = false;
    }

}

custom_get_left_hand_weapon_model_name( name )
{
	switch ( name )
	{
		case  "microwavegundw_zm":
			return GetWeaponModel( "microwavegunlh_zm" );
		case  "microwavegundw_upgraded_zm":
			return GetWeaponModel( "microwavegunlh_upgraded_zm" );
		default:
			return GetWeaponModel( name );
	}
}

custom_weapon_is_dual_wield(name)
{
	switch(name)
	{
		case  "cz75dw_zm":
		case  "cz75dw_upgraded_zm":
		case  "m1911_upgraded_zm":
		case  "hs10_upgraded_zm":
		case  "pm63_upgraded_zm":
		case  "microwavegundw_zm":
		case  "microwavegundw_upgraded_zm":
			return true;
		default:
			return false;
	}
}

custom_give_weapon( weapon_string ){

	primaryWeapons = self GetWeaponsListPrimaries(); 
	current_weapon = undefined; 
	weapon_limit = 2;

	if( self HasWeapon( weapon_string ) )
	{
		if ( issubstr( weapon_string, "knife_ballistic_" ) )
		{
			self notify( "zmb_lost_knife" );
		}
		self GiveStartAmmo( weapon_string );
		self SwitchToWeapon( weapon_string );
		return;
	}

 	if ( self HasPerk( "specialty_additionalprimaryweapon" ) )
 	{
 		weapon_limit = 3;
 	}
	
	// This should never be true for the first time.
	if( primaryWeapons.size >= weapon_limit )
	{
		current_weapon = self getCurrentWeapon(); // get hiss current weapon

		if ( is_placeable_mine( current_weapon ) || is_equipment( current_weapon ) ) 
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !is_offhand_weapon( weapon_string ) )
			{
				
				if ( issubstr( current_weapon, "knife_ballistic_" ) )
				{
					self notify( "zmb_lost_knife" );
				}

                self TakeWeapon( current_weapon );
			} 
		} 
	} 

	self play_sound_on_ent( "purchase" );
	
	if( IsDefined( level.zombiemode_offhand_weapon_give_override ) )
	{
		self [[ level.zombiemode_offhand_weapon_give_override ]]( weapon_string );
	}

	if( weapon_string == "zombie_cymbal_monkey" )
	{
		self maps\_zombiemode_weap_cymbal_monkey::player_give_cymbal_monkey();
		return;
	}
	else if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "bowie_knife_zm" ) )
	{
		weapon_string = "knife_ballistic_bowie_zm";
	}
	else if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "sickle_knife_zm" ) )
	{
		weapon_string = "knife_ballistic_sickle_zm";
	}
	if (weapon_string == "ray_gun_zm")
	{
		playsoundatposition ("mus_raygun_stinger", (0,0,0));		
	}
	self GiveWeapon( weapon_string, 0 );
	self GiveStartAmmo( weapon_string );
	self SwitchToWeapon( weapon_string );

}

custom_change_weapon( next_weapon ){
    
    if(isDefined(self.weapon_model_dw)){
        self.weapon_model_dw Delete();
        self.weapon_model_dw = undefined;   
    }

    if(next_weapon){
        self.index++;
        if(self.index >= level.zombie_weapons_keys.size){
            self.index = 0;
        }
    }else{
        self.index--;
        if(self.index < 0){
            self.index = level.zombie_weapons_keys.size -1;
        }
    }

    self.weapon_string = level.zombie_weapons_keys[self.index];

    modelname = GetWeaponModel( self.weapon_string );
    self.weapon_model setmodel( modelname ); 
    self.weapon_model useweaponhidetags( self.weapon_string );

    if(custom_weapon_is_dual_wield( self.weapon_string )){

        if( (level.script == "zombie_cosmodrome" || level.script == "zombie_pentagon") && self.weapon_string == "cz75dw_zm" ){
            custom_change_weapon( next_weapon );
        }

        self.weapon_model_dw = spawn( "script_model", self.weapon_model.origin - ( 3, 3, 3 ) ); // extra model for dualwield weapons
		self.weapon_model_dw.angles = self.angles +( 0, 90, 0 );		

		self.weapon_model_dw setmodel( custom_get_left_hand_weapon_model_name( self.weapon_string ) ); 
		self.weapon_model_dw useweaponhidetags( self.weapon_string );

    }

    wait 0.05;

}

custom_show_chest(){

    self thread [[ level.pandora_show_func ]]();

	self enable_trigger();

	self.chest_lid show();
	self.chest_box show();

	self.chest_lid playsound( "zmb_box_poof_land" );
	self.chest_lid playsound( "zmb_couch_slam" );

    rubble = getentarray( self.script_noteworthy + "_rubble", "script_noteworthy" );
	if ( IsDefined( rubble ) )
	{
		for ( x = 0; x < rubble.size; x++ )
		{
			rubble[x] hide();
		}
	}

	self.hidden = false;

}

disable_zombies(){
    level endon( "game_ended" );
    for(;;){
        flag_wait( "spawn_zombies" );
        wait 0.5;
        level.zombie_total = 7777777;
        level.zombie_vars["zombie_use_failsafe"] = false;
        flag_clear( "spawn_zombies");
    }
}

init_hud(){


    NadeCamEnd = newHudElem();

        NadeCamEnd.alignx = "left";
	    NadeCamEnd.aligny = "top";
	    NadeCamEnd.horzalign = "user_left";
	    NadeCamEnd.vertalign = "user_top"; 
        NadeCamEnd.x = 10;
	    NadeCamEnd.y = 45;
        NadeCamEnd.foreground = 1;
        NadeCamEnd.font = "objective";
        NadeCamEnd.fontscale = 1.3;
        NadeCamEnd.hidewheninmenu = 1;
        NadeCamEnd.alpha = 1;
        NadeCamEnd.color = ( 1, 1, 1 );

    NadeCamEnd.label = "^5[{+melee}]^7 To Cancel Custom Cams";


    ZombieSpawns = newHudElem();

        ZombieSpawns.alignx = "left";
	    ZombieSpawns.aligny = "top";
	    ZombieSpawns.horzalign = "user_left";
	    ZombieSpawns.vertalign = "user_top"; 
        ZombieSpawns.x = 10;
	    ZombieSpawns.y = 70;
        ZombieSpawns.foreground = 1;
        ZombieSpawns.font = "objective";
        ZombieSpawns.fontscale = 1.3;
        ZombieSpawns.hidewheninmenu = 1;
        ZombieSpawns.alpha = 1;
        ZombieSpawns.color = ( 1, 1, 1 );

    ZombieSpawns.label = "Current Zombies Spawners: ^5";

    ZombieSpawns thread monitor_zm_spawns();

}

monitor_zm_spawns(){
    level endon( "game_ended" );

    flag_wait( "starting final intro screen fadeout" );

    for(;;){
        wait 0.1;

        if(level.script == "zombie_temple"){
            self setValue( level.enemy_spawn_locations.size );
        }else{
            array = [];
            array = array_combine(level.zombie_rise_spawners, level.enemy_spawns);
            self setValue( array.size );
        }

    }

}

Hit_Monitor( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime ){

    eAttacker thread updateDamageFeedback();

    self [[level.old_callbackActorDamage]] ( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );

}

updateDamageFeedback()
{

	if ( !IsPlayer( self ) ) return;

	self playlocalsound( "SP_hit_alert" );
	
	self.hud_damagefeedback.alpha = 1;
	self.hud_damagefeedback fadeOverTime( 1 );
	self.hud_damagefeedback.alpha = 0;
}

nade_monitor()
{
    level endon( "game_ended" );
    self endon( "disconnect" );

    while( self GetWeaponsList().size <3 ) wait 0.05;

    primary_weapons = self GetWeaponsList();
    for( x = 0; x < primary_weapons.size; x++ )
	{
		self GiveMaxAmmo( primary_weapons[x] );
	}

    for(;;){
        wait 0.1;
        self waittill( "grenade_fire", grenade, weapName );
        if(!self.can_activate_cam) continue;
        self.can_activate_cam = false;

        self giveWeapon(weapName);

        camera = spawn("script_model", grenade.origin );
	    camera SetModel("tag_origin");
		camera.angles = self.angles;

        //camera linkTo(grenade);
        self freezeControls(1);
        self CameraSetPosition( camera );
        self CameraSetLookAt( grenade );
        self CameraActivate(1);
        
        while(isDefined(grenade) && !self meleeButtonPressed())
        {
            wait 0.05;
            dist = Abs( distance(grenade.origin , camera.origin) );

            if( dist > 150 ){
                pos = (grenade.origin + camera.origin)/2;
                camera moveTo(pos, 0.25);
            }

        }

        wait 0.5;
        distance = undefined;

        self freezeControls(0);
        self CameraActivate(0);
        camera delete();

        self.can_activate_cam = true;

    }

}

get_available_zombie_spawns(){

    if(level.script == "zombie_temple"){
        return level.enemy_spawn_locations;
    }else{
        zombie_spawns = array_combine(level.zombie_rise_spawners, level.enemy_spawns);
        return zombie_spawns;
    }

}

spawn_selection(){

    level endon( "game_ended" );
    self endon( "disconnect" );

    flag_wait( "starting final intro screen fadeout" );

    self.Controls1 = newclienthudelem( self );
	    self.Controls1.alignX = "left";
	    self.Controls1.horzAlign = "left";
	    self.Controls1.x = 10; 
	    self.Controls1.y = 100;
        self.Controls1.hidewheninmenu = 1;
	    self.Controls1.fontscale = 1;
	    self.Controls1.color = ( 1, 1, 1 );
    self.Controls1.label = "^5[{+activate}]^7 and ^5[{+gostand}]^7 to save spawns: ";

    self.Controls2 = newclienthudelem( self );
	    self.Controls2.alignX = "left";
	    self.Controls2.horzAlign = "left";
	    self.Controls2.x = 10; 
	    self.Controls2.y = 125;
        self.Controls2.hidewheninmenu = 1;
	    self.Controls2.fontscale = 1;
	    self.Controls2.color = ( 1, 1, 1 );
    self.Controls2.label = "^5[{+activate}]^7 and ^5[{+attack}]^7 or ^5[{+speed_throw}]^7 to change spawn/box gun: ";

    self.Controls3 = newclienthudelem( self );
	    self.Controls3.alignX = "left";
	    self.Controls3.horzAlign = "left";
	    self.Controls3.x = 10; 
	    self.Controls3.y = 150;
        self.Controls3.hidewheninmenu = 1;
	    self.Controls3.fontscale = 1;
	    self.Controls3.color = ( 1, 1, 1 );
    self.Controls3.label = "^5[{+activate}]^7 and ^5[{+reload}]^7 to TP: ";

    self.Controls4 = newclienthudelem( self );
	    self.Controls4.alignX = "left";
	    self.Controls4.horzAlign = "left";
	    self.Controls4.x = 10; 
	    self.Controls4.y = 175;
        self.Controls4.hidewheninmenu = 1;
	    self.Controls4.fontscale = 1;
	    self.Controls4.color = ( 1, 1, 1 );
    self.Controls4.label = "^5[{+activate}]^7 and ^5[{+smoke}]^7 to Test Zombie Spawn (sometimes fails): ^5";

    level.zombie_total = 777777;

    self.teddybear =  Spawn( "script_model", self.origin);
    self.teddybear.angles = self.angles;
    self.teddybear SetModel("zombie_teddybear");
    self.teddybear setCanDamage(true);
    self.teddybear.health = 7777777;

    self.teddybear thread check_damage(self);

    self.index = 0;
    self.teddy_active = false;
    self.can_activate_cam = true;
    self.can_spawn_zombie = true;

    while(true){
        wait 0.05;

        if( self useButtonPressed() && self JumpButtonPressed()){
            self.z_array = [];
            self.z_array = get_available_zombie_spawns();
            self.index = 0;
            self.pos = self getOrigin();

            self.Controls1 setText(""+self.z_array.size+" spawns saved!");

            self update_spawners_text();

            self.Controls4 setText("Not using");

            wait 0.5;
            continue;
        }

        if(self useButtonPressed() && self attackButtonPressed() && isDefined(self.z_array) && self.z_array.size > 0 ){
            self.index++;
            if(self.index > self.z_array.size-1) self.index = 0;

            self update_spawners_text();

            wait 0.2;
            continue;
        }

        if(self useButtonPressed() && self adsButtonPressed() && isDefined(self.z_array) && self.z_array.size > 0 ){
            self.index--;
            if(self.index < 0) self.index = self.z_array.size-1;

            self update_spawners_text();

            wait 0.2;
            continue;
        }

        if(self useButtonPressed() && self ReloadButtonPressed() && isDefined(self.z_array) && self.z_array.size > 0 ){
            self setOrigin(self.z_array[self.index].origin);
            self setPlayerAngles( VectortoAngles( self.pos - self.z_array[self.index].origin ) );

            wait 0.2;
            continue;
        }

        if(self useButtonPressed() && self SecondaryOffhandButtonPressed() && isDefined(self.z_array) && self.z_array.size > 0 && self.can_activate_cam){
            
            self.can_activate_cam = false;

            self.Controls4 setText("using");

            spawn_point = self.z_array[self.index];
            ai = _try_spawn_zombie(spawn_point);
            wait 0.1;

            if(isDefined(ai)){
                self hide();
                self notSolid();

                ai.health = 7777777;

                forward = AnglesToForward( ai.angles );
                ai.cam = Spawn( "script_model", ai.origin + ( 0, 0, 50 ) + forward * -100 );
                ai.cam SetModel( "tag_origin" );
                ai.cam LinkTo( ai );

                self CameraSetPosition(ai.cam);
                self CameraSetLookAt(ai);
                self CameraActivate(1);

                while(!self meleeButtonPressed() && isDefined(ai)) wait 0.1;

                if(isDefined(ai)) ai thread freeze_position(ai.origin, ai.angles, self);

                self show();
                self solid();
                self CameraActivate(0);
            }

            self.Controls4 setText("Not using");

            wait 0.2;
            self.can_activate_cam = true;
            continue;
        }
    }

}

say_damage(player){

    level endon( "game_ended" );
    player endon( "disconnect" );
    self endon("death"); 

    while(isDefined(self)){
        
        self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );
        if(attacker != player) continue;
        if(dmg_type == "MOD_MELEE") self dodamage( self.health + 100, (0,0,0) );
        player iPrintLnBold("Hit by "+amount+"!");        
        self.health = 7777777;
    }

}

freeze_position(position, angles, player){
    level endon( "game_ended" );
    player endon( "disconnect" );
    self endon("death");

    self thread say_damage(player);

    while(isDefined(self)){
        self ForceTeleport(position, angles);
        wait 0.1;
    }

}

check_damage(player){
    level endon( "game_ended" );
    player endon( "disconnect" );

    for(;;){

        self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );
        if(self.teddy_active && attacker == player) player iPrintLnBold("Hit by "+amount+"!");
        player updateDamageFeedback();
        self.health = 7777777;
    }

}

_try_spawn_zombie(spawn_point)
{
    if(level.script == "zombie_temple"){
        level.main_spawner.script_string = spawn_point.script_string;
	    level.main_spawner.target = spawn_point.target;
	    level.main_spawner.zone_name = spawn_point.zone_name;

        ai = spawn_zombie( level.main_spawner );

        level.main_spawner.count = 100; 
	    level.main_spawner.last_spawn_time = GetTime();
    }else{
        ai = spawn_zombie( spawn_point );
    }

	if ( !spawn_failed(ai) )
	{
		// teleport the zombie to our spawner
		ai ForceTeleport(spawn_point.origin, spawn_point.angles);
	}

	return ai;
}

update_spawners_text(){

    self.teddy_active = true;

    self.teddybear.origin = self.z_array[self.index].origin;
    self.teddybear.angles = self.z_array[self.index].angles;

    self.Controls2 setText("^5"+( self.index+1 )+"^7/"+self.z_array.size );

    text = "";

    if( IsDefined( self.z_array[self.index].script_forcespawn ) && self.z_array[self.index].script_forcespawn ) 
	{ 
		text = text+" | forcespawn: "+self.z_array[self.index].script_forcespawn;
	}

    if( IsDefined( self.z_array[self.index].target ) && self.z_array[self.index].target != "" ) 
	{ 
		text = text+" | target: "+self.z_array[self.index].target;
	}
                
    if( IsDefined( self.z_array[self.index].zone_name ) && self.z_array[self.index].zone_name != "" ) 
	{ 
	    text = text+" | zone: "+self.z_array[self.index].zone_name;
	} 

    if( isDefined(self.z_array[self.index].script_string) && self.z_array[self.index].script_string != "" ){
                    
        text = text+" | type: "+self.z_array[self.index].script_string;

    }else if( isDefined(self.z_array[self.index].script_noteworthy) && self.z_array[self.index].script_noteworthy != "" ){

        text = text+" | type: "+self.z_array[self.index].script_noteworthy;

    }else if( IsArray(self.z_array[self.index]) ){

        text = text+" | type: Spawner is an array!";
        self iPrintLnBold("Spawn is array");

    }

    self.Controls3 setText(text);
    
}

god(){
    level endon( "game_ended" );
    self endon( "disconnect" );

    while (true){
        wait 0.5;
        self waittill( "weapon_fired", weapon ); 
        // Evita que Samantha te mate al estar fuera del mapa
        self notify("stop_player_out_of_playable_area_monitor");
        self notify( "stop_player_too_many_weapons_monitor" );

        // Te activa el god mode
        self EnableInvulnerability();
        self.ignoreme = 1;
        self.score = 77770;

        self SetWeaponAmmoClip(weapon, 777);

    }

}