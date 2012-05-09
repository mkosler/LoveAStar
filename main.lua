

-- This is a much more optimized version of my A* implementation into Lua.
-- It is also now completely detached from the geometry of a map, so any
-- arbitrarily built map will work, as long as you supply a few necessary
-- piece (which are explained in the intsructions.txt file). I tried to 
-- comment in the code as much as possible on areas what might need some
-- explanation, but if you need any more help, simply reply to the thread
-- located at 
--		http://love2d.org/forums/viewtopic.php?f=5&t=7174


-- CONTROLS FOR THE VISUAL DEMO:

-- MOUSE:
--		Left-click:			places the start node (green rectangle)
--		SHIFT+Left-click:	places a wall
--		Right-click:		places the end node (red rectangle)

-- KEYBOARD:
--		W:		toggles the drawing of the walls
--		TAB:	calls A* once
--		F2:		resets the program
--		P:		toggles the stress test
--		[:		Decreases the number of consecutive calls to A* during
--				the stress test (clamped at 1)
--		]:		Increases the number of consecutive calls to A* during
--				the stress test
--		ESC:	Quits the program		

require "flatten"
require "astar"

colors = {
	red = {255,0,0},
	green = {0,255,0},
	blue = {0,0,255},
	gray = {100,100,100},
	yellow = {255,255,0},
	black = {0,0,0},
	white = {255,255,255},
}

--- Builds the visual grid into a framebuffer
-- @param nsx:	number of columns
-- @param nsy:	number of rows
-- @param nw:	node width
-- @param nh:	node height
-- #returns fb:	framebuffer
local function buildVisualGrid(nsx, nsy, nw, nh)
	local fb = love.graphics.newCanvas()
	love.graphics.setCanvas(fb)
	love.graphics.setColor(colors.gray)
	for row = 0, nsx - 1 do
		for col = 0, nsy - 1 do
			love.graphics.rectangle(
				"line",
				row * nw,
				col * nh,
				nw,
				nh)
		end
	end
	love.graphics.setColor(colors.white)
	love.graphics.setCanvas()
	return fb
end

--- Builds a 2D table/array
-- @param nsx:	number of columns
-- @param nsy:	number of rows
-- #returns map:	2D table
local function buildMap(nsx, nsy)
	local map = {}
	for row = 1, nsx do
		map[row] = {}
		for col = 1, nsy do
			map[row][col] = {}
		end
	end
	return map
end

function love.load()
	MAPWIDTH = love.graphics.getWidth()
	MAPHEIGHT = love.graphics.getHeight()
	NUMBERCOLS = 25
	NUMBERROWS = 25
	NODEWIDTH = MAPWIDTH / NUMBERCOLS
	NODEHEIGHT = MAPHEIGHT / NUMBERROWS
	SCALE = 10 / math.min(NUMBERCOLS, NUMBERROWS)
	gridFb = buildVisualGrid(NUMBERCOLS, NUMBERROWS, NODEWIDTH, NODEHEIGHT)
	wallMap = buildMap(NUMBERCOLS, NUMBERROWS)
	pathMap = {}
	currentPath = {}
	startGridPos = {r = -1, c = -1}
	exitGridPos = {r = -1, c = -1}
	timeToggle = false
	pathTrigger = false
	tabTrigger = false
	wallToggle = true
	mouseFreeze = false
	calls = 1
	callsMax = 10
end

--- Clamps a value between to bounds
-- @param a:	value to be clamped
-- @param l:	lower bound
-- @param u:	upper bound
-- #returns integer:	the clamped value
local function clamp(a, l, u)
	return math.min(math.max(a, l), u)
end

function love.update(dt)
	calls = clamp(calls, 1, callsMax)
	if timeToggle then
		for i = 1, calls do
			if not mouseFreeze then
				pathMap = flattenMap(wallMap, exitGridPos, pathMap)
			end
			currentPath = startPathing(
				pathMap,
				((startGridPos.r - 1) * NUMBERROWS) + startGridPos.c,
				((exitGridPos.r - 1) * NUMBERROWS) + exitGridPos.c)
		end
		if next(currentPath) ~= nil then
			pathTrigger = true
		else
			pathTrigger = false
		end
	end
