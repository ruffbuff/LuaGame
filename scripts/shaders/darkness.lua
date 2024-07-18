-- scripts/shaders/darkness.lua

local darknessShader = love.graphics.newShader[[
    extern vec2 playerPos;
    extern float radius;
    extern vec2 screenSize;
    extern vec3 glowColor;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
    {
        vec2 aspectRatio = vec2(screenSize.x / screenSize.y, 1.0);
        vec2 relativePos = screen_coords / screenSize;
        vec2 playerRelativePos = playerPos / screenSize;
        float dist = distance(relativePos, playerRelativePos) * screenSize.y;
        float alpha = smoothstep(0.0, radius, dist);

        float glow = smoothstep(radius, 0.0, dist) * 0.5;
        vec3 finalColor = mix(glowColor, vec3(0.0), alpha);

        return vec4(finalColor, alpha * color.a);
    }
]]

return darknessShader