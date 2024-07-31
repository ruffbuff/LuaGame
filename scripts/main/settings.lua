-- scripts/main/settings.lua

local settings = {
    GAME_VERSION = "0.1.19",
    GAME_NAME = "FKingPets",
    FONT_PATH = "fonts/bitByBit/bitbybit_ [Font].ttf",
    FONT_SIZE = 16,
    WORLD_WIDTH = 60,
    WORLD_HEIGHT = 35,
    TILE_SIZE = 64,
    PLAYER_SIZE = 48,
    PLAYER_SPEED = 250,
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
    MOVEMENT_TYPE = "wasd", -- Может быть "wasd", "arrows" или "mouse"

    playerColors = {
        red = {1, 0, 0},
        blue = {0, 0, 1}
    },
    
    playerColorOrder = {"red", "blue"},

    world = {
        width = 50,
        height = 50,
        tileSize = 64,
    },

    MAP = {
        SPAWN_POINTS = {
            {x = 3, y = 18},  -- Левая команда
            {x = 58, y = 18}  -- Правая команда
        },
        MAIN_BUILDINGS = {
            {x = 6, y = 18},  -- Левая команда
            {x = 55, y = 18}  -- Правая команда
        },
        TOWER_POINTS = {
            -- Левая команда
            {x = 9, y = 18},   -- Башня возле базы
            {x = 13, y = 5},   -- Верхняя башня
            {x = 13, y = 31},  -- Нижняя башня
            {x = 22, y = 5},   -- Дополнительная верхняя башня
            {x = 22, y = 31},  -- Дополнительная нижняя башня
            -- Правая команда
            {x = 52, y = 18},  -- Башня возле базы
            {x = 48, y = 5},   -- Верхняя башня
            {x = 48, y = 31},  -- Нижняя башня
            {x = 39, y = 5},   -- Дополнительная верхняя башня
            {x = 39, y = 31}   -- Дополнительная нижняя башня
        },
        JUNGLE_POINTS = {
            {x = 8, y = 18},   -- Левая джунгля
            {x = 53, y = 18}   -- Правая джунгля
        },
        WALLS = {
            -- Внешние стены
            {x = 1, y = 1, width = 60, height = 1},   -- Верхняя
            {x = 1, y = 35, width = 60, height = 1},  -- Нижняя
            {x = 1, y = 1, width = 1, height = 35},   -- Левая
            {x = 60, y = 1, width = 1, height = 35},  -- Правая
            
            -- Центральные стены с проходами
            {x = 12, y = 9, width = 8, height = 1},   -- Верхняя левая
            {x = 23, y = 9, width = 15, height = 1},  -- Верхняя центральная
            {x = 41, y = 9, width = 8, height = 1},   -- Верхняя правая
            
            {x = 12, y = 25, width = 8, height = 1},  -- Нижняя левая
            {x = 23, y = 25, width = 15, height = 1}, -- Нижняя центральная
            {x = 41, y = 25, width = 8, height = 1},  -- Нижняя правая
            
            {x = 12, y = 10, width = 1, height = 15}, -- Левая вертикальная
            {x = 48, y = 10, width = 1, height = 15}, -- Правая вертикальная
        
            -- Дополнительные стены для формирования углов
            {x = 12, y = 9, width = 1, height = 1},   -- Верхний левый угол
            {x = 48, y = 9, width = 1, height = 1},   -- Верхний правый угол
            {x = 12, y = 25, width = 1, height = 1},  -- Нижний левый угол
            {x = 48, y = 25, width = 1, height = 1},  -- Нижний правый угол
        }
    }
}

return settings