end

--- Draws the visual walls
-- @param map:	the 2D table holds the map values
local function drawWalls(map)
	love.graphics.setColor(colors.blue)
	for row = 1, #map do
		for col = 1, #map[row] do
			if map[row][col].wall then
				love.graphics.rectangle(
					"fill",
					(col - 1) * NODEWIDTH,
					(row - 1) * NODEHEIGHT,
					NODEWIDTH,
					NODEHEIGHT)
			end
		end
	end
end

--- Converts from matrix coordinates into Cartesian coordinates
-- @param row:	row
-- @param col:	column
-- @param nw:	node width
-- @param nh:	node height
-- #returns x, y:	the Cartesian coordinates
local function findWorldPosition(row, col, nw, nh)
	local x = (col - 1) * nw
	local y = (row - 1) * nh
	return x, y
end

--- Draws the found path
-- @param path: the path to draw
local function drawPath(path)
	love.graphics.setLineWidth(10 * SCALE)
	local colorStep = 255 / #path
	for i = 1, #path - 1 do
		local x1, y1 = findWorldPosition(path[i].row, path[i].col, NODEWIDTH, NODEHEIGHT)
		local x2, y2 = findWorldPosition(path[i + 1].row, path[i + 1].col, NODEWIDTH, NODEHEIGHT)
		love.graphics.setColor(colors.yellow)
		love.graphics.line(
			x1 + (NODEWIDTH / 2),
			y1 + (NODEHEIGHT / 2),
			x2 + (NODEWIDTH / 2),
			y2 + (NODEHEIGHT / 2))
		love.graphics.setColor(
			255 - (colorStep * (i - 1)),
			0 + (colorStep * (i - 1)),
			0)
		love.graphics.circle(
			"fill",
			x1 + (NODEWIDTH / 2),
			y1 + (NODEHEIGHT / 2),
			5 * SCALE)
	end
	love.graphics.setColor(0,255,0)
	local sx, sy = findWorldPosition(path[#path].row, path[#path].col, NODEWIDTH, NODEHEIGHT)
	love.graphics.circle(
		"fill",
		sx + (NODEWIDTH / 2),
		sy + (NODEHEIGHT / 2),
		5 * SCALE)
	love.graphics.setLineWidth(1)
end

function love.draw()
	love.graphics.draw(gridFb, 0, 0)
	if startGridPos.c ~= -1 then
		love.graphics.setColor(colors.green)
		love.graphics.rectangle(
			"fill",
			(startGridPos.c - 1) * NODEWIDTH,
			(startGridPos.r - 1) * NODEHEIGHT,
			NODEWIDTH,
			NODEHEIGHT)
	end
	if exitGridPos.c ~= -1 then
		love.graphics.setColor(colors.red)
		love.graphics.rectangle(
			"fill",
			(exitGridPos.c - 1) * NODEWIDTH,
			(exitGridPos.r - 1) * NODEHEIGHT,
			NODEWIDTH,
			NODEHEIGHT)	
	end
	if pathTrigger then
		drawPath(currentPath)
	end
	if wallToggle then
		drawWalls(wallMap)
	end
	love.graphics.setColor(colors.white)
	love.graphics.print(string.format("Number of calls: %d", calls), 0, 0)
	if timeToggle then
		love.graphics.print("=========FPS=========", 0, 15)
		love.graphics.print(string.format("FPS: %f | dt: %f", love.timer.getFPS(), love.timer.getDelta()), 0, 30)
		love.graphics.print(string.format("Time span of A*: %f", aStarEnd - aStarStart), 0, 60)
		love.graphics.print(string.format("Main loop: %f", mainLoopEnd - mainLoopStart), 10, 75)
		love.graphics.print(string.format("Find next: %f", findNextEnd - findNextStart), 10, 90)
		love.graphics.print(string.format("Neighbor check: %f", neighborEnd - neighborStart), 10, 105)
		love.graphics.print(string.format("Build path: %f", buildPathEnd - buildPathStart), 10, 120)
		love.graphics.print(string.format("Clean up: %f", cleanUpEnd - cleanUpStart), 10, 135)
	end
	if mouseFreeze then
		love.graphics.print("### Flatten currently being skipped ###", 0, 45)
		love.graphics.print("##### MOUSE FROZEN #####", 0, 150)
	else
		if flattenEnd ~= nil then
			love.graphics.print(string.format("Time span of flatten: %f", (flattenEnd - flattenStart)), 0, 45)
		end
	end
end

--- 1D containment
-- @param a:	value to check
-- @param l:	lower bound
-- @param u:	upper bound
-- #returns integer:	negative if a is below l,
--						postive if a is above u,
--						zero if in between
local function within(a, l, u)
	if a < l then return -1
	elseif a > u then return 1
	else return 0 end
end

--- 2D containment
-- @param x:	x-coordinate
-- @param y:	y-coordinate
-- @param rect:	rectangular bound
-- #returns boolean
local function contains(x, y, rect)
	if 	within(x, rect.x, rect.x + rect.w) == 0 and
		within(y, rect.y, rect.y + rect.h) == 0 then
		return true
	end return false
end


--- Converts from Cartesian coordinates to matrix coordinates
-- @param x:	x-coordinate
-- @param y:	y-coordinate
-- @param map:	matrix to check against
-- @param nw:	node width
-- @param nh:	node height
-- #returns row, col: matrix coordinates
function findGridPosition(x, y, map, nw, nh)
	for row = 1, #map do
		for col = 1, #map[row] do
			local rect = {}
			rect.x = (col - 1) * nw
			rect.y = (row - 1) * nh
			rect.w = nw
			rect.h = nh
			if contains(x, y, rect) then
				return row, col
			end
		end
	end
	return -1, -1
end

function love.mousepressed(x,y,b)
	if mouseFreeze then return end
	local gr, gc = findGridPosition(x, y, wallMap, NODEWIDTH, NODEHEIGHT)
	if gr ~= -1 then
		if love.keyboard.isDown("rshift", "lshift") then
			if b == "l" then
				if 	not (gc == startGridPos.c and gr == startGridPos.r) and
					not (gc == exitGridPos.c and gr == exitGridPos.r) then
					if wallMap[gr][gc].wall then
						wallMap[gr][gc].wall = false
					else
						wallMap[gr][gc].wall = true
					end
				end
			end
		else
			if not wallMap[gr][gc].wall then
				if 	b == "l" and 
					not (gc == exitGridPos.c and gr == exitGridPos.r) then
					startGridPos.c = gc
					startGridPos.r = gr
				elseif 	b == "r" and
						not (gc == startGridPos.c and gr == startGridPos.r) then
					exitGridPos.c = gc
					exitGridPos.r = gr
				end
			end
		end
	end
end

function love.keypressed(k)
	if k == "escape" then
		love.event.quit();
	end
	if k == "p" then
		if timeToggle then
			timeToggle = false
		else
			timeToggle = true
		end
	end
	if k == "w" then
		if wallToggle then
			wallToggle = false
		else
			wallToggle = true
		end
	end
	if k == "tab" then
		if startGridPos.r == -1 or exitGridPos.r == -1 then 
			return 
		end
			tabTrigger = true
			pathMap = flattenMap(wallMap, exitGridPos, pathMap)
		currentPath = startPathing(
			pathMap,
			((startGridPos.r - 1) * NUMBERROWS) + startGridPos.c,
			((exitGridPos.r - 1) * NUMBERROWS) + exitGridPos.c)
		if next(currentPath) ~= nil then
			pathTrigger = true
		else
			pathTrigger = false
		end
	end
	if k == "f2" then
		love.load()
	end
	if k == "[" then
		calls = calls - 1
	end
	if k == "]" then
		calls = calls + 1
	end
	if k == "m" then
		if mouseFreeze then
			callsMax = 10
			mouseFreeze = false
		else
			callsMax = 100
			mouseFreeze = true
		end
	end
end
