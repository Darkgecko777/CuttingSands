extends Control

const MAP_NODES_PATH := "res://data/world/map_nodes.json"
const MAP_SCENE := "res://scenes/map/map.tscn"
const CARAVAN_SPRITE := "res://Assets/sprites/prototype_caravan_icon.png"
const REF_SIZE := Vector2(1920, 1080)
const VIEW_SIZE := Vector2(1200, 800)
const MAX_WATCH := 30.0
const MIN_WATCH := 6.0
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.0
const ZOOM_DEFAULT := 1.5
const ZOOM_STEP := 0.1
const GOLD := Color(0.92, 0.78, 0.45, 1)
const MUTED := Color(0.75, 0.62, 0.42, 1)
const INK := Color(0.85, 0.78, 0.66, 1)
enum Mode { WAGON, MAP, WORD }
enum Yard { NONE, HOUSE, MARKET }

@onready var house_label: Label = %HouseLabel
@onready var place_label: Label = %PlaceLabel
@onready var status_label: Label = %StatusLabel
@onready var day_label: Label = %DayLabel
@onready var weather_pip: Label = %WeatherPip
@onready var gear_button: Button = %GearButton
@onready var rail: Control = %Rail
@onready var context_pane: Control = %ContextPane
@onready var wagon_rack: Control = %WagonRack
@onready var rack_grid: GridContainer = %RackGrid
@onready var map_clip: Control = %MapClip
@onready var map_layer: Control = %MapLayer
@onready var markers_layer: Control = %Markers
@onready var context_title: Label = %ContextTitle
@onready var context_meta: Label = %ContextMeta
@onready var context_body: Label = %ContextBody
@onready var context_actions: VBoxContainer = %ContextActions
@onready var market_box: VBoxContainer = %MarketBox

var _nodes: Dictionary = {}
var _mode: int = Mode.WAGON
var _yard: int = Yard.NONE
var _draft_buy: Dictionary = {}
var _draft_sell: Dictionary = {}
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _dragging := false
var _drag_last := Vector2.ZERO
var _cat_buttons: Dictionary = {}
var _paths: Dictionary = {}
var _max_path_len := 1.0
var _wagon: Sprite2D
var _hop_tween: Tween
var _zoom := ZOOM_DEFAULT
var _plate_size := REF_SIZE
var _res_scale := 1.0
var _content: Control
