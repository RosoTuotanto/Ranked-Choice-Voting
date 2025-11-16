-- Ranked-Choice Voting Calculator for Solar2D
display.setStatusBar( display.HiddenStatusBar )

-- Set the filename up here.
local csvFile = "votes.csv"

-- Run tests:
-- local csvFile = "testFiles/test1.csv"

----------------------------------------------------------------------

local function parseCSV(filename)
	local path = system.pathForFile(filename, system.ResourceDirectory)

	if not path then
		print( "ERROR: \"" .. filename .. "\" does not exist." )
		return false
	end

	local file = io.open(path, "r")

	if not file then
		print("ERROR: Could not open " .. filename)
		return false
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	return lines
end


local function splitCSV(line)
	local fields = {}
	local field = ""
	local inQuotes = false

	for i = 1, #line do
		local char = line:sub(i, i)

		if char == '"' then
			inQuotes = not inQuotes
		elseif char == ',' and not inQuotes then
			table.insert(fields, field)
			field = ""
		else
			field = field .. char
		end
	end

	table.insert(fields, field)
	return fields
end

-- Extract game name from the file header.
local function extractGameName(header)
	-- Extract text between brackets, e.g., [Peli-idea #1] -> Peli-idea #1
	local name = header:match("%[(.-)%]")
	if name then
		return name
	end
	return header
end

-- Calculate ranked-choice voting.
local function calculateRCV(ballots, candidates)
	local eliminated = {}
	local round = 1
	local totalVoters = #ballots

	print("\n=== RANKED-CHOICE VOTING ===")
	print("Total voters: " .. totalVoters)
	print("Candidates: " .. #candidates)

	while true do
		print("\n--- Round " .. round .. " ---")

		-- Count votes for each candidate
		local counts = {}
		for i = 1, #candidates do
			counts[i] = 0
		end

		-- For each ballot, find the first non-eliminated choice
		for _, ballot in ipairs(ballots) do
			for rank = 1, #candidates do
				for candidateIdx, choice in ipairs(ballot) do
					if choice == rank and not eliminated[candidateIdx] then
						counts[candidateIdx] = counts[candidateIdx] + 1
						break
					end
				end
				-- Check if we found a valid vote
				local foundVote = false
				for candidateIdx, choice in ipairs(ballot) do
					if choice == rank and not eliminated[candidateIdx] then
						foundVote = true
						break
					end
				end
				if foundVote then break end
			end
		end

		-- Display current counts
		for i = 1, #candidates do
			if not eliminated[i] then
				local percentage = (counts[i] / totalVoters) * 100
				print(string.format("%s: %d votes (%.1f%%)", candidates[i], counts[i], percentage))
			end
		end

		-- Check for majority winner (>50%)
		local maxVotes = 0
		local winnerIdx = nil
		for i = 1, #candidates do
			if not eliminated[i] and counts[i] > maxVotes then
				maxVotes = counts[i]
				winnerIdx = i
			end
		end

		if maxVotes > totalVoters / 2 then
			local percentage = (maxVotes / totalVoters) * 100
			print("\n=== WINNER ===")
			print(string.format("%s with %d votes (%.1f%%)", candidates[winnerIdx], maxVotes, percentage))
			return candidates[winnerIdx], percentage, maxVotes, false
		end

		-- Find candidate with fewest votes to eliminate
		local minVotes = totalVoters + 1
		local eliminateIdx = nil
		for i = 1, #candidates do
			if not eliminated[i] and counts[i] < minVotes then
				minVotes = counts[i]
				eliminateIdx = i
			end
		end

		-- Check if only one candidate left
		local remainingCount = 0
		local remainingIndices = {}
		for i = 1, #candidates do
			if not eliminated[i] then
				remainingCount = remainingCount + 1
				table.insert(remainingIndices, i)
			end
		end

		if remainingCount == 1 then
			-- Last candidate wins by default
			local percentage = (maxVotes / totalVoters) * 100
			print("\n=== WINNER (Last Remaining) ===")
			print(string.format("%s with %d votes (%.1f%%)", candidates[winnerIdx], maxVotes, percentage))
			return candidates[winnerIdx], percentage, maxVotes, false
		end

		-- Check for tie between last two candidates
		if remainingCount == 2 then
			local idx1, idx2 = remainingIndices[1], remainingIndices[2]
			if counts[idx1] == counts[idx2] then
				local percentage = (counts[idx1] / totalVoters) * 100
				print("\n=== TIE ===")
				print(string.format("%s and %s tied with %d votes each (%.1f%%)",
					candidates[idx1], candidates[idx2], counts[idx1], percentage))
				return candidates[idx1] .. "\n&\n" .. candidates[idx2], percentage, counts[idx1], true
			end
		end

		eliminated[eliminateIdx] = true
		print("Eliminated: " .. candidates[eliminateIdx])

		round = round + 1
	end
end


local function showResults(winner, percentage, votes, isTie)
	-- Display result on screen
	display.setDefault("background", 0.2, 0.2, 0.3)

	local titleText = display.newText({
		text = isTie and "RANKED-CHOICE VOTING TIE" or "RANKED-CHOICE VOTING WINNER",
		x = display.contentCenterX,
		y = display.contentCenterY - 100,
		font = native.systemFontBold,
		fontSize = 24
	})
	titleText:setFillColor(1, 1, 1)

	local winnerText = display.newText({
		text = winner,
		x = display.contentCenterX,
		y = display.contentCenterY,
		font = native.systemFontBold,
		fontSize = 36,
		align = "center"
	})
	winnerText:setFillColor(0.2, 0.8, 1)

	-- Scale text to fit within screen width with padding
	local maxWidth = display.actualContentWidth * 0.9  -- 90% of screen width
	if winnerText.width > maxWidth then
		local scale = maxWidth / winnerText.width
		winnerText:scale(scale, scale)
	end

	local percentageText = display.newText({
		text = string.format("%.1f%% (%d votes%s)", percentage, votes, isTie and " each" or ""),
		x = display.contentCenterX,
		y = winnerText.y + winnerText.height*0.5 + 40,
		font = native.systemFont,
		fontSize = 28
	})
	percentageText:setFillColor(1, 1, 0.5)
end


local function animateCounting(winner, percentage, votes, isTie)
	local countingText = display.newText({
		text = "Counting the votes.",
		x = display.contentCenterX,
		y = display.contentCenterY,
		font = native.systemFontBold,
		align = "center",
		fontSize = 20
	})
	countingText:setFillColor(1, 1, 1)
	countingText.anchorY = 0
	countingText.y = display.contentCenterY - countingText.height*0.5

	local dotCount = 1
	local animationCount = 0
	local maxAnimations =  20 -- 15 cycles * 333ms = ~5 seconds

	local function updateDots()
		animationCount = animationCount + 1

		if animationCount > maxAnimations then
			countingText:removeSelf()
			showResults(winner, percentage, votes, isTie)
			return
		end

		dotCount = (dotCount % 3) + 1
		local dots = string.rep(".", dotCount)
		countingText.text = "Counting the votes" .. dots

		if animationCount > math.floor( maxAnimations / 2 ) then
			countingText.text = "Counting the votes" .. dots .. "\n\nThis is just for show.\nThe calculation was done instantly."
		end
	end

	timer.performWithDelay(333, updateDots, maxAnimations + 1)
end


local function main( filename )
	local lines = parseCSV( filename )

	if not lines or #lines < 2 then
		local errorMessage = "ERROR: Invalid, empty or missing CSV file\n\n" .. filename

		local errorText = display.newText({
			text = errorMessage,
			x = display.contentCenterX,
			y = display.contentCenterY,
			font = native.systemFontBold,
			fontSize = 16,
			align = "center"
		})
		errorText:setFillColor( 0.9, 0, 0 )

		print( errorMessage )
		return
	end

	-- Parse header
	local headerFields = splitCSV(lines[1])
	local candidates = {}

	-- Skip first column (timestamp), extract candidate names
	for i = 2, #headerFields do
		local candidateName = extractGameName(headerFields[i])
		table.insert(candidates, candidateName)
	end

	print("Loaded candidates:")
	for i, name in ipairs(candidates) do
		print(i .. ". " .. name)
	end

	-- Parse ballots
	local ballots = {}
	for i = 2, #lines do
		local fields = splitCSV(lines[i])
		local ballot = {}

		-- Skip first column (timestamp), extract rankings
		for j = 2, #fields do
			local choice = fields[j]
			-- Extract number from format like "#1" or "1"
			local rank = tonumber(choice:match("%d+"))
			table.insert(ballot, rank)
		end

		table.insert(ballots, ballot)
	end

	print("\nLoaded " .. #ballots .. " ballots")

	-- Calculate winner
	local winner, percentage, votes, isTie = calculateRCV(ballots, candidates)

	-- Show counting animation before results
	animateCounting(winner, percentage, votes, isTie)
end


-- Initial setup
display.setDefault("background", 0.2, 0.2, 0.3)

local startText = display.newText({
	text = "Start the count!",
	x = display.contentCenterX,
	y = display.contentCenterY,
	font = native.systemFontBold,
	fontSize = 40
})
startText:setFillColor(1, 1, 1)

local function onStartTap( event )
	if event.phase == "began" then
		startText:removeSelf()
		main(csvFile)
	end
end

startText:addEventListener("touch", onStartTap)