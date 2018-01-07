
rubble.usertemplate("@CH_STANDARD_CONFIGURATION", {{"mats", ""}, {"tissues", ""}, {"extras", ""}, {"doless", "NO"}},
[=[{@}[BODY_DETAIL_PLAN:STANDARD_MATERIALS]{@IF;%mats;;;"\n\t%mats"}
	[BODY_DETAIL_PLAN:STANDARD_TISSUES]{@IF;%tissues;;;"\n\t%tissues"}
	[BODY_DETAIL_PLAN:VERTEBRATE_TISSUE_LAYERS:SKIN:FAT:MUSCLE:BONE:CARTILAGE]{@IF;%extras;;;"\n\n\t%extras"}
	
	{@IF;%doless;NO;;
	[BODY_DETAIL_PLAN:STANDARD_HEAD_POSITIONS]
	
	[SELECT_TISSUE_LAYER:HEART:BY_CATEGORY:HEART]
	[PLUS_TISSUE_LAYER:SKIN:BY_CATEGORY:THROAT]
		[TL_MAJOR_ARTERIES]
	
	{#}}{@CH_BLOOD_N_PUS}]=])

rubble.usertemplate("@CH_BLOOD_N_PUS", {},
[=[{@}[USE_MATERIAL_TEMPLATE:SINEW:SINEW_TEMPLATE]
	[TENDONS:LOCAL_CREATURE_MAT:SINEW:200]
	[LIGAMENTS:LOCAL_CREATURE_MAT:SINEW:200]
	[HAS_NERVES]
	
	[USE_MATERIAL_TEMPLATE:BLOOD:BLOOD_TEMPLATE]
	[BLOOD:LOCAL_CREATURE_MAT:BLOOD:LIQUID]
	
	[USE_MATERIAL_TEMPLATE:PUS:PUS_TEMPLATE]
	[PUS:LOCAL_CREATURE_MAT:PUS:LIQUID]
	[GETS_WOUND_INFECTIONS]
	[GETS_INFECTIONS_FROM_ROT]{@}]=])

rubble.usertemplate("@CH_BUG_CONFIGURATION", {{"mats", ""}, {"tissues", ""}, {"extras", ""}, {"doless", "NO"}},
[=[{@}[BODY_DETAIL_PLAN:CHITIN_MATERIALS]{@IF;%mats;;;"\n\t%mats"}
	[BODY_DETAIL_PLAN:CHITIN_TISSUES]{@IF;%tissues;;;"\n\t%tissues"}
	[BODY_DETAIL_PLAN:EXOSKELETON_TISSUE_LAYERS:CHITIN:FAT:MUSCLE]{@IF;%extras;;;"\n\n\t%extras"}
	
	[BODY_DETAIL_PLAN:STANDARD_HEAD_POSITIONS]
	
	{@IF;%doless;NO;;
	[BODY_DETAIL_PLAN:STANDARD_HEAD_POSITIONS]
	
	[SELECT_TISSUE_LAYER:HEART:BY_CATEGORY:HEART]
		[TL_MAJOR_ARTERIES]
	
	{#}}{@CH_ICHOR_N_PUS}]=])

rubble.usertemplate("@CH_ICHOR_N_PUS", {},
[=[{@}[USE_MATERIAL_TEMPLATE:SINEW:SINEW_TEMPLATE]
	[TENDONS:LOCAL_CREATURE_MAT:SINEW:200]
	[LIGAMENTS:LOCAL_CREATURE_MAT:SINEW:200]
	[HAS_NERVES]
	
	[USE_MATERIAL_TEMPLATE:ICHOR:ICHOR_TEMPLATE]
	[BLOOD:LOCAL_CREATURE_MAT:ICHOR:LIQUID]
	
	[USE_MATERIAL_TEMPLATE:PUS:PUS_TEMPLATE]
	[PUS:LOCAL_CREATURE_MAT:PUS:LIQUID]
	[GETS_WOUND_INFECTIONS]
	[GETS_INFECTIONS_FROM_ROT]{@}]=])

rubble.template("@CH_GAIT", function(gait, kph)
	gait, kph = rubble.expandargs(gait, kph)
	kph = tonumber(kph)
	if kph == nil or kph < 1 or kph > 87 then
		rubble.abort("Invalid speed (not numeric or out of range).")
	end
	
	return "[APPLY_CREATURE_VARIATION:"..gait..":"..({
		"9000:8900:8825:8775:9500:9900] 1 kph",
		"8390:8204:8040:4388:8989:9567] 2 kph",
		"7780:7508:7254:2925:8478:9233] 3 kph",
		"7171:6811:6469:2193:7967:8900] 4 kph",
		"6561:6115:5683:1755:7456:8567] 5 kph",
		"5951:5419:4898:1463:6944:8233] 6 kph",
		"5341:4723:4112:1254:6433:7900] 7 kph",
		"4732:4026:3327:1097:5922:7567] 8 kph",
		"4122:3330:2541:975:5411:7233] 9 kph",
		"3512:2634:1756:878:4900:6900] 10 kph",
		"3251:2446:1640:798:4600:6500] 11 kph",
		"2990:2257:1525:731:4300:6100] 12 kph",
		"2728:2069:1409:675:4000:5700] 13 kph",
		"2467:1880:1294:627:3700:5300] 14 kph",
		"2206:1692:1178:585:3400:4900] 15 kph",
		"1945:1504:1062:548:3100:4500] 16 kph",
		"1683:1315:947:516:2800:4100] 17 kph",
		"1422:1127:831:488:2500:3700] 18 kph",
		"1161:938:716:462:2200:3300] 19 kph",
		"900:750:600:439:1900:2900] 20 kph",
		"900:746:592:418:1900:2900] 21 kph",
		"900:742:584:399:1900:2900] 22 kph",
		"900:738:576:382:1900:2900] 23 kph",
		"900:734:568:366:1900:2900] 24 kph",
		"900:730:561:351:1900:2900] 25 kph",
		"900:726:553:338:1900:2900] 26 kph",
		"900:722:545:325:1900:2900] 27 kph",
		"900:718:537:313:1900:2900] 28 kph",
		"900:714:529:303:1900:2900] 29 kph",
		"900:711:521:293:1900:2900] 30 kph",
		"900:707:513:283:1900:2900] 31 kph",
		"900:703:505:274:1900:2900] 32 kph",
		"900:699:497:266:1900:2900] 33 kph",
		"900:695:489:258:1900:2900] 34 kph",
		"900:691:482:251:1900:2900] 35 kph",
		"900:687:474:244:1900:2900] 36 kph",
		"900:683:468:237:1900:2900] 37 kph",
		"900:679:458:231:1900:2900] 38 kph",
		"900:675:450:225:1900:2900] 39 kph",
		"900:657:438:219:1900:2900] 40 kph",
		"900:642:428:214:1900:2900] 41 kph",
		"900:627:418:209:1900:2900] 42 kph",
		"900:612:408:204:1900:2900] 43 kph",
		"900:597:398:199:1900:2900] 44 kph",
		"900:585:390:195:1900:2900] 45 kph",
		"900:573:382:191:1900:2900] 46 kph",
		"900:561:374:187:1900:2900] 47 kph",
		"900:549:366:183:1900:2900] 48 kph",
		"900:537:358:179:1900:2900] 49 kph",
		"900:528:352:176:1900:2900] 50 kph",
		"900:519:346:173:1900:2900] 51 kph",
		"900:507:338:169:1900:2900] 52 kph",
		"900:498:332:166:1900:2900] 53 kph",
		"900:489:326:163:1900:2900] 54 kph",
		"900:480:320:160:1900:2900] 55 kph",
		"900:471:314:157:1900:2900] 56 kph",
		"900:462:308:154:1900:2900] 57 kph",
		"900:453:302:151:1900:2900] 58 kph",
		"900:447:298:149:1900:2900] 59 kph",
		"900:438:292:146:1900:2900] 60 kph",
		"900:432:288:144:1900:2900] 61 kph",
		"900:426:284:142:1900:2900] 62 kph",
		"900:417:278:139:1900:2900] 63 kph",
		"900:411:274:137:1900:2900] 64 kph",
		"900:405:270:135:1900:2900] 65 kph",
		"900:399:266:133:1900:2900] 66 kph",
		"900:393:262:131:1900:2900] 67 kph",
		"900:387:258:129:1900:2900] 68 kph",
		"900:381:254:127:1900:2900] 69 kph",
		"900:375:250:125:1900:2900] 70 kph",
		"900:372:248:124:1900:2900] 71 kph",
		"900:366:244:122:1900:2900] 72 kph",
		"900:360:240:120:1900:2900] 73 kph",
		"900:357:238:119:1900:2900] 74 kph",
		"900:351:234:117:1900:2900] 75 kph",
		"900:345:230:115:1900:2900] 76 kph",
		"900:342:228:114:1900:2900] 77 kph",
		"900:336:224:112:1900:2900] 78 kph",
		"900:333:222:111:1900:2900] 79 kph",
		"900:327:218:109:1900:2900] 80 kph",
		"900:324:216:108:1900:2900] 81 kph",
		"900:321:214:107:1900:2900] 82 kph",
		"900:315:210:105:1900:2900] 83 kph",
		"900:312:208:104:1900:2900] 84 kph",
		"900:309:206:103:1900:2900] 85 kph",
		"900:306:204:102:1900:2900] 86 kph",
		"900:300:200:100:1900:2900] 87+ kph",
	})[kph]
end)

rubble.usertemplate("@CH_GAITS_STANDARD", {{"walk", "-"}, {"crawl", "-"}, {"swim", "-"}, {"climb", "-"}, {"fly", "-"}},
[=[{@_CH_GAITS_INTERNAL;STANDARD_WALKING_GAITS;%walk;%crawl;%swim;%climb;%fly}]=])

rubble.usertemplate("@CH_GAITS_QUADRUPED", {{"walk", "-"}, {"crawl", "-"}, {"swim", "-"}, {"climb", "-"}, {"fly", "-"}},
[=[{@_CH_GAITS_INTERNAL;STANDARD_QUADRUPED_GAITS;%walk;%crawl;%swim;%climb;%fly}]=])

rubble.usertemplate("@CH_GAITS_BIPED", {{"walk", "-"}, {"crawl", "-"}, {"swim", "-"}, {"climb", "-"}, {"fly", "-"}},
[=[{@_CH_GAITS_INTERNAL;STANDARD_BIPED_GAITS;%walk;%crawl;%swim;%climb;%fly}]=])

rubble.usertemplate("@CH_GAITS_CRAWL", {{"walk", "-"}, {"crawl", "-"}, {"swim", "-"}, {"climb", "-"}, {"fly", "-"}},
[=[{@_CH_GAITS_INTERNAL;STANDARD_WALK_CRAWL_GAITS;%walk;%crawl;%swim;%climb;%fly}]=])

rubble.usertemplate("@_CH_GAITS_INTERNAL", {{"walktyp", ""}, {"walk", "-"}, {"crawl", "-"}, {"swim", "-"}, {"climb", "-"}, {"fly", "-"}},
[=[{@IF;%walk;-;;"\t{@CH_GAIT;%walktyp;%walk}\n"}{C;
	}{@IF;%crawl;-;;"\t{@CH_GAIT;STANDARD_CRAWLING_GAITS;%crawl}\n"}{C;
	}{@IF;%swim;-;;"\t{@CH_GAIT;STANDARD_SWIMMING_GAITS;%swim}\n"}{C;
	}{@IF;%climb;-;;"\t{@CH_GAIT;STANDARD_CLIMBING_GAITS;%climb}\n"}{C;
	}{@IF;%fly;-;;"\t{@CH_GAIT;STANDARD_FLYING_GAITS;%fly}\n"}]=])

rubble.template("@CH_HEADER", function(name, plural, adj, baby, tile, fg, bg, desc)
	local vanillacolor = false
	if desc == nil then
		desc = bg
		name, plural, adj, baby, tile, fg, desc = rubble.expandargs(name, plural, adj, baby, tile, fg, desc)
	else
		name, plural, adj, baby, tile, fg, bg, desc = rubble.expandargs(name, plural, adj, baby, tile, fg, bg, desc)
	end
	
	if adj == "NAME" then
		adj = name
	end
	
	if plural == "STP" then
		plural = name.."s"
	end
	
	local extra = ""
	if rubble.tobool(baby) then
		extra = extra.."\n\t[GENERAL_BABY_NAME:"..adj.." baby:"..adj.." babies]\n"..
		"\t[BABYNAME:"..adj.." baby:"..adj.." babies]\n"..
		"\t[GENERAL_CHILD_NAME:"..adj.." child:"..adj.." children]\n"..
		"\t[CHILDNAME:"..adj.." child:"..adj.." children]"
	end
	
	if vanillacolor then
		return "[DESCRIPTION:"..desc.."]\n"..
		"\t[NAME:"..name..":"..plural..":"..adj.."]\n"..
		"\t[CASTE_NAME:"..name..":"..plural..":"..adj.."]\n"..
		"\t[CREATURE_TILE:"..tile.."][COLOR:"..fg.."]"..extra
	else
		return "[DESCRIPTION:"..desc.."]\n"..
		"\t[NAME:"..name..":"..plural..":"..adj.."]\n"..
		"\t[CASTE_NAME:"..name..":"..plural..":"..adj.."]\n"..
		"\t[CREATURE_TILE:"..tile.."][COLOR:{@COLOR;"..fg..";"..bg.."}]"..extra
	end
end)

rubble.usertemplate("@CH_SPIT_N_TEARS", {},
[=[{@}[USE_MATERIAL_TEMPLATE:SWEAT:SWEAT_TEMPLATE]
	[USE_MATERIAL_TEMPLATE:TEARS:TEARS_TEMPLATE]
	[USE_MATERIAL_TEMPLATE:SPIT:SPIT_TEMPLATE]

	[SECRETION:LOCAL_CREATURE_MAT:SWEAT:LIQUID:BY_CATEGORY:ALL:SKIN:EXERTION]
	[SECRETION:LOCAL_CREATURE_MAT:TEARS:LIQUID:BY_CATEGORY:EYE:ALL:EXTREME_EMOTION]

	[CAN_DO_INTERACTION:MATERIAL_EMISSION]
		[CDI:ADV_NAME:Spit]
		[CDI:USAGE_HINT:NEGATIVE_SOCIAL_RESPONSE]
		[CDI:USAGE_HINT:TORMENT]
		[CDI:BP_REQUIRED:BY_CATEGORY:MOUTH]
		[CDI:MATERIAL:LOCAL_CREATURE_MAT:SPIT:LIQUID_GLOB]
		[CDI:VERB:spit:spits:NA]
		[CDI:TARGET:C:LINE_OF_SIGHT]
		[CDI:TARGET_RANGE:C:15]
		[CDI:MAX_TARGET_NUMBER:C:1]
		[CDI:WAIT_PERIOD:30]{@}]=])

rubble.usertemplate("@CH_STD_MANNERISMS", {},
[=[{@}[MANNERISM_FINGERS:finger:fingers]
	[MANNERISM_NOSE:nose]
	[MANNERISM_EAR:ear]
	[MANNERISM_HEAD:head]
	[MANNERISM_EYES:eyes]
	[MANNERISM_MOUTH:mouth]
	[MANNERISM_HAIR:hair]
	[MANNERISM_KNUCKLES:knuckles]
	[MANNERISM_LIPS:lips]
	[MANNERISM_CHEEK:cheek]
	[MANNERISM_NAILS:nails]
	[MANNERISM_FEET:feet]
	[MANNERISM_ARMS:arms]
	[MANNERISM_HANDS:hands]
	[MANNERISM_TONGUE:tongue]
	[MANNERISM_LEG:leg]
	[MANNERISM_LAUGH]
	[MANNERISM_SMILE]
	[MANNERISM_WALK]
	[MANNERISM_SIT]
	[MANNERISM_BREATH]
	[MANNERISM_POSTURE]
	[MANNERISM_STRETCH]
	[MANNERISM_EYELIDS]{@}]=])

rubble.usertemplate("@CH_ATTACK_BITE", {{"priority", "SECOND"}, {"part", "TOOTH"}},
[=[{@}[ATTACK:BITE:CHILD_BODYPART_GROUP:BY_CATEGORY:HEAD:BY_CATEGORY:%part]
		[ATTACK_SKILL:BITE]
		[ATTACK_VERB:bite:bites]
		[ATTACK_CONTACT_PERC:100]
		[ATTACK_PENETRATION_PERC:100]
		[ATTACK_FLAG_EDGE]
		[ATTACK_PREPARE_AND_RECOVER:3:3]
		[ATTACK_PRIORITY:%priority]
		[ATTACK_FLAG_CANLATCH]{@}]=])

rubble.usertemplate("@CH_ATTACK_SCRATCH", {{"priority", "SECOND"}, {"part", "GRASP"}},
[=[{@}[ATTACK:SCRATCH:CHILD_TISSUE_LAYER_GROUP:BY_TYPE:%part:BY_CATEGORY:ALL:NAIL]
		[ATTACK_SKILL:GRASP_STRIKE]
		[ATTACK_VERB:scratch:scratches]
		[ATTACK_CONTACT_PERC:100]
		[ATTACK_PENETRATION_PERC:100]
		[ATTACK_FLAG_EDGE]
		[ATTACK_PREPARE_AND_RECOVER:3:3]
		[ATTACK_PRIORITY:%priority]{@}]=])

rubble.usertemplate("@CH_ATTACK_KICK", {{"priority", "SECOND"}},
[=[{@}[ATTACK:KICK:BODYPART:BY_TYPE:STANCE]
		[ATTACK_SKILL:STANCE_STRIKE]
		[ATTACK_VERB:kick:kicks]
		[ATTACK_CONTACT_PERC:100]
		[ATTACK_PREPARE_AND_RECOVER:4:4]
		[ATTACK_FLAG_WITH]
		[ATTACK_PRIORITY:%priority]
		[ATTACK_FLAG_BAD_MULTIATTACK]{@}]=])

rubble.usertemplate("@CH_ATTACK_PUNCH", {{"priority", "SECOND"}},
[=[{@}[ATTACK:PUNCH:BODYPART:BY_TYPE:GRASP]
		[ATTACK_SKILL:GRASP_STRIKE]
		[ATTACK_VERB:punch:punches]
		[ATTACK_CONTACT_PERC:100]
		[ATTACK_PREPARE_AND_RECOVER:3:3]
		[ATTACK_FLAG_WITH]
		[ATTACK_PRIORITY:%priority]{@}]=])

rubble.usertemplate("@CH_ATTACK_GORE", {{"priority", "SECOND"}},
[=[{@}[ATTACK:GORE:BODYPART:BY_CATEGORY:HORN]
		[ATTACK_SKILL:BITE]
		[ATTACK_VERB:gore:gores]
		[ATTACK_CONTACT_PERC:100]
		[ATTACK_PREPARE_AND_RECOVER:3:3]
		[ATTACK_FLAG_WITH]
		[ATTACK_PRIORITY:%priority]{@}]=])

rubble.usertemplate("@CH_BAM_GENERIC", {},
[=[{@}[BODY_APPEARANCE_MODIFIER:LENGTH:90:95:98:100:102:105:110]
	[BODY_APPEARANCE_MODIFIER:HEIGHT:90:95:98:100:102:105:110]
	[BODY_APPEARANCE_MODIFIER:BROADNESS:90:95:98:100:102:105:110]{@}]=])

rubble.usertemplate("@CH_CASTES_GENERIC", {{"m", ""}, {"f", ""}}, 
[=[{@}[CASTE:MALE]
		[MALE][CREATURE_CLASS:MALE]
		[SET_BP_GROUP:BY_TYPE:LOWERBODY][BP_ADD_TYPE:GELDABLE]
		[ORIENTATION:FEMALE:0:0:100]
		[ORIENTATION:MALE:100:0:0]{@IF;%m;;;"\n\t\t%m"}
	[CASTE:FEMALE]
		[FEMALE][CREATURE_CLASS:FEMALE]
		[ORIENTATION:MALE:0:0:100]
		[ORIENTATION:FEMALE:100:0:0]{@IF;%f;;;"\n\t\t%f"}
	[SELECT_CASTE:ALL]{@}]=])
