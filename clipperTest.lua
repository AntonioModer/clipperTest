--[[
version 0.0.3
HELP:
	+ https://love2d.org/forums/viewtopic.php?f=5&t=81229
TODO:
	- тестирование
	+BUG1 почему исчезает половинка, если делить с права на лево? (смотри скриншет бага)
		+ потому что существует разница между нижней границей вернего полигона и верхней границей нижнего полигона, т.е. их AABB формы не пересекаются
	+BUG2 если obstacle ниже cell, то нулевой результат
--]]

local thisModule = {}

------------------------- cell
do
	thisModule.cell = {}
	thisModule.cell.polygons = {}
	thisModule.cell.polygons[1] = {
		200, 110,
		600, 110,
		600, 510,
		200, 510
	}
	thisModule.cell.clipperPolygons = {}
end

-------------------------- obstacle
do
	thisModule.obstacle = {}
	thisModule.obstacle.polygons = {}
	thisModule.obstacle.polygons[1] = {
		150, 150,
		250, 150,
		250, 250,
		150, 250
	}
	thisModule.obstacle.clipperPolygons = {}
end

-------------------------- result
do
	thisModule.result = {}
	thisModule.result.polygons = {}
	function thisModule:refreshResultFromClipperResult()
		thisModule.result.polygons = {}
		for polyN=1, thisModule.clipper.result:size() do
			local clipperPolygon = thisModule.clipper.result:get(polyN)
			thisModule.result.polygons[polyN] = {}
			for pointN=1, clipperPolygon:size() do
				table.insert(thisModule.result.polygons[polyN], tonumber(clipperPolygon:get(pointN).x))
				table.insert(thisModule.result.polygons[polyN], tonumber(clipperPolygon:get(pointN).y))
			end		
		end	
	end
end

-------------------------- clipper
thisModule.clipper = require("clipper.clipper")

table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(thisModule.cell.polygons[1]))
table.insert(thisModule.obstacle.clipperPolygons, thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1]))

thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
thisModule:refreshResultFromClipperResult()

function thisModule:update(dt)
	
	----------------------------------------------------------------------------------------- update obstacle
	-------------------------- двигаем obstacle
	local x, y = love.mouse.getPosition()
	thisModule.obstacle.polygons[1] = {
		x, y,
		x+50, y,
		x+50, y+50,
		x, y+50
	}
	thisModule.obstacle.polygons[2] = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}	
	--------------------------- clipper
	if true then
	--	thisModule.obstacle.clipperPolygon:clean()															-- работает не так как я ожидал
		if #thisModule.cell.clipperPolygons > 0 then
			thisModule.obstacle.clipperPolygons[1] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1])
			thisModule.obstacle.clipperPolygons[2] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[2])
			thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
			
--			thisModule.clipper.result = thisModule.clipper.result:clean()
			thisModule.clipper.result = thisModule.clipper.result:simplify()
			
			thisModule:refreshResultFromClipperResult()
		end
		
		-- fix bug3 (see image)
		if true then
			local needFixError = false
			for i, polygon in ipairs(thisModule.result.polygons) do
				local triangles
				local ok, out = pcall(love.math.triangulate, polygon)
				if not ok then
					-- cant draw(triangulate) result.polygons
					needFixError = true
					break
				end
			end
			if needFixError then
--				print('fixError')
				x, y = x+1, y+1
				thisModule.obstacle.polygons[1] = {
					x, y,
					x+50, y,
					x+50, y+50,
					x, y+50
				}
				thisModule.obstacle.polygons[2] = {
					0, 0,
					1, 0,
					1, 1,
					0, 1
				}
				if #thisModule.cell.clipperPolygons > 0 then
					thisModule.obstacle.clipperPolygons[1] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1])
					thisModule.obstacle.clipperPolygons[2] = thisModule.clipper:newPolygon(thisModule.obstacle.polygons[2])
					thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
					
		--			thisModule.clipper.result = thisModule.clipper.result:clean()
					thisModule.clipper.result = thisModule.clipper.result:simplify()
					
					thisModule:refreshResultFromClipperResult()
				end				
			end
		end
	end
	
end

function thisModule:mousePressed(x, y, button)
	if button == 'l' then
		-- при нажатии на кнопку мыши запоминаем вырезаную cell, и уже вырезаем в ней в дальнейшем
		thisModule.cell.polygons = thisModule.result.polygons
		do
			thisModule.cell.clipperPolygons = {}
			for i, polygon in ipairs(thisModule.cell.polygons) do
				table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(polygon))
			end
--			print(#thisModule.cell.polygons)
		end
	end	
end

function thisModule:draw()
	
	-- cell.polygons
	if true then
		love.graphics.setColor(0, 255, 0, 255)
		for i, polygon in ipairs(thisModule.cell.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				for i, triangle in ipairs(triangles) do
					love.graphics.polygon("fill", triangle)
				end					
			else
				love.graphics.print('cant draw(triangulate) cell.polygons', 0, 0, 0, 1, 1)
			end
		end
	end	

	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle('rough')
	love.graphics.setLineJoin('none')
	------------------------------------------------------ thisModule.result.polygons
	if true then
		for i, polygon in ipairs(thisModule.result.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				love.graphics.setColor(0, 0, 255, 255)
				for i1, triangle in ipairs(triangles) do
					love.graphics.polygon('line', triangle)
				end
				
				love.graphics.setColor(255, 0, 0, 255)
				love.graphics.print(i, polygon[1], polygon[2], 0, 1.5, 1.5)
			else
				love.graphics.setColor(0, 0, 255, 255)
				love.graphics.print('cant draw(triangulate) result.polygons', 0, 20, 0, 1, 1)
			end
		end
	end
	love.graphics.setLineStyle('smooth')
	love.graphics.setLineWidth(1)
	
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.polygon('fill', thisModule.obstacle.polygons[1])
	
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.print('#cell.polygons = '..#thisModule.cell.polygons, 0, 40, 0, 1, 1)
	love.graphics.setColor(0, 0, 255, 255)
	love.graphics.print('clipper.result:size() = '..thisModule.clipper.result:size(), 0, 60, 0, 1, 1)
end

return thisModule