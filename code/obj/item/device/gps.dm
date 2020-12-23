/obj/item/device/gps
	name = "space GPS"
	desc = "Tells you your coordinates based on the nearest coordinate beacon."
	icon_state = "gps-off"
	item_state = "electronic"
	var/is_broadcasting = TRUE // defaults to on so people know where you are (sort of!)
	var/serial = "4200" // shouldnt show up as this
	var/identifier = "NT13" // four characters max plz
	var/distress = 0
	var/active = 0		//probably should
	var/track_x
	var/track_y
	var/track_z
	var/atom/tracking_target = null		//unafilliated with is_broadcasting, which essentially just lets your gps appear on other gps lists
	flags = FPRINT | TABLEPASS | CONDUCT | TGUI_INTERACTIVE
	w_class = 2.0
	m_amt = 50
	g_amt = 100
	mats = 2
	module_research = list("science" = 1, "devices" = 1, "miniaturization" = 8)
	var/frequency = "1453"
	var/net_id
	var/datum/radio_frequency/radio_control

/obj/item/device/gps/New()
	..()
	serial = rand(4201,7999)
	START_TRACKING
	if (radio_controller)
		src.net_id = generate_net_id(src)
		radio_control = radio_controller.add_object(src, "[frequency]")

/* INTERFACE */

/obj/item/device/gps/ui_interact(mob/user, datum/tgui/ui)
	ui = tgui_process.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "GPS", name)
		ui.open()

/obj/item/device/gps/ui_data(mob/user)
	var/turf/current_turf = get_turf(src)
	var/list/gps_list = null
	var/list/implant_list = null
	var/list/beacon_list = null

	for_by_tcl(gps, /obj/item/device/gps)
		LAGCHECK(LAG_LOW)
		if (gps.is_broadcasting)
			var/turf/T = get_turf(gps.loc)
			if (!T)
				continue
			gps_list += list(
				"serial" = gps.serial,
				"ident" = gps.identifier,
				"distress" = gps.distress,
				"x" = T.x,
				"y" = T.y,
				"z" = src.get_z_info(T)
			)

	for_by_tcl(imp, /obj/item/implant/tracking)
		LAGCHECK(LAG_LOW)
		if (isliving(imp.loc))
			var/turf/T = get_turf(imp.loc)
			if (!T)
				continue
			implant_list += list(
				"name" = imp.loc.name,
				"x" = T.x,
				"y" = T.y,
				"z" = src.get_z_info(T)
			)

	for (var/obj/machinery/beacon/beac as() in machine_registry[MACHINES_BEACONS])
		if (beac.enabled == 1)
			var/turf/T = get_turf(beac.loc)
			beacon_list += list(
				"name" = beac.sname,
				"x" = T.x,
				"y" = T.y,
				"z" = src.get_z_info(T)
			)

	. = list(
		"current_location" = list(
			"x" = current_turf.x,
			"y" = current_turf.y,
			"z" = current_turf.z,
		),
		"tracking" = src.tracking_target,
		"serial" = src.serial,
		"identifier" = src.identifier,
		"broadcasting" = src.is_broadcasting,
		"distress" = src.distress,
		"gpses" = gps_list,
		"implants" = implant_list,
		"beacons" = beacon_list
	)

/obj/item/device/gps/ui_state(mob/user)
	return tgui_physical_state

/obj/item/device/gps/ui_status(mob/user)
  return min(
		tgui_physical_state.can_use_topic(src, user),
		tgui_not_incapacitated_state.can_use_topic(src, user)
	)

/obj/item/device/gps/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return
	var/turf/T = get_turf(usr)
	switch(action)
		if ("get_coords")
			boutput(usr, "<span class='notice'>Located at: <b>X</b>: [T.x], <b>Y</b>: [T.y]</span>")
		if ("toggle_broadcasting")
			src.is_broadcasting = !src.is_broadcasting
			boutput(usr, "<span class='notice'>Tracking [is_broadcasting ? "enabled" : "disabled"].</span>")
			. = TRUE
		if ("set_ident")
			var/t = strip_html(input(usr, "Enter new GPS identification name (must be 4 characters)", src.identifier) as text)
			if(length(t) > 4)
				boutput(usr, "<span class='alert'>Input too long.</span>")
				return
			if(length(t) < 4)
				boutput(usr, "<span class='alert'>Input too short.</span>")
				return
			if(!t)
				return
			src.identifier = t
			. = TRUE
		if ("toggle_distress")
			src.distress = !src.distress
			boutput(usr, "<span class='alert'>[distress ? "Sending distress signal" : "Distress signal cleared"].</span>")
			src.send_distress_signal(distress)
			. = TRUE
		if ("track_coords")
			var/x = params["x"]
			var/y = params["y"]
			obtain_target_from_coords(x,y)
		if ("stop_tracking")
			tracking_target = null
			active = null
			icon_state = "gps-off"

	src.add_fingerprint(usr)

/obj/item/device/gps/proc/get_z_info(var/turf/T)
	. =  "Landmark: Unknown"
	if (!T)
		return
	if (!istype(T))
		T = get_turf(T)
	if (!T)
		return
	if (T.z == 1)
		. = "Landmark: [capitalize(station_or_ship())]"
	else if (T.z == 2)
		. =  "Landmark: Restricted"
	else if (T.z == 3)
		. =  "Landmark: Debris Field"

/obj/item/device/gps/get_desc(dist, mob/user)
	. = "<br>Its serial code is [src.serial]-[identifier]."
	if (dist < 2)
		. += "<br>There's a sticker on the back saying \"Net Identifier: [net_id]\" on it."

