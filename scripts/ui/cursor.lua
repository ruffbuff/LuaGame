local cursor = {
    image = love.graphics.newImage("assets/ui/cursor/Hand3.png"),
    x = 0,
    y = 0
}

function cursor.update()
    cursor.x, cursor.y = love.mouse.getPosition()
end

function cursor.draw()
    love.graphics.draw(cursor.image, cursor.x, cursor.y, 0, 1, 1, cursor.image:getWidth()/2, cursor.image:getHeight()/2)
end

return cursor