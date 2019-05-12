extends Node

var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
var automate = true
var channels = []

func _ready():
	peer = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [
			{
				"urls": ["stun:stun.l.google.com:19302", "stun:stun.2.google.com:19302"]
			},
#			{
#				"username": "fales",
#				"credential": "mypassword",
#				"urls": ["turn:127.0.0.1:3478"],
#			}
		]
	})
	channels.append(peer.create_data_channel("negotiated1", {
		"ordered": false,
		"maxPacketLifeTime": 200,
		#"maxRetransmits": 5,
		"negotiated": true,
		"protocol": "myCustomProtocol",
		"id": 10
	}))
	channels.append(peer.create_data_channel("negotiated2", {
		"ordered": true,
		#"maxPacketLifeTime": 100,
		"maxRetransmits": 1,
		"negotiated": true,
		"protocol": "myCustomProtocol2",
		"id": 2
	}))
	_log(str(channels[0].get_ready_state()))
	LocalServer.register(get_path())
	peer.connect("ice_candidate_created", self, "new_ice_candidate")
	peer.connect("session_description_created", self, "offer_created")
	peer.connect("data_channel_received", self, "data_channel_received")

func data_channel_received(p_channel : WebRTCDataChannel):
	_log("Received channel: %s - label: %s" % [p_channel, p_channel.get_label()])
	channels.append(p_channel)

func new_ice_candidate(mid_name, index_name, sdp_name):
	_log("Candidate")
	_log(sdp_name)
	if automate:
		LocalServer.new_candidate(get_path(), mid_name, index_name, sdp_name)

func _process(delta):
	peer.poll()
	var i = 0
	for c in channels:
		if c and c.get_available_packet_count() > 0:
			_log("<%s> (%d), count: %s" % [_describe_ch(c), i, str(c.get_available_packet_count())])
			$HBoxContainer/Logs/Msg.text += c.get_packet().get_string_from_utf8() + "\n"
		i += 1

func offer_created(type, offer):
	_log("Offer")
	_log(type)
	_log(offer)
	peer.set_local_description(type, offer)
	if automate:
		LocalServer.new_offer(get_path(), type, offer)

func _log(msg):
	print(msg)
	$HBoxContainer/Logs/Local.text += "%s\n" % str(msg)

func _describe_ch(ch):
	return "Channel: label=%s, protocol=%s, id=%d, ordered=%s, max_packet_life_time=%d, retransmits=%s, negotiated=%s" % [
		ch.get_label(),
		ch.get_protocol(),
		ch.get_id(),
		ch.is_ordered(),
		ch.get_max_packet_life_time(),
		ch.get_max_retransmits(),
		ch.is_negotiated()
	]

###
### GUI
###

func _set_remote_desc(type):
	var offer = $HBoxContainer/Offer/TextEdit.text
	$HBoxContainer/Offer/TextEdit.text = ""
	peer.set_remote_description(type, offer)

func _on_SetRemoteOffer_pressed():
	_set_remote_desc("offer")

func _on_SetRemoteAnswer_pressed():
	_set_remote_desc("answer")

func _on_Send_pressed():
	print(peer.get_connection_state())
	var i = 0
	for c in channels:
		print("State %s, size %s" % [c.get_ready_state(), $HBoxContainer/Offer/Send/LineEdit.text.to_utf8().size()])
		_log("Send msg (ch %d) result: %d" % [i, c.put_packet($HBoxContainer/Offer/Send/LineEdit.text.to_utf8())])
		i += 1
	$HBoxContainer/Offer/Send/LineEdit.text = ""

func _on_IceCandidate_pressed():
	var candidate = $HBoxContainer/Offer/IceCandidate/LineEdit.text
	peer.add_ice_candidate("data", 0, candidate)
	$HBoxContainer/Offer/IceCandidate/LineEdit.text = ""

func _on_Button_pressed():
	print("pressed")
	channels.append(peer.create_data_channel("auto", {}))
	channels.append(peer.create_data_channel("inband", {
		"ordered": false,
		"maxPacketLifeTime": 100,
		"protocol": "myProtocol",
	}))
#	channels.append(peer.create_data_channel("test2", {}))
	peer.create_offer()

func _on_Automate_toggled(button_pressed):
	automate = button_pressed

func _on_Close_pressed():
	peer.close()
	peer.initialize()
