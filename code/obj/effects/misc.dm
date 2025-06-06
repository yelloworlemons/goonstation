/obj/effects/lightshaft
	name = "light"
	anchored = ANCHORED
	icon = 'icons/effects/224x224.dmi'
	icon_state = "light2"
	pixel_x = -96
	layer = EFFECTS_LAYER_4
	plane = PLANE_NOSHADOW_ABOVE

/obj/effects/lightshaft/blue
	icon_state = "light"

/obj/effects/electro
	name = "energy"
	anchored = ANCHORED
	icon = 'icons/effects/224x224.dmi'
	icon_state = "electro"
	pixel_x = -96
	pixel_y = -96
	layer = EFFECTS_LAYER_4

/obj/effects/explosion/small
	name = "explosion"
	anchored = ANCHORED
	icon = 'icons/effects/64x64.dmi'
	icon_state = "explsmall"
	pixel_x = -16
	pixel_y = -16
	layer = EFFECTS_LAYER_4

/obj/effects/explosion/fiery
	name = "explosion"
	anchored = ANCHORED
	icon = 'icons/effects/64x64.dmi'
	icon_state = "explo_fiery"
	pixel_x = -16
	pixel_y = -16
	layer = EFFECTS_LAYER_4

/obj/effects/explosion/smoky
	name = "explosion"
	anchored = ANCHORED
	icon = 'icons/effects/96x96.dmi'
	icon_state = "explo_smoky"
	pixel_x = -32
	pixel_y = -32
	layer = EFFECTS_LAYER_4

/obj/effects/gang_crate_indicator
	name = "gang crate indicator"
	anchored = ANCHORED
	icon = null
	pixel_x = 0
	pixel_y = 0
	layer = EFFECTS_LAYER_4

/obj/effects/magicspark
	name = "magic spark"
	anchored = ANCHORED_ALWAYS
	icon = 'icons/effects/160x160.dmi'
	icon_state = "magicspark"
	layer = EFFECTS_LAYER_4
	plane = PLANE_DEFAULT_NOWARP

	New()
		. = ..()
		src.pixel_x -= 80
		src.pixel_y -= 80
		SPAWN(2.5 SECONDS) qdel(src)
