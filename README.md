# Ball Bounce Physics Game

A fun physics-based ball game built with TypeScript, Matter.js and Bun.

## Features

- Multiple types of blocks including Multiply, Remove, Diagonal, and Plus blocks
- Physics-based ball movement and collisions
- Level progression with increasing difficulty
- Score tracking and game completion

## Game Controls

- Click to start dropping balls
- Balls will interact with different types of blocks:
  - Multiply (x2-x5): Creates additional balls based on the multiplier
  - Remove (-): Removes balls that hit it
  - Diagonal: Changes the direction of balls
  - Plus (+5-+20): Spawns 5-20 new balls and then disappears

## Setup

### Prerequisites

- [Bun](https://bun.sh/) - A fast JavaScript runtime and toolkit

### Installation

1. Clone the repository
2. Install dependencies
   ```
   bun install
   ```

## Development

To run the game:

```
bun start
```

This will start a development server and open the game in your browser.

You can then access the game at http://localhost:3000
