# Roso Games - Ranked-Choice Voting for Game Ideas

Pick the next Roso Games project democratically using ranked-choice voting.

## Quick Start

1. **Create a Google Form** with game ideas as ranked choices (using the template poll)
2. **Export responses** as CSV (`File` → `Download` → `.csv`)
3. **Rename to `votes.csv`** and drop in project root
4. **Run in Solar2D** and tap "Start the count!"

## How It Works

- Counts first-choice votes
- If no majority (>50%), eliminates weakest idea
- Redistributes votes to next choices
- Repeats until one game idea wins
- Detects ties automatically

## CSV Format

```csv
Timestamp,[Game Idea #1],[Game Idea #2],[Game Idea #3]
16.11.2025 10:00,1,2,3
16.11.2025 10:05,2,1,3
```

## Features

- Dramatic 5-second counting animation
- Winner displayed with vote percentage
- Detailed console output for each round
- Automatic tie detection
- Auto-scales for long names

## Test It

Includes 4 test CSV files in `testFiles/`:
- `test1.csv` - Clear winner
- `test2.csv` - Multiple rounds
- `test3.csv` - Close race
- `test4.csv` - 10 candidates

Change the file in `main.lua`:
```lua
local csvFile = "testFiles/test3.csv"
```

---

**Roso Games** | Made with Solar2D