
This addon adds a small set of templates designed to make "normal" creatures a little easier to write. It does not try
to cover every case, only the most common ones. If you need to do something that these templates do not cover just do it
the vanilla way.

Some of the templates do allow you to modify their output in various ways, but most of the time if you need to do anything
but the most trivial tweaks you should not use these templates. Think of this as a set of lazy conveniences and you won't
be far wrong :)

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_STANDARD_CONFIGURATION;<MAT_CONFIG>="";<TISSUE_CONFIG>="";<EXTRAS>="";<DOLESS>="NO"}
	{@CH_BUG_CONFIGURATION;<MAT_CONFIG>="";<TISSUE_CONFIG>="";<EXTRAS>="";<DOLESS>="NO"}

Insert a standard set of materials, tissues, blood (or ichor), pus, and sinew plus default tissue layers, head positions,
and major arteries in the heart and throat. For most creatures all you need to do to finish the body is to place a call
to one of these templates directly after the `BODY` tag.

For the common case of a "normal" creature with no custom materials, tissues, etc you do not need to specify any arguments.

If your creature is not "normal" you can still use these templates, but it will be harder and harder the more the creature
differs from the norm. After a certain point it becomes easier (and clearer) to do it the vanilla way.

The `BUG` version uses the `CHITIN` and `EXOSKELETON` body detail plans and ichor instead of the `STANDARD` and `VERTEBRATE`
BDPs and blood. Also the `BUG` version does not set major arteries in the throat.

`<MAT_CONFIG>` is inserted directly after the materials are inserted, this allows you to remove materials you don't need
or insert custom materials you need later.

`<TISSUE_CONFIG>` is exactly the same as `<MAT_CONFIG>`, but for the tissues.

`<EXTRAS>` is inserted after the tissue layers are set. This is the place to change any body part relative sizes, set
body part positions, etc.

If `<DOLESS>` is not "NO" then major arteries are not set on the heart (and throat for the non `BUG` version) and head
positions are not set. Use this if your creature has a non-standard body (no heart, throat, or head).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_BLOOD_N_PUS}
	{@CH_ICHOR_N_PUS}

These templates are a subsets of `@CH_STANDARD_CONFIGURATION` and `@CH_BUG_CONFIGURATION` that only add blood (or ichor),
sinew, and pus.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_GAIT;<GAIT_CV>;<SPEED>}

This template returns a `APPLY_CREATURE_VARIATION` tag with `<GAIT_CV>` as the variation and the arguments derived from
`<SPEED>`.

For most cases you will want `@CH_GAITS_STANDARD` instead.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_GAITS_STANDARD;<WALK>="-";<CRAWL>="-";<SWIM>="-";<CLIMB>="-";<FLY>="-"}
	{@CH_GAITS_QUADRUPED;<WALK>="-";<CRAWL>="-";<SWIM>="-";<CLIMB>="-";<FLY>="-"}
	{@CH_GAITS_BIPED;<WALK>="-";<CRAWL>="-";<SWIM>="-";<CLIMB>="-";<FLY>="-"}
	{@CH_GAITS_CRAWL;<WALK>="-";<CRAWL>="-";<SWIM>="-";<CLIMB>="-";<FLY>="-"}

These templates insert a full set of gaits for a creature. Each argument should be set to an integer between 1 and 87 *or*
"-". These arguments are the approximate top speed the creature can reach with the given movement type, if set to "-" no
gait is set for that movement type.

`@CH_GAITS_STANDARD` is the only template you really need, the others just use different gait descriptions (cosmetic).

The arguments are carefully ordered so that the most common gait types come first, and the least common last. Instead of
setting them to "-", the last unneeded gaits may simply be omitted.

Example:

	# Gaits for the vanilla dwarf
	{@CH_GAITS_BIPED;30;12;6;6;-}
	
	# Gaits for the vanilla beak dog
	{@CH_GAITS_STANDARD;45;5;5}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_HEADER;<NAME>;<PLURAL>;<ADJ>;<BABY>;<TILE>;<COLOR>;<DESC>}
	{@CH_HEADER;<NAME>;<PLURAL>;<ADJ>;<BABY>;<TILE>;<FG>;<BG>;<DESC>}

This template generates a simple "creature header" containing the name, description, tile, and color.

The first form is the one you will normally use, the second form is a special case for users of `addon:Libs/Colors`,
unless you are working on a total conversion with a custom base the second form is of little use.

If you set `<ADJ>` to `NAME` then the value of the name field will be used as the adjective. Using `STP` for `<PLURAL>`
works exactly like it does in vanilla.

If `<BABY>` is set to `YES` then baby and child names are generated from the value of the `<ADJ>` argument.

