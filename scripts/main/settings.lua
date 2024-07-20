-- scripts/main/settings.lua

local settings = {
    GAME_VERSION = "0.1.16",
    GAME_NAME = "LuaGame",
    FONT_PATH = "fonts/bitByBit/bitbybit_ [Font].ttf",
    FONT_SIZE = 16,
    TILE_SIZE = 64,
    WORLD_WIDTH = 32,
    WORLD_HEIGHT = 32,
    PLAYER_SPEED = 200,
    PLAYER_SPRITE_SCALE = 2,
    DEBUG_TOGGLE_KEY = "f3",
    MOVE_UP_KEY = "w",
    MOVE_DOWN_KEY = "s",
    MOVE_LEFT_KEY = "a",
    MOVE_RIGHT_KEY = "d",
    MOVE_FAST_KEY = "lshift",
    DASH_KEY = "space",
    PAUSE_TOGGLE_KEY = "escape",
    WINDOW_WIDTH = 1280,
    WINDOW_HEIGHT = 720,
    WINDOW_RESIZABLE = true,
    FULLSCREEN_TOGGLE_KEY = "f11",
    GRAPPLING_HOOK_SHOOT_KEY = "e",
    GRAPPLING_HOOK_DETACH_KEY = "q",

    playerColors = {"red", "blue", "green", "yellow", "purple"},

    world = {
        width = 50,
        height = 50,
        tileSize = 64,
    },

    playerColor = "red",
}

return settings