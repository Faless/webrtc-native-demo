extends Node

var peers = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func register(path):
	peers.append(path)

func deregister(path):
	peers.erase(path)

func new_candidate(path, media, index, sdp):
	prints("From:", path)
	for p in peers:
		if p != path:
			print("Candidate")
			prints("To:", p)
			get_node(p).peer.add_ice_candidate(media, index, sdp)

func new_offer(path, type, sdp):
	prints("From:", path)
	for p in peers:
		if p != path:
			print(type, sdp)
			prints("To:", p)
			get_node(p).peer.set_remote_description(type, sdp)
		#else:
		#	get_node(path).set_local_description(sdp, isOffer)