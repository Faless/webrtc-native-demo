extends Node


# The commented line will be used instead,
# and the script will be set as a project property
# when everything is done and awesome
#var peer = WebRTCPeer.new()
const NativeWebRTC = preload("res://webrtc/webrtc.gdns")
var peer = NativeWebRTC.new()

var automate = true

func _ready():
	LocalServer.register(get_path())
	peer.connect("new_ice_candidate", self, "new_ice_candidate")
	peer.connect("offer_created", self, "offer_created")

func new_ice_candidate(mid_name, index_name, sdp_name):
	_log("Candidate")
	_log(sdp_name)
	$AcceptDialog.candidates.append(sdp_name)
	if automate:
		LocalServer.new_candidate(get_path(), mid_name, index_name, sdp_name)

func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		_log("Count:" + str(peer.get_available_packet_count()))
		_log(peer.get_packet().get_string_from_utf8())

func offer_created(type, offer):
	_log("Offer")
	_log(type)
	_log(offer)
	peer.set_local_description(type, offer)
	$AcceptDialog.offer = offer
	if automate:
		LocalServer.new_offer(get_path(), type, offer)

func _log(msg):
	$HBoxContainer/Logs/Local.text += "%s\n" % str(msg)

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
	peer.put_packet($HBoxContainer/Offer/Send/LineEdit.text.to_utf8())
	$HBoxContainer/Offer/Send/LineEdit.text = ""

func meesage_received(msg, d0="", d1="", d2="", d3="", d4=""):
	_log([msg, d0, d1, d2, d3, d4])

func _on_IceCandidate_pressed():
	var candidate = $HBoxContainer/Offer/IceCandidate/LineEdit.text
	peer.add_ice_candidate("data", 0, candidate)
	$HBoxContainer/Offer/IceCandidate/LineEdit.text = ""

func _on_Button_pressed():
	peer.create_offer()

func _on_Automate_toggled(button_pressed):
	automate = button_pressed