# res://button.gd
extends Control

# Pega referências aos nós que vamos usar. O '%' é um atalho para get_node.
@onready var red_button: Button = %RedButton
@onready var blue_button: Button = %BlueButton
@onready var home_button: Button = %HomeButton
@onready var log_label: Label = %LogLabel
@onready var log_scroll: ScrollContainer = %LogScroll

func _ready() -> void:
	# Limpa o log inicial
	log_label.text = ""
	_add_log_entry("Sistema iniciado. Aguardando comando...", false)
	
	# Conecta os sinais dos botões às suas respectivas funções
	red_button.pressed.connect(func(): _open_deep_link("/red"))
	blue_button.pressed.connect(func(): _open_deep_link("/blue"))
	home_button.pressed.connect(func(): _open_deep_link(""))

# Função centralizada para abrir qualquer deep link
func _open_deep_link(path: String) -> void:
	# Monta a URL com base no novo host e no caminho do botão
	var base_host = "gusoliveira21.eu5.org"
	var deep_link_url = "meuapp://%s%s" % [base_host, path]
	
	_add_log_entry("Executando: " + deep_link_url, false)
	
	var error_code = OS.shell_open(deep_link_url)
	
	if error_code == OK:
		_add_log_entry("SUCESSO: App respondeu.", false)
	else:
		_add_log_entry("ERRO: O app de destino não foi encontrado (Código: %s)" % error_code, true)

# Adiciona uma nova linha ao nosso "terminal" de feedback
func _add_log_entry(message: String, is_error: bool) -> void:
	var timestamp = Time.get_time_string_from_system()
	var color = "lime" if not is_error else "red"
	
	# Usa BBCode para formatar o texto com cores
	log_label.text += "[%s] [%s]%s[/color]\n" % [timestamp, color, message]
	
	# Força o scroll a ir para o final para mostrar a última mensagem
	await get_tree().process_frame
	log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value
