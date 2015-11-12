function love.load()
	require("clipperTest")
end

function love.mousepressed(x, y, button)
	require("clipperTest"):mousePressed(x, y, button)
end

function love.update(dt)
	require("clipperTest"):update(dt)
end

function love.draw()
	require("clipperTest"):draw()
end