# res://button.gd
extends Control

@onready var red_button: Button = %RedButton
@onready var blue_button: Button = %BlueButton
@onready var home_button: Button = %HomeButton
@onready var success_button: Button = %SuccessButton # Adicionado
@onready var error_button: Button = %ErrorButton   # Adicionado
@onready var log_label: Label = %LogLabel
@onready var log_scroll: ScrollContainer = %LogScroll

var pending_requests = {}
var last_request_id: String = "" # Adicionado para guardar o último ID

func _ready() -> void:
	log_label.text = ""
	_add_log_entry("Sistema iniciado. Aguardando comando...", false)
	
	# Conecta os botões de requisição
	red_button.pressed.connect(func(): _send_request("/red"))
	blue_button.pressed.connect(func(): _send_request("/blue"))
	home_button.pressed.connect(func(): _send_request(""))
	
	# Adicionado: Conecta os botões de callback (resposta)
	success_button.pressed.connect(func():
		if not last_request_id.is_empty():
			_send_callback_to_flutter(last_request_id, true)
		else:
			_add_log_entry("AVISO: Nenhuma requisição foi enviada para simular uma resposta.", true)
	)
	error_button.pressed.connect(func():
		if not last_request_id.is_empty():
			_send_callback_to_flutter(last_request_id, false)
		else:
			_add_log_entry("AVISO: Nenhuma requisição foi enviada para simular uma resposta.", true)
	)

func _send_request(path: String) -> void:
	var base_host = "gusoliveira21.eu5.org"
	
	var request_id = "req_" + str(Time.get_unix_time_from_system())
	last_request_id = request_id # Adicionado: Guarda o ID da requisição atual
	
	var deep_link_url = "meuapp://%s%s?requestId=%s" % [base_host, path, request_id]
	
	_add_log_entry("Enviando requisição [%s]..." % request_id, false)
	pending_requests[request_id] = "Pendente"
	
	var error_code = OS.shell_open(deep_link_url)
	
	if error_code != OK:
		_add_log_entry("ERRO: O sistema operacional não conseguiu chamar a URL.", true)
		pending_requests.erase(request_id)

func _send_callback_to_flutter(request_id: String, was_successful: bool) -> void:
	var status = "success" if was_successful else "error"
	var message = "Operação concluída com sucesso." if was_successful else "Falha na operação simulada."

	var response_data = {
		"requestId": request_id,
		"status": status,
		"message": message
	}

	var json_string = JSON.stringify(response_data)
	DisplayServer.clipboard_set(json_string)
	OS.shell_open("meuapp://gusoliveira21.eu5.org")

	_add_log_entry("Callback enviado para o clipboard para requestId: " + request_id, false)

func _add_log_entry(message: String, is_error: bool) -> void:
	var timestamp = Time.get_time_string_from_system()
	var color = "lime" if not is_error else "red"
	
	log_label.text += "[%s] [%s]%s[/color]\n" % [timestamp, color, message]
	
	await get_tree().process_frame
	log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value
