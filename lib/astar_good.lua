

-- This is a lifted implementation of A* search, written in Lua. This
-- version has a few variables designed for stress testing, so THIS
-- VERSION SHOULD NOT BE USED OUTSIDE OF THIS DEMO. Please use the
-- version included in the lib directory of the .zip file, or
-- download another copy @:
--			INSERT URL

binary_heap = require "binary_heap"

--- Toggle off the pathMap toggles to set up for the next call
-- @param pathMap:		the flattened path map
-- @param openSet:		the open set
-- @param closedSet:	the closed set
local function cleanPathMap(pathMap, openSet, closedSet)
	cleanUpStart = love.timer.getTime()	--			<== FOR STRESS TEST
	for _,v in pairs(openSet) do
		if type(v) == "table" then
			pathMap[v.value.pathLoc].open = false
		end
	end
	for _,v in pairs(closedSet) do
		pathMap[v.pathLoc].closed = false
	end
	cleanUpEnd = love.timer.getTime()	--			<== FOR STRESS TEST
end

--- Constructs the found path. This works in reverse from the 
--- pathfinding algorithm, by using parent values and the associated
--- location of that parent on the closed set to jump around until it
--- returns to the start node's position.
-- @param closedSet:	the closed set
-- @param startPos:		the position of the start node
-- #returns path:	the found path
local function buildPath(closedSet, startPos)
	buildPathStart = love.timer.getTime()	--		<== FOR STRESS TEST
	local path = {closedSet[#closedSet]}
	while path[#path].pathLoc ~= startPos do
		table.insert(path, closedSet[path[#path].pCloseLoc])
	end
	buildPathEnd = love.timer.getTime()	--			<== FOR STRESS TEST
	aStarEnd = love.timer.getTime()	--				<== FOR STRESS TEST
	return path
end

--- The A* search algorithm. Using imported heuristics and distance values
--- between individual nodes, this finds the shortest path from the start
--- node's position to the exit node's position.
-- @param pathMap:	the flattened path map
-- @param startPos:	the start node's position, relative to the pathMap
-- @param exitPos:	the exit node's position, relative to the pathMap
-- #returns path:	the found path (or empty if it failed to find a path)
function startPathing(pathMap, startPos, exitPos)
	aStarStart = love.timer.getTime()	-- 			<== FOR STRESS TEST
	pathMap[startPos].parent = pathMap[startPos]
	-- Initialize the gScore and fScore of the start node
	pathMap[startPos].gScore = 0
	pathMap[startPos].fScore =
		pathMap[startPos].gScore + pathMap[startPos].hScore
	-- Toggle the open trigger on pathMap for the start node
	pathMap[startPos].open = true
	-- Initialize the openSet and add the start node to it
	local openSet = binary_heap:new()
	openSet:insert(pathMap[startPos].fScore, pathMap[startPos])
	-- Initialize the closedSet and the testNode
	local closedSet = {}
	local testNode = {}
	
	mainLoopStart = love.timer.getTime()	--		<== FOR STRESS TEST
	
	-- The main loop for the algorithm. Will continue to check as long as
	-- there are open nodes that haven't been checked.
	while #openSet > 0 do
		-- Find the next node with the best fScore
		findNextStart = love.timer.getTime()	--		<== FOR STRESS TEST
		_, testNode = openSet:pop()
		findNextEnd = love.timer.getTime()	--			<== FOR STRESS TEST
		pathMap[testNode.pathLoc].open = false
		-- Add that node to the closed set
		pathMap[testNode.pathLoc].closed = true
		table.insert(closedSet, testNode)
		-- Check to see if that is the exit node's position
		if closedSet[#closedSet].pathLoc == exitPos then
			mainLoopEnd = love.timer.getTime()	--	<== FOR STRESS TEST
			-- Clean the path map
			cleanPathMap(pathMap, openSet, closedSet)
			-- Return the build path
			return buildPath(closedSet, startPos)
		end
		neighborStart = love.timer.getTime()	--	<== FOR STRESS TEST
		
		-- Check all the (pre-assigned) neighbors. If they are not closed 
		-- already, then check to see if they are either not on the open
		-- or if they are on the open list, but their currently assigned
		-- distance score (either given to them when they were first added
		-- or reassigned earlier) is greater than the distance score that
		-- goes through the current test node. If either is true, then
		-- calculate their fScore and assign the current test node as their
		-- parent
		for k,v in pairs(testNode.neighbors) do
			if not pathMap[v].closed then
				local tempGScore = testNode.gScore + testNode.distance[k]
				if not pathMap[v].open then
					pathMap[v].open = true
					pathMap[v].parent = testNode
					pathMap[v].pCloseLoc = #closedSet
					pathMap[v].gScore = tempGScore
					pathMap[v].fScore = 
						pathMap[v].hScore + tempGScore
					openSet:insert(pathMap[v].fScore, pathMap[v])
				elseif tempGScore < pathMap[v].gScore then
					pathMap[v].parent = testNode
					pathMap[v].gScore = tempGScore
					pathMap[v].fScore = 
						pathMap[v].hScore + tempGScore
				end
			end
		end
		neighborEnd = love.timer.getTime()	--		<== For STRESS TEST
	end
	-- Returns an empty table if it failed to find any path to the exit node
	return {}
end

--======================================================================
-- Helper functions for easier plug-in to other games
--======================================================================

function newNode(pathLoc, hScore, neighbors, distance)
	assert(type(pathLoc) == "number", "bad arg #1: needs number")
	assert(type(hScore) == "number", "bad arg #1: needs number")
	assert(type(neighbors) == "table" and 
		type(next(neighbors)) == "number", "bad arg #1: needs table")
	assert(type(distance) == "table" and
		type(next(distance)) == "number", "bad arg #1: needs number")
	local n = {
		pathLoc = pathLoc,
		hScore = hScore,
		neighbors = neighbors,
		distance = distance,
	}
	return n
end































