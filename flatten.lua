

-- This is an example flatten map function used for the visual demo
-- of my A* search in Lua. It flattens a 2D, square-tiled map into
-- the 1D pathMap that is used for my A* search. For the requirements
-- needed for building your own, please see the instructions.txt file
-- packaged with this demo, or you can download another copy @
--			INSERT URL

require "astar"

--- Find the neighbor nodes of a square map
-- @param wallMap:	the visual map
-- @param row:		the row of the current temp node
-- @param col:		the column of the current temp node
-- #returns tables:	pointers to the neighbor nodes, along with the
--					"distance" between each node (hardcoded for squares as
--					10 steps orthogonal and 14 steps diagonal)
local function findNeighbors(wallMap, row, col)
	local skipList = {}
	local rmin = -1
	local rmax = 1
	local cmin = -1
	local cmax = 1
	-- This trims the search area if the current temp node is located
	-- on the boundary of a square map (will only work if correctly if
	-- all of the rows and columns are of the same length)
	if row == 1 then
		rmin = 0
	elseif row == #wallMap then
		rmax = 0
	end
	if col == 1 then
		cmin = 0
	elseif col == #wallMap[row] then
		cmax = 0
	end
	local neighbors = {}
	local distance = {}
	for i = rmin, rmax do
		for j = cmin, cmax do
			-- As long as a neighbor isn't a wall (or itself)
			if 	not wallMap[row + i][col + j].wall and
				not (i == 0 and j == 0) then
				-- Calculate the length by summing the lengths of each coordinate.
				-- A sum of 2 means that both coordinates have a length of 1
				local len = math.abs(i) + math.abs(j)
				if len == 2 then
					table.insert(distance, 14)
				elseif len == 1 then
					table.insert(distance, 10)
				end
				table.insert(neighbors, (((row - 1) + i) * #wallMap) + (col + j))
			end
		end
	end
	return neighbors, distance
end

--- Flattens a square map to a 1D array to be used in A*. The only pieces
--- that are required for A* are:

---		+ the location of itself inside the pathMap
---		+ the heuristic score used for your map
---		+ the neighbors of the node
---		+ the distance to each of those neighbors (the gScore)

--- Anything else you wish to store would only be required for understanding
--- the path relative to the original formation of your map. In this demo,
--- It is a simple square grid, so I also stored its matrix coordinates for
--- easier access to that information during the unpacking of the path.

--- This demo flattenMap is by no means optimized. Whenever it is called,
--- it rebuilds the entire pathMap, as opposed to simply updating any
--- changed nodes. Optimizing the flattenMap function is something
--- that should be done for each individual, as you will know how your
--- map is designed better than I every would.

-- @param wallMap:	the map to flatten
-- @param exitPos:	the matrix coordinate of the exit node's position
--					(for heuristic calculations)
-- @param pathMap:	the (existing) path map to change
-- #returns pathMap:	the built path map
function flattenMap(wallMap, exitPos, pathMap)
	flattenStart = love.timer.getTime()
	-- If a pathMap wasn't given, make one
	local pathMap = pathMap or {}
	for row = 1, #wallMap do
		for col = 1, #wallMap[row] do
			if not wallMap[row][col].wall then
				local pathLoc = ((row - 1) * #wallMap) + col
				-- My hScore is built using taxicab geometry. Sum the
				-- vertical and horizontal distances, and multiply that
				-- by 10.
				local hScore = (math.abs(row - exitPos.r) + math.abs(col - exitPos.c)) * 10
				local neighbors, distance = findNeighbors(wallMap, row, col)
				local tempNode = newNode(pathLoc, hScore, neighbors, distance)
				tempNode.row = row
				tempNode.col = col
				pathMap[pathLoc] = tempNode
			end
		end
	end
	flattenEnd = love.timer.getTime()
	return pathMap
end
