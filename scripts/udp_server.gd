extends Node

# Emits signal when received data
signal landmarks_received(data)

# Paths to Python interpreter and script
var python_interpreter: String = ProjectSettings.globalize_path("res://PythonFiles/venv/python.exe")
var python_script: String = ProjectSettings.globalize_path("res://PythonFiles/script.py")

# UDP Server instance
var server: UDPServer = UDPServer.new()
var server_port: int = 4242

# Process ID for the Python server (used to stop it later)
var server_proc_id: int = -1

func _ready() -> void:
	# Start the Python UDP server
	start_server()
	
	# Initialize and start the UDP server in Godot
	server.listen(server_port)

func start_server() -> void:
	# Start the Python script and store process ID
	server_proc_id = OS.create_process(python_interpreter, [python_script])
	if server_proc_id != -1:
		print("Python server started successfully")
		
	assert(server_proc_id != -1, "Failed to start Python server!")

func _process(_delta: float) -> void:
	server.poll()
	
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var received_data = packet.get_string_from_utf8()
		
		# Parse the received JSON data
		var parsed_json = JSON.parse_string(received_data)
		if parsed_json != null and parsed_json.has("hands"):
			landmarks_received.emit(parsed_json)
		else:
			print("Invalid JSON data received")


func stop_server() -> void:
	# Stop listening on the UDP server
	if server.is_listening():
		server.stop()
		print("UDP server stopped!")
	
	# Stop the Python server if it's running
	if server_proc_id > 0:
		# Ensure the process is still running before killing
		if OS.is_process_running(server_proc_id):
			print("Process ID running and found!")
			var success = OS.kill(server_proc_id)
			if success:
				print("Python server (PID %d) stopped successfully." % server_proc_id)
				server_proc_id = -1
			else:
				print("Error: Failed to stop Python server.")
		else:
			print("Python server was already stopped.")
	else:
		print("No active Python server process to stop.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		stop_server()
