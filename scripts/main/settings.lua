-- scripts/main/settings.lua

local settings = {
    GAME_VERSION = "0.1.3",
    GAME_NAME = "LuaGame",
    TILE_SIZE = 64,
    WORLD_WIDTH = 50,
    WORLD_HEIGHT = 50,
    PLAYER_SPEED = 400,
    DEBUG_TOGGLE_KEY = "f3",
    MOVE_UP_KEY = { "up", "w" },
    MOVE_DOWN_KEY = { "down", "s"},
    MOVE_LEFT_KEY = { "left", "a"},
    MOVE_RIGHT_KEY = { "right", "d"},
    MOVE_FAST_KEY = "lshift",
    PAUSE_TOGGLE_KEY = "escape",
    WINDOW_WIDTH = 1280,
    WINDOW_HEIGHT = 720,
    WINDOW_RESIZABLE = true,
    FULLSCREEN_TOGGLE_KEY = "f11",

    playerColors = {
        {1, 0, 0},
        {0, 0, 1},
        {0, 1, 0},
        {1, 1, 0},
        {1, 0, 1},
    },

    world = {
        width = 50,
        height = 50,
        tileSize = 64,
    },

    playerColor = {1, 0, 0},
}

return settings