/obj/item/device/gps/proc/obtain_target_from_coords(x, y)
	tracking_target = null
	if (!x || !y)
		boutput(usr, "<span class='alert'>GPS/TGUI: Not passed x,y:[x],[y]!!</span>")
		return
	// This is to get a turf with the specified coordinates on the same Z as the device
	var/turf/T = get_turf(src) //bugfix for this not working when src was in containers
	var/z = T.z

	T = locate(x,y,z)
	//Set located turf to be the tracking_target
	if (isturf(T))
		src.tracking_target = T
		boutput(usr, "<span class='notice'>Now tracking: <b>X</b>: [T.x], <b>Y</b>: [T.y]</span>")

		begin_tracking()
	else
		boutput(usr, "<span class='alert'>Invalid GPS coordinates.</span>")

/obj/item/device/gps/proc/begin_tracking()
	if(!active)
		if (!src.tracking_target)
			usr.show_text("No target specified, cannot activate the pinpointer.", "red")
			return
		active = 1
		process()
		boutput(usr, "<span class='notice'>You activate the gps</span>")

/obj/item/device/gps/proc/send_distress_signal(distress)
	var/distressAlert = distress ? "help" : "clear"
	var/turf/T = get_turf(usr)
	var/datum/signal/reply = get_free_signal()
	reply.source = src
	reply.data["sender"] = src.net_id
	reply.data["identifier"] = "[src.serial]-[src.identifier]"
	reply.data["coords"] = "[T.x],[T.y]"
	reply.data["location"] = "[src.get_z_info(T)]"
	reply.data["distress_alert"] = "[distressAlert]"
	radio_control.post_signal(src, reply)

/obj/item/device/gps/process()
	if(!active || !tracking_target)
		active = 0
		icon_state = "gps-off"
		return

	src.set_dir(get_dir(src,tracking_target))
	if (get_dist(src,tracking_target) == 0)
		icon_state = "gps-direct"
	else
		icon_state = "gps"

	SPAWN_DBG(0.5 SECONDS) .()

/obj/item/device/gps/disposing()
	STOP_TRACKING
	if (radio_controller)
		radio_controller.remove_object(src, "[src.frequency]")
	..()

/obj/item/device/gps/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption)
		return

	var/sender = signal.data["sender"]

	if (lowertext(signal.data["distress_alert"]))
		var/senderName = signal.data["identifier"]
		if (!senderName)
			return
		if (lowertext(signal.data["distress_alert"] == "help"))
			src.visible_message("<b>[bicon(src)] [src]</b> beeps, \"NOTICE: Distress signal recieved from GPS [senderName].\".")
		else if (lowertext(signal.data["distress_alert"] == "clear"))
			src.visible_message("<b>[bicon(src)] [src]</b> beeps, \"NOTICE: Distress signal cleared by GPS [senderName].\".")
		return
	else if (!signal.data["sender"])
		return
	else if (signal.data["address_1"] == src.net_id && src.is_broadcasting)
		var/datum/signal/reply = get_free_signal()
		reply.source = src
		reply.data["sender"] = src.net_id
		reply.data["address_1"] = sender
		switch (lowertext(signal.data["command"]))
			if ("help")
				if (!signal.data["topic"])
					reply.data["description"] = "GPS unit - Provides space-coordinates and transmits distress signals"
					reply.data["topics"] = "status"
				else
					reply.data["topic"] = signal.data["topic"]
					switch (lowertext(signal.data["topic"]))
						if ("status")
							reply.data["description"] = "Returns the status of the GPS unit, including identifier, coords, location, and distress status. Does not require any arguments"
						else
							reply.data["topic"] = signal.data["topic"]
							reply.data["description"] = "ERROR: UNKNOWN TOPIC"
			if ("status")
				var/turf/T = get_turf(src)
				reply.data["identifier"] = "[src.serial]-[src.identifier]"
				reply.data["coords"] = "[T.x],[T.y]"
				reply.data["location"] = "[src.get_z_info(T)]"
				reply.data["distress"] = "[src.distress]"
			else
				return //COMMAND NOT RECOGNIZED
		radio_control.post_signal(src, reply)

	else if (lowertext(signal.data["address_1"]) == "ping" && src.is_broadcasting)
		var/datum/signal/pingsignal = get_free_signal()
		pingsignal.source = src
		pingsignal.data["device"] = "WNET_GPS"
		pingsignal.data["netid"] = src.net_id
		pingsignal.data["address_1"] = sender
		pingsignal.data["command"] = "ping_reply"
		pingsignal.data["data"] = "[src.serial]-[src.identifier]"
		pingsignal.data["distress"] = "[src.distress]"
		pingsignal.transmission_method = TRANSMISSION_RADIO

		radio_control.post_signal(src, pingsignal)









// coordinate beacons. pretty useless but whatever you never know

/obj/machinery/beacon
	name = "coordinate beacon"
	desc = "A coordinate beacon used for space GPSes."
	icon = 'icons/obj/ship.dmi'
	icon_state = "beacon"
	machine_registry_idx = MACHINES_BEACONS
	var/sname = "unidentified"
	var/enabled = 1

	process()
		if(enabled == 1)
			use_power(50)

	attack_hand()
		enabled = !enabled
		boutput(usr, "<span class='notice'>You switch the beacon [src.enabled ? "on" : "off"].</span>")

	attack_ai(mob/user as mob)
		var/t = input(user, "Enter new beacon identification name", src.sname) as null|text
		if (isnull(t))
			return
		t = strip_html(replacetext(t, "'",""))
		t = copytext(t, 1, 45)
		if (!t)
			return
		src.sname = t