Examples:

	# Vanilla DF:
	{@CH_HEADER;dwarf;dwarves;dwarven;YES;1;3:0:0;A short, sturdy creature fond of drink and industry}
	
	# With "Libs/Colors" and an appropriate base:
	{@CH_HEADER;dwarf;dwarves;dwarven;YES;1;CYAN;BLACK;A short, sturdy creature fond of drink and industry}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_SPIT_N_TEARS}

This very simple template inserts spit, sweat, and tears (and the tags needed to make them work).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_STD_MANNERISMS}

This very simple template inserts all the standard mannerisms with generic names. If your creature is a more-or-less
normal humanoid this is what you want, otherwise you'll have to insert all that crap on your own.

AFAIK mannerisms are only useful in playable races.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_ATTACK_BITE;[<PRIORITY>="SECOND"];<PART>="TOOTH"}
	{@CH_ATTACK_SCRATCH;[<PRIORITY>="SECOND"];<PART>="GRASP"}
	{@CH_ATTACK_KICK;[<PRIORITY>="SECOND"]}
	{@CH_ATTACK_PUNCH;[<PRIORITY>="SECOND"]}
	{@CH_ATTACK_GORE;[<PRIORITY>="SECOND"]}

These templates insert basic attacks, nothing special, but they cover the vast majority of cases. Some templates allow
you to specify an optional part to help decide what bit of the creature is used for the attack. For bite attacks this is
generally `TOOTH` or `MOUTH`, for scratch attacks this is `STANCE` or `GRASP`.


If you need special tags added to a basic attack you can just list them directly after the template.

Example:

	# The vanilla Nightwing's bite attack:
	{@CH_ATTACK_BITE;MAIN}
		[SPECIALATTACK_SUCK_BLOOD:50:100]

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_BAM_GENERIC}

This template adds the three common body appearance modifiers (length, height, broadness), with their common ranges of
90 to 110.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CH_CASTES_GENERIC;[<MALE_EXTRA>=""];[<FEMALE_EXTRA>=""]}

This template adds generic male and female castes, you can add extra stuff to the castes here if you want, but if you were
going to do that then why didn't you define your own castes?

In addition to the standard `MALE` and `FEMALE` tags I also add `MALE` and `FEMALE` creature classes, so if you want
gender specific creature targeting you don't need to add anything...

`[SELECT_CASTE:ALL]` is inserted as the last part of the template, so you don't have to remember to do it yourself.


Model Creature:
------------------------------------------------------------------------------------------------------------------------

What follows is a "model creature" using the templates defined above to define a creature that is a short as possible
(without being trivial). This creature is an actual creature from one of my mods. As you can see, the only tags left are
those that are in some way important to this individual creature, and not creatures in general.

	{!SHARED_CREATURE;PLATEDCREEPER;
		# Named colors ("GREEN;BLACK") only work if `Libs/Colors` is used and color names are defined
		# (which is not the case with the default base).
		{@CH_HEADER;plated creeper;STP;NAME;NO;'P';GREEN;BLACK;A gigantic armored caterpillar that will relentlessly, but slowly, seek out food in the Underhive.}
		[PREFSTRING:tough carapace] # Pref strings are not covered by @CH_HEADER since you can add more than one.
		
		[BIOME:SUBTERRANEAN_CHASM]
		[UNDERGROUND_DEPTH:1:1]
		[POPULATION_NUMBER:300:500]
		[CLUSTER_NUMBER:1:1]
		
		[LARGE_ROAMING]
		[CURIOUSBEAST_EATER][CARNIVORE]
		[NATURAL][ALL_ACTIVE]
		[NOBONES][NOEMOTION][NOFEAR][NO_DIZZINESS]
		[GRASSTRAMPLE:20]
		[EXTRAVISION]
		[PRONE_TO_RAGE:1]
		[HOMEOTHERM:10040]
		
		[BODY:BASIC_1PARTBODY:BASIC_HEAD:TAIL:HEART:GUTS:BRAIN:MOUTH]
		
		{@CH_BUG_CONFIGURATION}
		
		{@CH_GAITS_STANDARD;20;5}
		
		[BODY_SIZE:0:0:20000]
		[BODY_SIZE:1:0:140000]
		{@CH_BAM_GENERIC}
		[MAXAGE:2:5]
		
		{@CH_ATTACK_BITE;MAIN}
		
		{@CH_CASTES_GENERIC}
		
		[SET_TL_GROUP:BY_CATEGORY:ALL:CHITIN]
			[TL_COLOR_MODIFIER:{@COLOR;GRAY}:1]
				[TLCM_NOUN:chitin:SINGULAR]
		
		[SELECT_MATERIAL:ALL]
			[MULTIPLY_VALUE:3]
	}
