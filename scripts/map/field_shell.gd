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
