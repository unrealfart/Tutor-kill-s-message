#include <amxmodx>
#include <reapi>

#pragma semicolon 1

new const Title[] = "Tutor kill's message";
new const Version[] = "1.0.0";
new const Author[] = "unrealfart";

const TASK_TUTOR = 57810;

new const g_TutorPrecache[][] = 
{ 
	"gfx/career/icon_!.tga", 
	"gfx/career/icon_!-bigger.tga", 
	"gfx/career/icon_i.tga", 
	"gfx/career/icon_i-bigger.tga", 
	"gfx/career/icon_skulls.tga", 
	"gfx/career/round_corner_ne.tga", 
	"gfx/career/round_corner_nw.tga", 
	"gfx/career/round_corner_se.tga", 
	"gfx/career/round_corner_sw.tga", 
	"resource/TutorScheme.res", 
	"resource/UI/TutorTextWindow.res" 
};

new g_iMsgTutor;
new g_iMsgTutClose;

new TutorColor:g_iColorTutorMessage;
new Float:g_flTimeTutorMessage;

new const g_szWeaponName[][] = 
{
	"",
	"P228",
	"",
	"SCOUT" ,
	"GRENADE",
	"XM1014",
	"C4",
	"MAC10",
	"AUG",
	"",				
	"ELITE",
	"FIVESEVEN",
	"UMP-45",
	"SG550",
	"GALIL",
	"FAMAS",
	"USP",
	"GLOCK18",
	"AWP",
	"MP5",			
	"M249",
	"M3",
	"M4A1",
	"TMP",
	"G3SG1",
	"",
	"DEAGLe",
	"SG552",
	"AK-47",
	"KNIFE",	
	"P90"
};

public plugin_precache()
{
	for(new i = 0; i < sizeof(g_TutorPrecache); i++)
	{	
		precache_generic(g_TutorPrecache[i]);
	}
}

public plugin_init()
{
	register_plugin(Title, Version, Author);
	
	g_iMsgTutor = get_user_msgid("TutorText");
	g_iMsgTutClose = get_user_msgid("TutorClose");

	bind_pcvar_num(create_cvar(
		"tutor_message_color", "1", 
		.description = "Color of tutor message^n1 - red^n2 - blue^n3 - yellow^n4 - green", 
		.has_min = true, .min_val = 1.0, 
		.has_max = true, .max_val = 4.0), 
		g_iColorTutorMessage);

	bind_pcvar_float(create_cvar(
		"tutor_message_time", "7.5", 
		.description = "Time of tutor message", 
		.has_min = true, .min_val = 1.0), 
		g_flTimeTutorMessage);

	AutoExecConfig(true, "kill_message");

	RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice", true);
}

public CSGameRules_DeathNotice(iVictim, iKiller, Inflictor)
{
	new szDeathMessage[192];
	new szConvertedMessage[192];
	
	if(Inflictor == -1)
	{
		formatex(szDeathMessage, charsmax(szDeathMessage), "[%n] committed suicide", iVictim);
	}
	else
	if(Inflictor == 0)
	{
		formatex(szDeathMessage, charsmax(szDeathMessage), "[%n] killed by world", iVictim);
	}
	else
	if(Inflictor > 0)
	{
		new iActiveItem;
		new iWeaponID;
		new bool:bIsHeadshot;

		bIsHeadshot = get_member(iVictim, m_bHeadshotKilled);
		
		iActiveItem = get_member(iKiller, m_pActiveItem);

		if(iActiveItem)
		{
			iWeaponID = get_member(iActiveItem, m_iId);
		}
		formatex(szDeathMessage, charsmax(szDeathMessage), "[%n] killed [%n]%s via %s", iKiller, iVictim, bIsHeadshot ? " to the HEAD" : " ", g_szWeaponName[iWeaponID]);
	}

	utf8Tocp1251(szDeathMessage, szConvertedMessage, charsmax(szConvertedMessage));

	tutorMake(0, g_iColorTutorMessage, g_flTimeTutorMessage, szConvertedMessage);

	return HC_CONTINUE;
}

stock tutorMake(id, TutorColor:Color, Float:fTime = 0.0, const szText[], any:...)
{
	new szMessage[192];
	vformat(szMessage, charsmax(szMessage), szText, 5);
	
	if(!id)
	{
		message_begin(MSG_ALL,g_iMsgTutor);
		write_string(szMessage);
		write_byte(0);
		write_short(0);
		write_short(0);
		write_short(1<<_:Color);
		message_end();
	}
	else if(is_user_connected(id))
	{
		message_begin(MSG_ONE_UNRELIABLE,g_iMsgTutor,_,id);
		write_string(szMessage);
		write_byte(0);
		write_short(0);
		write_short(0);
		write_short(1<<_:Color);
		message_end();
	}
	
	if(fTime != 0.0)
	{
		if(!id)
		{
			for(new i = 1; i <= MaxClients; i++)
				remove_task(i+TASK_TUTOR);
			
			
			set_task(fTime,"tutorClose",TASK_TUTOR);
		}
		else
		{
			remove_task(id+TASK_TUTOR);
			set_task(fTime,"tutorClose",id+TASK_TUTOR);
		}
	}
}

public tutorClose(iTask)
{
	new id = iTask - TASK_TUTOR;
	
	if(!id)
	{
		message_begin(MSG_ALL,g_iMsgTutClose);
		message_end();
	}
	else if(is_user_connected(id))
	{
		message_begin(MSG_ONE_UNRELIABLE,g_iMsgTutClose,_,id);
		message_end();
	}
}

stock utf8Tocp1251(const string[], output[], maxlen)
{
    new i, len, j, char1, char2;
    len = strlen(string);
    while(string[i] && j <= maxlen)
    {
        if(i + 1 < len)
        {
            char1 = string[i] & 0xFF;
            char2 = string[i+1] & 0xFF;

            if (char1 == 0xD0 && char2 == 0x81)
            {
                output[j] = 168;
                i++;
            }
            else if (char1 == 0xD1 && char2 == 0x91)
            {
                output[j] = 184;
                i++;
			}
            else if (char1 == 0xD0 && char2 >= 0x90 && char2 <= 0xBF)
            {
                output[j] = char2 + 48;
                i++;
            }
            else if (char1 == 0xD1 && char2 >= 0x80 && char2 <= 0x8F)
            {
                output[j] = char2 + 112;
                i++;
            }
            else output[j] = string[i];
        }
        else output[j] = string[i];

        i++;
        j++;
    }
    output[maxlen] = 0;
}
