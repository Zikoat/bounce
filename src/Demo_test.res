// open Webapi.Canvas
open Webapi.Canvas.Canvas2d
// open Webapi.Dom

Console.log("Hello, world!")

// todo: rename file
// todo remove package json build scripts for bun
// todo enable all warnings
// todo create unit tests for level generation
// todo create unit tests for physics engine
// todo create frontend rendering tests
// todo remove all asserc false statements
// todo migrate physicsgame to rescript
// todo migrate from drawing and collision detecting ribbons manually to using matter.js

%%raw(`
import * as Matter from 'matter-js';
const { Engine, Render, World, Bodies, Body, Runner } = Matter;

class Block {
    body = null;
    type;
    value;
    counter;
    bounds;
    justHit = false;
    hitAnimTimer = 0;
    diagonalWall = null;
    diagonalDirection = null;
    secondaryDiagonalWall = null;
    constructor(x, y, width, height, type = "Empty", multiplyValue = 0) {
        this.type = type;
        // For Multiply blocks, use the provided multiplyValue or generate a random one between 2-5
        if (type === "Multiply") {
            if (multiplyValue >= 2 && multiplyValue <= 5) {
                this.value = multiplyValue;
            }
            else {
                // Generate a random value: 2, 3, 4, or 5
                this.value = Math.floor(Math.random() * 4) + 2;
            }
        }
        // For Plus blocks, generate a random value between 2-5
        else if (type === "Plus") {
            // Generate a random value: 5 to 20
            this.value = Math.floor(Math.random() * 16) + 5;
            console.log("Created Plus block with value:", this.value);
        }
        else {
            this.value = 0;
        }
        // For Remove blocks, generate a random counter between 5 and 50
        if (type === "Remove") {
            this.counter = Math.floor(Math.random() * 46) + 5; // Random value between 5 and 50
            console.log("Created Remove block with counter:", this.counter);
        }
        else {
            this.counter = 0;
        }
        this.bounds = {
            min: { x: x - width / 2, y: y - height / 2 },
            max: { x: x + width / 2, y: y + height / 2 }
        };
        if (type !== "Multiply" && type !== "Remove" &&
            type !== "Diagonal" && type !== "Plus" &&
            type !== "Chevron") {
            this.body = Bodies.rectangle(x, y, width, height, {
                isStatic: true,
                render: {
                    fillStyle: this.getFillStyle()
                }
            });
            '';
            this.body.label = 'block';
        }
        else if (type === "Diagonal") {
            this.diagonalDirection = Math.random() < 0.5 ? 'leftToRight' : 'rightToLeft';
        }
        // For debugging: check if block types have a body set
        if (type === "Plus") {
            console.log("Plus block body set to:", this.body ? "has body" : "null");
        }
    }
    getFillStyle() {
        return getFillStyle(this.type);
    }
    drawRibbon(ctx) {
        const setHitAnimTimer = (hitAnimTimer) => {
            this.hitAnimTimer = hitAnimTimer;
        }
        drawRibbon2(ctx, this.bounds, this.type, this.value, this.hitAnimTimer, this.counter, setHitAnimTimer)
    }
    isPointInRibbon(x, y) {
        return isPointInRibbon2(x, y, this.type, this.bounds)
        
    }

}
class PhysicsGame {
    // Static constants that were previously global
    static GLOBAL_BOUNCE = 0.7;
    static GLOBAL_FRICTION = 0;
    engine;
    render;
    runner;
    balls;
    walls;
    blocks;
    canvas;
    spawnPosition;
    nextSpawnTime;
    currentLevel = 1;
    score = 0;
    ballsRemaining = 20;
    initialBallCount = 20; // Track initial ball count for spawn rate calculation
    spawnActive = false;
    levelCompleteMessage = "";
    levelCompleteTimer = 0;
    SPAWN_INTERVAL = 300; // Base spawn interval in ms
    SPAWN_HEIGHT = 50;
    BALL_RADIUS = 15;
    CANVAS_WIDTH = 600;
    CANVAS_HEIGHT = 900;
    LANE_COUNT = 5;
    BLOCK_COUNT = 5;
    WALL_THICKNESS = 10;
    WALL_START_Y = 150;
    BLOCK_HEIGHT_RATIO = 0.8;
    DIAGONAL_THICKNESS = 10;
    LEVEL_COMPLETE_MESSAGE_DURATION = 120;
    MIN_SPAWN_INTERVAL = 50; // Minimum spawn interval (fastest speed)
    MAX_BALLS_FOR_BASE_SPEED = 20; // Number of balls below which we use the base speed
    NO_COLLECTION_TIMEOUT = 300; // 5 seconds at 60 FPS
    MAX_LEVELS = 3; // Maximum number of levels before game ends
    verticalWallSegments = [];
    // Total number of balls for the level (for tracking completion)
    totalBallsInLevel = 20;
    // Timer to track time since last ball was collected
    timeSinceLastCollection = 0;
    // Game over state
    gameOver = false;
    finalScore = 0;
    // Map to track which multiply blocks each ball has visited
    ballToVisitedBlocks = new Map();
    constructor() {
        const canvasElement = document.getElementById('game-canvas');
        if (!canvasElement) {
            throw new Error('Canvas element not found');
        }
        this.canvas = canvasElement;
        this.engine = Engine.create();
        this.engine.world.gravity.y = 1;
        this.render = Render.create({
            canvas: this.canvas,
            engine: this.engine,
            options: {
                width: this.CANVAS_WIDTH,
                height: this.CANVAS_HEIGHT,
                wireframes: false,
                background: '#f0f0f0'
            }
        });
        this.spawnPosition = { x: this.CANVAS_WIDTH / 2, y: this.SPAWN_HEIGHT };
        this.nextSpawnTime = 0;
        this.balls = [];
        this.walls = [];
        this.blocks = [];
        this.createLanes();
        // Initialize the game with level 1
        this.currentLevel = 0; // Will be incremented to 1 in startNextLevel
        this.startNextLevel();
        Matter.Events.on(this.engine, 'collisionStart', this.handleCollisions);
        this.runner = Runner.create();
        Runner.run(this.runner, this.engine);
        Render.run(this.render);
        this.setupEventListeners();
        requestAnimationFrame(this.gameLoop);
    }
    createLanes() {
        const laneWidth = this.CANVAS_WIDTH / this.LANE_COUNT;
        const blockHeight = (this.CANVAS_HEIGHT - this.WALL_START_Y) / this.BLOCK_COUNT * this.BLOCK_HEIGHT_RATIO;
        this.verticalWallSegments = Array(this.LANE_COUNT + 1).fill(null).map(() => Array(this.BLOCK_COUNT).fill(null).map(() => []));
        for (let laneIndex = 0; laneIndex <= this.LANE_COUNT; laneIndex++) {
            const x = laneWidth * laneIndex;
            // Add walls from top of canvas to WALL_START_Y for the leftmost and rightmost lanes
            if (laneIndex === 0 || laneIndex === this.LANE_COUNT) {
                // Calculate the height of the top wall section
                const topWallHeight = this.WALL_START_Y;
                const topWallY = topWallHeight / 2; // Center point of the wall
                const topWall = Bodies.rectangle(x, topWallY, this.WALL_THICKNESS, topWallHeight, {
                    isStatic: true,
                    render: {
                        fillStyle: '#95a5a6'
                    }
                });
                topWall.label = 'wall';
                this.walls.push(topWall);
                World.add(this.engine.world, topWall);
            }
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                // Skip creating wall segment with medium probability (45%)
                // But always keep walls on the outer edges
                if ((laneIndex !== 0 && laneIndex !== this.LANE_COUNT) && Math.random() < 0.45) {
                    continue;
                }
                const y = this.WALL_START_Y + (blockHeight * blockIndex) + (blockHeight / 2);
                const wallSegment = Bodies.rectangle(x, y, this.WALL_THICKNESS, blockHeight, {
                    isStatic: true,
                    render: {
                        fillStyle: '#95a5a6'
                    }
                });
                wallSegment.label = 'wall';
                const blockSegments = this.verticalWallSegments[laneIndex]?.[blockIndex];
                if (blockSegments) {
                    blockSegments.push(wallSegment);
                    this.walls.push(wallSegment);
                    World.add(this.engine.world, wallSegment);
                }
            }
            // Add bottom wall extensions
            if (laneIndex === 0 || laneIndex === this.LANE_COUNT) {
                const extraWallHeight = this.BALL_RADIUS * 3;
                const extraWallY = this.CANVAS_HEIGHT + (extraWallHeight / 3);
                const sideWallExtension = Bodies.rectangle(x, extraWallY, this.WALL_THICKNESS, extraWallHeight, {
                    isStatic: true,
                    render: {
                        fillStyle: '#95a5a6',
                        visible: false
                    }
                });
                sideWallExtension.label = 'wall';
                this.walls.push(sideWallExtension);
                World.add(this.engine.world, sideWallExtension);
            }
        }
    }
    createBlocks() {
        const laneWidth = this.CANVAS_WIDTH / this.LANE_COUNT;
        const blockHeight = (this.CANVAS_HEIGHT - this.WALL_START_Y) / this.BLOCK_COUNT * this.BLOCK_HEIGHT_RATIO;
        const blockWidth = laneWidth - this.WALL_THICKNESS;
        if (this.blocks.length > 0) {
            this.clearExistingBlocks();
        }
        this.blocks = [];
        const blockLayout = this.generateRandomBlockLayout();
        for (let laneIndex = 0; laneIndex < this.LANE_COUNT; laneIndex++) {
            const laneArray = [];
            this.blocks.push(laneArray);
            const laneX = (laneIndex * laneWidth) + (laneWidth / 2);
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                const blockY = this.WALL_START_Y + (blockHeight * blockIndex) + (blockHeight / 2);
                if (!blockLayout[laneIndex]) {
                    throw new Error("Lane " + laneIndex + " is undefined in blockLayout");
                }
                const type = blockLayout[laneIndex][blockIndex];
                if (type === undefined) {
                    throw new Error("Block type at [" + laneIndex + "][" + blockIndex + "] is undefined");
                }
                const block = new Block(laneX, blockY, blockWidth, blockHeight, type);
                laneArray.push(block);
                if (block.type !== "Empty" && block.type !== "Multiply" &&
                    block.type !== "Remove" && block.body !== null) {
                    World.add(this.engine.world, block.body);
                }
                if (block.type === "Diagonal") {
                    this.createDiagonalWall(block, laneIndex, blockIndex);
                }
                if (block.type === "Chevron") {
                    this.createChevronWall(block, laneIndex, blockIndex);
                }
            }
        }
    }
    clearExistingBlocks() {
        if (!this.blocks)
            return;
        for (const laneArray of this.blocks) {
            if (!laneArray)
                continue;
            for (const block of laneArray) {
                if (!block)
                    continue;
                if (block.body) {
                    World.remove(this.engine.world, block.body);
                }
                if (block.diagonalWall) {
                    World.remove(this.engine.world, block.diagonalWall);
                }
                if (block.secondaryDiagonalWall) {
                    World.remove(this.engine.world, block.secondaryDiagonalWall);
                }
            }
        }
        this.blocks = [];
    }
   
    generateRandomBlockLayout() {
        // Create an array filled with empty blocks
        const layout = [];
        // Initialize with Empty blocks
        for (let laneIndex = 0; laneIndex < this.LANE_COUNT; laneIndex++) {
            layout[laneIndex] = [];
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                const lane = layout[laneIndex];
                if (!lane) {
                    throw new Error("Lane " + laneIndex + " is undefined");
                }
                lane[blockIndex] = "Empty";
            }
        }
        // First pass: generate random blocks
        for (let laneIndex = 0; laneIndex < this.LANE_COUNT; laneIndex++) {
            const lane = layout[laneIndex];
            if (!lane) {
                throw new Error("Lane " + laneIndex + " is undefined in first pass");
            }
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                // Skip the first row
                if (blockIndex === 0) {
                    continue;
                }
                lane[blockIndex] = this.getRandomBlockType(this.currentLevel);
            }
        }
        // Second pass: resolve conflicts
        for (let laneIndex = 0; laneIndex < this.LANE_COUNT; laneIndex++) {
            const lane = layout[laneIndex];
            if (!lane) {
                throw new Error("Lane " + laneIndex + " is undefined in second pass");
            }
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                // Skip the first row
                if (blockIndex === 0)
                    continue;
                // Handle Multiply blocks
                if (lane[blockIndex] === "Multiply") {
                    // Don't place Multiply blocks above each other
                    if (blockIndex > 0) {
                        const blockAbove = lane[blockIndex - 1];
                        if (blockAbove === undefined) {
                            throw new Error("Block at [" + laneIndex + "][" + (blockIndex - 1) + "] is undefined");
                        }
                        if (blockAbove === "Multiply") {
                            lane[blockIndex] = "Empty";
                            continue;
                        }
                    }
                    // Don't place Multiply blocks next to each other horizontally
                    if (laneIndex > 0) {
                        const leftLane = layout[laneIndex - 1];
                        if (!leftLane) {
                            throw new Error("Lane " + (laneIndex - 1) + " is undefined");
                        }
                        const blockToLeft = leftLane[blockIndex];
                        if (blockToLeft === undefined) {
                            throw new Error("Block at [" + (laneIndex - 1) + "][" + blockIndex + "] is undefined");
                        }
                        if (blockToLeft === "Multiply") {
                            lane[blockIndex] = "Empty";
                            continue;
                        }
                    }
                }
                // Handle Diagonal blocks
                if (lane[blockIndex] === "Diagonal") {
                    // Don't place diagonal blocks in the first or last lane
                    if (laneIndex === 0 || laneIndex === this.LANE_COUNT - 1) {
                        lane[blockIndex] = "Empty";
                        continue;
                    }
                    // Don't place adjacent diagonal blocks
                    if (laneIndex > 0) {
                        const leftLane = layout[laneIndex - 1];
                        if (!leftLane) {
                            throw new Error("Lane " + (laneIndex - 1) + " is undefined when checking diagonals");
                        }
                        const blockToLeft = leftLane[blockIndex];
                        if (blockToLeft === undefined) {
                            throw new Error("Block at [" + (laneIndex - 1) + "][" + blockIndex + "] is undefined when checking diagonals");
                        }
                        if (blockToLeft === "Diagonal") {
                            lane[blockIndex] = "Empty";
                            continue;
                        }
                    }
                }
                // Handle Chevron blocks
                if (lane[blockIndex] === "Chevron") {
                    // Don't place chevron blocks in the first or last lane
                    if (laneIndex === 0 || laneIndex === this.LANE_COUNT - 1) {
                        lane[blockIndex] = "Empty";
                        continue;
                    }
                    // Don't place chevrons next to each other
                    let hasAdjacentChevron = false;
                    // Check left
                    if (laneIndex > 0) {
                        const leftLane = layout[laneIndex - 1];
                        if (!leftLane) {
                            throw new Error("Lane " + (laneIndex - 1) + " is undefined when checking for adjacent chevrons");
                        }
                        const blockToLeft = leftLane[blockIndex];
                        if (blockToLeft === undefined) {
                            throw new Error("Block at [" + (laneIndex - 1) + "][" + blockIndex + "] is undefined when checking for adjacent chevrons");
                        }
                        if (blockToLeft === "Chevron") {
                            hasAdjacentChevron = true;
                        }
                    }
                    // Check right
                    if (laneIndex < this.LANE_COUNT - 1) {
                        const rightLane = layout[laneIndex + 1];
                        if (!rightLane) {
                            throw new Error("Lane " + (laneIndex + 1) + " is undefined when checking for adjacent chevrons");
                        }
                        const blockToRight = rightLane[blockIndex];
                        if (blockToRight === undefined) {
                            throw new Error("Block at [" + (laneIndex + 1) + "][" + blockIndex + "] is undefined when checking for adjacent chevrons");
                        }
                        if (blockToRight === "Chevron") {
                            hasAdjacentChevron = true;
                        }
                    }
                    if (hasAdjacentChevron) {
                        lane[blockIndex] = "Empty";
                        continue;
                    }
                    // Don't place a diagonal to the right of a chevron which goes from top right to bottom left
                    if (laneIndex < this.LANE_COUNT - 1) {
                        const rightLane = layout[laneIndex + 1];
                        if (!rightLane) {
                            throw new Error("Lane " + (laneIndex + 1) + " is undefined when checking right of chevron");
                        }
                        const blockToRight = rightLane[blockIndex];
                        if (blockToRight === undefined) {
                            throw new Error("Block at [" + (laneIndex + 1) + "][" + blockIndex + "] is undefined when checking right of chevron");
                        }
                        if (blockToRight === "Diagonal") {
                            // We'll set the diagonal direction in the next pass, but here we'll just prevent the combination
                            rightLane[blockIndex] = "Empty";
                        }
                    }
                    // Don't place a diagonal block to the left of a chevron which goes from top left to bottom right
                    if (laneIndex > 0) {
                        const leftLane = layout[laneIndex - 1];
                        if (!leftLane) {
                            throw new Error("Lane " + (laneIndex - 1) + " is undefined when checking left of chevron");
                        }
                        const blockToLeft = leftLane[blockIndex];
                        if (blockToLeft === undefined) {
                            throw new Error("Block at [" + (laneIndex - 1) + "][" + blockIndex + "] is undefined when checking left of chevron");
                        }
                        if (blockToLeft === "Diagonal") {
                            // Same as above, prevent the combination
                            leftLane[blockIndex] = "Empty";
                        }
                    }
                }
            }
        }
        return layout;
    }
    getRandomBlockType(currentLevel) {
        return getRandomBlockType2(currentLevel);
    }
    createDiagonalWall(block, laneIndex, blockIndex) {
        if (block.diagonalWall) {
            return;
        }
        // Check for adjacent diagonal block that could create a V-trap
        let adjacentDirection = null;
        // Check left adjacent diagonal if not at leftmost lane
        if (laneIndex > 0 && blockIndex < this.BLOCK_COUNT) {
            // Check if blocks array for adjacent lane exists and has a block at this index
            const leftLaneBlocks = this.blocks[laneIndex - 1];
            if (leftLaneBlocks && Array.isArray(leftLaneBlocks) && leftLaneBlocks.length > blockIndex) {
                const leftBlock = leftLaneBlocks[blockIndex];
                // Check if the left block is a diagonal block with a direction
                if (leftBlock && leftBlock.type === "Diagonal" && leftBlock.diagonalDirection) {
                    adjacentDirection = leftBlock.diagonalDirection;
                }
            }
        }
        // Check right adjacent diagonal if not at rightmost lane
        if (laneIndex < this.LANE_COUNT - 1 && blockIndex < this.BLOCK_COUNT) {
            // Check if blocks array for adjacent lane exists and has a block at this index
            const rightLaneBlocks = this.blocks[laneIndex + 1];
            if (rightLaneBlocks && Array.isArray(rightLaneBlocks) && rightLaneBlocks.length > blockIndex) {
                const rightBlock = rightLaneBlocks[blockIndex];
                // Check if the right block is a diagonal block with a direction
                if (rightBlock && rightBlock.type === "Diagonal" && rightBlock.diagonalDirection) {
                    adjacentDirection = rightBlock.diagonalDirection;
                }
            }
        }
        // If we found an adjacent diagonal, make sure we use the opposite direction
        if (adjacentDirection) {
            block.diagonalDirection = adjacentDirection === 'leftToRight' ? 'rightToLeft' : 'leftToRight';
        }
        else if (!block.diagonalDirection) {
            // No adjacent diagonal, just pick random direction
            block.diagonalDirection = Math.random() < 0.5 ? 'leftToRight' : 'rightToLeft';
        }
        if (!block.bounds ||
            typeof block.bounds.min?.x !== 'number' ||
            typeof block.bounds.min?.y !== 'number' ||
            typeof block.bounds.max?.x !== 'number' ||
            typeof block.bounds.max?.y !== 'number') {
            throw Error("Block bounds not properly defined");
        }
        const minX = block.bounds.min.x;
        const minY = block.bounds.min.y;
        const maxX = block.bounds.max.x;
        const maxY = block.bounds.max.y;
        const centerX = (minX + maxX) / 2;
        const centerY = (minY + maxY) / 2;
        const width = maxX - minX;
        const height = maxY - minY;
        const diagonalAngle = Math.atan2(height, width);
        const scaledThickness = this.WALL_THICKNESS / Math.sin(diagonalAngle);
        let vertices;
        if (block.diagonalDirection === 'leftToRight') {
            const dx = (scaledThickness / 2) * Math.sin(diagonalAngle);
            const dy = (scaledThickness / 2) * Math.cos(diagonalAngle);
            vertices = [
                { x: minX - dx, y: minY + dy },
                { x: minX + dx, y: minY - dy },
                { x: maxX + dx, y: maxY - dy },
                { x: maxX - dx, y: maxY + dy }
            ];
            this.removeWallSegment(laneIndex, blockIndex);
            if (laneIndex < this.LANE_COUNT - 1) {
                this.removeWallSegment(laneIndex + 1, blockIndex);
            }
        }
        else {
            const dx = (scaledThickness / 2) * Math.sin(diagonalAngle);
            const dy = (scaledThickness / 2) * Math.cos(diagonalAngle);
            vertices = [
                { x: maxX + dx, y: minY + dy },
                { x: maxX - dx, y: minY - dy },
                { x: minX - dx, y: maxY - dy },
                { x: minX + dx, y: maxY + dy }
            ];
            if (laneIndex > 0) {
                this.removeWallSegment(laneIndex, blockIndex);
            }
            if (laneIndex < this.LANE_COUNT) {
                this.removeWallSegment(laneIndex + 1, blockIndex);
            }
        }
        const diagonalBody = Bodies.fromVertices(centerX, centerY, [vertices], {
            isStatic: true,
            render: {
                fillStyle: '#95a5a6'
            },
            friction: PhysicsGame.GLOBAL_FRICTION,
            restitution: PhysicsGame.GLOBAL_BOUNCE
        });
        if (!diagonalBody) {
            throw Error("Failed to create diagonal wall - null body returned");
        }
        diagonalBody.label = 'diagonalWall';
        block.diagonalWall = diagonalBody;
        World.add(this.engine.world, diagonalBody);
    }
    drawDiagonalForBlock(block, ctx) {
        if (block.type !== "Diagonal" || !block.bounds) {
            return;
        }
        const minX = block.bounds.min.x;
        const minY = block.bounds.min.y;
        const maxX = block.bounds.max.x;
        const maxY = block.bounds.max.y;
        if (!block.diagonalWall) {
            ctx.save();
            ctx.strokeStyle = '#95a5a6';
            ctx.lineWidth = this.DIAGONAL_THICKNESS;
            ctx.beginPath();
            if (block.diagonalDirection === 'leftToRight') {
                ctx.moveTo(minX, minY);
                ctx.lineTo(maxX, maxY);
            }
            else {
                ctx.moveTo(maxX, minY);
                ctx.lineTo(minX, maxY);
            }
            ctx.stroke();
            ctx.restore();
        }
    }
    removeWallSegment(laneIndex, blockIndex) {
        if (laneIndex < 0 || laneIndex >= this.verticalWallSegments.length) {
            return;
        }
        const laneSegments = this.verticalWallSegments[laneIndex];
        if (!laneSegments || blockIndex < 0 || blockIndex >= laneSegments.length) {
            return;
        }
        const blockSegments = laneSegments[blockIndex];
        if (!blockSegments || blockSegments.length === 0) {
            return;
        }
        for (const wallSegment of [...blockSegments]) {
            this.walls = this.walls.filter(wall => wall !== wallSegment);
            World.remove(this.engine.world, wallSegment);
        }
        if (this.verticalWallSegments[laneIndex] && this.verticalWallSegments[laneIndex][blockIndex]) {
            this.verticalWallSegments[laneIndex][blockIndex] = [];
        }
    }
    handleCollisions = (event) => {
        event.pairs.forEach((pair) => {
            const bodyA = pair.bodyA;
            const bodyB = pair.bodyB;
            const ball = bodyA.label === 'ball' ? bodyA : bodyB.label === 'ball' ? bodyB : null;
            const blockBody = bodyA.label === 'block' ? bodyA : bodyB.label === 'block' ? bodyB : null;
            if (ball && blockBody) {
                const block = this.findBlockByBody(blockBody);
                if (block && block.body) {
                    console.log("Block collision detected in handleCollisions, block type:", block.type);
                    this.handleBlockCollision(ball, block);
                }
            }
        });
    };
    findBlockByBody(body) {
        for (const lane of this.blocks) {
            for (const block of lane) {
                if (block.body === body) {
                    return block;
                }
            }
        }
        return null;
    }
    handleBlockCollision(ball, block) {
        switch (block.type) {
            case "Multiply":
                // Check if the ball has already visited this block
                const visitedBlocks = this.ballToVisitedBlocks.get(ball.id);
                if (visitedBlocks && visitedBlocks.has(block)) {
                    return;
                }
                // If we don't have a visited set for this ball yet, create one
                if (!visitedBlocks) {
                    this.ballToVisitedBlocks.set(ball.id, new Set());
                }
                this.handleMultiplication(ball, block);
                break;
            case "Plus":
                console.log("Plus block collision detected in handleBlockCollision!");
                if (!block.isPointInRibbon(ball.position.x, ball.position.y)) {
                    console.log("Ball is not in Plus block ribbon area!");
                    return;
                }
                console.log("Calling handlePlusBlock with ball id:", ball.id);
                this.handlePlusBlock(ball, block);
                // Remove the Plus block after it's hit by replacing it with an Empty block
                block.type = "Empty";
                block.value = 0;
                console.log("Plus block set to empty");
                break;
            case "Remove":
                if (!block.isPointInRibbon(ball.position.x, ball.position.y)) {
                    return;
                }
                block.counter--;
                block.justHit = true;
                block.hitAnimTimer = 10;
                World.remove(this.engine.world, ball);
                // Clean up the map when the ball is removed
                this.ballToVisitedBlocks.delete(ball.id);
                this.balls = this.balls.filter(b => b !== ball);
                this.drawRemoveEffect(ball.position.x, ball.position.y);
                if (block.counter <= 0) {
                    const blockBounds = {
                        x: (block.bounds.min.x + block.bounds.max.x) / 2,
                        y: (block.bounds.min.y + block.bounds.max.y) / 2,
                        width: block.bounds.max.x - block.bounds.min.x,
                        height: block.bounds.max.y - block.bounds.min.y
                    };
                    for (const laneArray of this.blocks) {
                        const blockIndex = laneArray.indexOf(block);
                        if (blockIndex !== -1) {
                            laneArray[blockIndex] = new Block(blockBounds.x, blockBounds.y, blockBounds.width, blockBounds.height, "Empty");
                            break;
                        }
                    }
                }
                break;
            case "Diagonal":
                break;
        }
    }
    drawMultiplyEffect(x, y, value = 2) {
        drawMultiplyEffect2(x, y, value, this.render.context, this.BALL_RADIUS);
    }
    drawPlusEffect(x, y, value = 2) {
        drawPlusEffect2(x, y, value, this.render.context, this.BALL_RADIUS);
    }
    drawRemoveEffect(x, y) {
        drawRemoveEffect2(x, y, this.render.context, this.BALL_RADIUS);
    }
    setupEventListeners() {
        this.canvas.addEventListener('mousemove', (event) => {
            const rect = this.canvas.getBoundingClientRect();
            const scaleX = this.canvas.width / rect.width;
            const scaleY = this.canvas.height / rect.height;
            let mouseX = (event.clientX - rect.left) * scaleX;
            // Ensure the mouse position stays within the canvas bounds
            mouseX = Math.max(this.BALL_RADIUS, Math.min(this.CANVAS_WIDTH - this.BALL_RADIUS, mouseX));
            this.spawnPosition.x = mouseX;
        });
        // Add touch event for mobile devices
        this.canvas.addEventListener('touchmove', (event) => {
            event.preventDefault(); // Prevent scrolling when touching the canvas
            // TypeScript doesn't understand that we've checked the length, so we explicitly check again
            const touch = event.touches[0];
            if (touch) {
                const rect = this.canvas.getBoundingClientRect();
                const scaleX = this.canvas.width / rect.width;
                const scaleY = this.canvas.height / rect.height;
                let touchX = (touch.clientX - rect.left) * scaleX;
                // Ensure the touch position stays within the canvas bounds
                touchX = Math.max(this.BALL_RADIUS, Math.min(this.CANVAS_WIDTH - this.BALL_RADIUS, touchX));
                this.spawnPosition.x = touchX;
            }
        }, { passive: false });
        // Add touchend event for mobile clicks
        this.canvas.addEventListener('touchend', (event) => {
            event.preventDefault(); // Prevent default behavior
            // Handle the same logic as click event
            if (this.levelCompleteTimer > 0) {
                this.levelCompleteTimer = 0;
                return;
            }
            // If game is over, restart the game on touch
            if (this.gameOver) {
                this.restartGame();
                return;
            }
            // Toggle spawn state on touch
            this.spawnActive = !this.spawnActive;
            if (this.spawnActive) {
                this.nextSpawnTime = Date.now();
            }
        }, { passive: false });
        // Restore the click event handler for desktop
        this.canvas.addEventListener('click', (event) => {
            if (this.levelCompleteTimer > 0) {
                this.levelCompleteTimer = 0;
                return;
            }
            // If game is over, restart the game on click
            if (this.gameOver) {
                this.restartGame();
                return;
            }
            if (!this.spawnActive) {
                this.spawnActive = true;
                this.nextSpawnTime = Date.now();
            }
        });
    }
    createBall() {
        // Calculate the horizontal randomness factor based on ball count
        // More balls = faster spawn rate = more randomness
        let randomnessFactor = 0.5; // Base randomness (0.5 ball width) - reduced by half
        if (this.initialBallCount > this.MAX_BALLS_FOR_BASE_SPEED) {
            // Calculate a factor that scales with the number of balls
            // More balls → bigger randomness, up to 1x ball width for 100+ extra balls
            const extraBalls = this.initialBallCount - this.MAX_BALLS_FOR_BASE_SPEED;
            const maxExtraRandomness = 0.5; // Additional randomness (up to +0.5 ball width) - reduced by half
            randomnessFactor += Math.min(extraBalls / 100, 1.0) * maxExtraRandomness;
        }
        // Apply randomness to x position (now up to a half ball width in either direction, scaled by factor)
        const randomX = (Math.random() - 0.5) * this.BALL_RADIUS * 2 * randomnessFactor;
        const ball = Bodies.circle(this.spawnPosition.x + randomX, this.spawnPosition.y, this.BALL_RADIUS, {
            restitution: PhysicsGame.GLOBAL_BOUNCE,
            friction: PhysicsGame.GLOBAL_FRICTION,
            render: {
                fillStyle: '#e74c3c'
            }
        });
        ball.label = 'ball';
        ball.id = Math.floor(Math.random() * 1000000);
        // Initialize an empty set of visited blocks for this ball
        this.ballToVisitedBlocks.set(ball.id, new Set());
        return ball;
    }
    gameLoop = () => {
        const currentTime = Date.now();
        if (this.spawnActive && currentTime > this.nextSpawnTime && this.ballsRemaining > 0) {
            const ball = this.createBall();
            World.add(this.engine.world, ball);
            this.balls.push(ball);
            // Calculate dynamic spawn interval based on initial ball count, not remaining balls
            // This ensures the spawn rate stays consistent throughout the level
            let spawnInterval = this.SPAWN_INTERVAL;
            if (this.initialBallCount > this.MAX_BALLS_FOR_BASE_SPEED) {
                // Scale down the interval based on how many balls we started with
                const extraBalls = this.initialBallCount - this.MAX_BALLS_FOR_BASE_SPEED;
                const scalingFactor = (this.SPAWN_INTERVAL - this.MIN_SPAWN_INTERVAL) / 100; // Scale over 100 extra balls
                spawnInterval = Math.max(this.SPAWN_INTERVAL - (extraBalls * scalingFactor), this.MIN_SPAWN_INTERVAL);
            }
            this.nextSpawnTime = currentTime + spawnInterval;
            this.ballsRemaining--;
        }
        const ballsCountBefore = this.balls.length;
        for (const ball of this.balls) {
            this.checkRibbonCollisions(ball);
        }
        this.balls = this.balls.filter(ball => {
            if (ball.position.y > this.CANVAS_HEIGHT + this.BALL_RADIUS * 2) {
                World.remove(this.engine.world, ball);
                this.score += 1;
                // Clean up the map when a ball is removed
                this.ballToVisitedBlocks.delete(ball.id);
                // Reset the timer since we just collected a ball
                this.timeSinceLastCollection = 0;
                return false;
            }
            return true;
        });
        const ballsCountAfter = this.balls.length;
        // Check if all balls have been spawned
        if (this.ballsRemaining === 0) {
            // If there are no balls in play, check if we need to start next level
            if (this.balls.length === 0) {
                // All balls have been collected, start next level immediately
                this.startNextLevel();
            }
            // If there are still balls in play, increment the timer since last collection
            else {
                this.timeSinceLastCollection++;
                // If it's been 5 seconds (300 frames at 60fps) since the last ball was collected
                // and all balls have been spawned, move to the next level
                if (this.timeSinceLastCollection >= this.NO_COLLECTION_TIMEOUT) {
                    this.startNextLevel();
                }
            }
        }
        const ctx = this.render.context;
        for (const laneArray of this.blocks) {
            for (const block of laneArray) {
                block.drawRibbon(ctx);
                this.drawDiagonalForBlock(block, ctx);
                this.drawChevronForBlock(block, ctx);
            }
        }
        this.drawUI(ctx);
        // Periodically check for and clean up any stray chevron arms
        if (Math.random() < 0.05) { // Only check occasionally (5% chance per frame) to save performance
            this.cleanupStrayChevronArms();
        }
        requestAnimationFrame(this.gameLoop);
    };
    drawUI(ctx) {
        ctx.save();
        ctx.fillStyle = '#2c3e50';
        ctx.font = 'bold 24px Arial';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.fillText("Level: " + this.currentLevel, this.CANVAS_WIDTH / 2, 20);
        ctx.textAlign = 'right';
        ctx.fillText("Balls: " + this.ballsRemaining, this.CANVAS_WIDTH - 20, 20);
        ctx.textAlign = 'left';
        ctx.fillText("Collected: " + this.score, 20, 20);
        ctx.textAlign = 'right';
        ctx.fillText("In play: " + this.balls.length, this.CANVAS_WIDTH - 20, 50);
        // Show timeout countdown when all balls have been spawned but some are still in play
        // Only show the countdown when there are 4 or fewer seconds remaining
        if (this.ballsRemaining === 0 && this.balls.length > 0 && this.timeSinceLastCollection > 0) {
            const timeLeft = Math.ceil((this.NO_COLLECTION_TIMEOUT - this.timeSinceLastCollection) / 60); // Convert to seconds
            // Only show the countdown text when 4 or fewer seconds remain
            if (timeLeft <= 4) {
                ctx.textAlign = 'center';
                ctx.fillStyle = timeLeft <= 2 ? '#e74c3c' : '#f39c12'; // Red when < 2 seconds, orange otherwise
                ctx.fillText("Next level in: " + timeLeft + "s", this.CANVAS_WIDTH / 2, 50);
            }
        }
        if (this.levelCompleteTimer > 0) {
            const alpha = Math.min(1, this.levelCompleteTimer / 30);
            ctx.fillStyle = "rgba(0, 0, 0, " + alpha * 0.7 + ")";
            ctx.fillRect(0, 0, this.CANVAS_WIDTH, this.CANVAS_HEIGHT);
            ctx.fillStyle = "rgba(255, 255, 255, " + alpha + ")";
            ctx.font = 'bold 36px Arial';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            // Split message by newline and display each line
            const messageLines = this.levelCompleteMessage.split('\n');
            messageLines.forEach((line, index) => {
                ctx.fillText(line, this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2 - 70 + (index * 40));
            });
            ctx.font = 'bold 24px Arial';
            if (this.currentLevel === 1) {
                // First level - simple message
                ctx.fillText("Click to Start", this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2 + 50);
            }
            else if (this.gameOver) {
                // Game over screen
                ctx.fillText("Click to Restart", this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2 + 50);
                // Show total score across all levels
                ctx.font = '20px Arial';
                ctx.fillText("Total balls collected: " + this.finalScore, this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2);
            }
            else {
                // Subsequent levels - show level and stats
                ctx.fillText("Click to start Level " + this.currentLevel, this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2 + 50);
                ctx.font = '20px Arial';
                ctx.fillText("Collected this level: " + this.score, this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2 - 30);
                ctx.fillText("Total balls for next level: " + this.initialBallCount, this.CANVAS_WIDTH / 2, this.CANVAS_HEIGHT / 2);
            }
            this.levelCompleteTimer--;
        }
        if (this.spawnActive) {
            ctx.fillStyle = 'rgba(231, 76, 60, 0.3)';
        }
        else {
            ctx.fillStyle = 'rgba(52, 152, 219, 0.5)';
            if (this.levelCompleteTimer <= 0) {
                ctx.font = 'bold 18px Arial';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'bottom';
                ctx.fillText('Click to Start', this.spawnPosition.x, this.spawnPosition.y - this.BALL_RADIUS - 5);
            }
        }
        if (this.levelCompleteTimer <= 0) {
            ctx.beginPath();
            ctx.arc(this.spawnPosition.x, this.spawnPosition.y, this.BALL_RADIUS, 0, Math.PI * 2);
            ctx.fill();
        }
        ctx.restore();
    }
    removeRandomWalls() {
        // Only remove internal wall segments (not the outer edge walls)
        for (let laneIndex = 1; laneIndex < this.LANE_COUNT; laneIndex++) {
            for (let blockIndex = 0; blockIndex < this.BLOCK_COUNT; blockIndex++) {
                // 30% chance to remove each internal wall segment (down from 50%)
                if (Math.random() < 0.3) {
                    this.removeWallSegment(laneIndex, blockIndex);
                }
            }
        }
    }
    startNextLevel() {
        // Save completion info before resetting
        const allBallsCollected = (this.score === this.totalBallsInLevel);
        // Increment the level counter
        this.currentLevel++;
        // Check if we've reached the maximum number of levels
        if (this.currentLevel > this.MAX_LEVELS) {
            this.endGame();
            return;
        }
        // Save the score from previous level as ball count for this level
        // For the first level, we start with 20 balls
        const ballsForThisLevel = this.currentLevel === 1 ? 20 : this.score;
        // Set the initial ball count for consistent spawn rate calculation
        this.initialBallCount = ballsForThisLevel;
        this.ballsRemaining = ballsForThisLevel;
        // Set the total balls for level completion tracking
        this.totalBallsInLevel = ballsForThisLevel;
        // Reset the collection timer
        this.timeSinceLastCollection = 0;
        // Reset the score counter for this level
        this.score = 0;
        // Always start with spawning inactive (require click to start)
        this.spawnActive = false;
        this.levelCompleteMessage = "";
        this.levelCompleteTimer = 0;
        // Clear any remaining balls
        for (const ball of [...this.balls]) {
            World.remove(this.engine.world, ball);
        }
        this.balls = [];
        // Clear the visited blocks map
        this.ballToVisitedBlocks.clear();
        this.createBlocks();
        this.removeRandomWalls(); // Add additional random wall removal
        // Only show level info screen for levels after the first
        if (this.currentLevel > 1) {
            this.levelCompleteMessage = "Level " + this.currentLevel;
            // Add completion info to the message
            if (allBallsCollected) {
                this.levelCompleteMessage += "\nPerfect! All balls collected!";
            }
            this.levelCompleteTimer = this.LEVEL_COMPLETE_MESSAGE_DURATION;
        }
        // For level 1, don't set levelCompleteTimer or message - just let the player click to start
    }
    checkRibbonCollisions(ball) {
        if (ball.id === undefined) {
            throw new Error("Ball missing ID property - not properly initialized");
        }
        if (!this.ballToVisitedBlocks.has(ball.id)) {
            console.warn("Ball ID=" + ball.id + " missing visitedMultiplyBlocks - initializing now");
            this.ballToVisitedBlocks.set(ball.id, new Set());
        }
        let shouldContinue = true;
        this.blocks.forEach((laneArray, laneIndex) => {
            if (!shouldContinue)
                return;
            laneArray.forEach((block, blockIndex) => {
                if (!shouldContinue)
                    return;
                if (block.type === "Remove") {
                    const bounds = block.bounds;
                }
                let collisionDetected = block.isPointInRibbon(ball.position.x, ball.position.y);
                if (!collisionDetected && (Math.abs(ball.velocity.x) > 2 || Math.abs(ball.velocity.y) > 2)) {
                    const futureX = ball.position.x + ball.velocity.x * 0.05;
                    const futureY = ball.position.y + ball.velocity.y * 0.05;
                    collisionDetected = block.isPointInRibbon(futureX, futureY);
                    if (!collisionDetected) {
                        collisionDetected = this.lineSegmentIntersectsRibbon(ball.position.x, ball.position.y, futureX, futureY, block);
                    }
                }
                if (block.type === "Multiply" &&
                    !this.ballToVisitedBlocks.get(ball.id)?.has(block) &&
                    collisionDetected) {
                    // Mark this block as visited for this ball
                    const visitedBlocks = this.ballToVisitedBlocks.get(ball.id);
                    if (visitedBlocks) {
                        visitedBlocks.add(block);
                    }
                    else {
                        this.ballToVisitedBlocks.set(ball.id, new Set([block]));
                    }
                    this.handleMultiplication(ball, block);
                    shouldContinue = false;
                }
                else if (block.type === "Plus" && collisionDetected) {
                    console.log("Found Plus block in collision check, ball id:", ball.id, "collision detected:", collisionDetected);
                    this.handlePlusBlock(ball, block);
                    // Remove the Plus block after it's hit by replacing it with an Empty block
                    block.type = "Empty";
                    block.value = 0;
                    console.log("Plus block set to empty in checkRibbonCollisions");
                    shouldContinue = false;
                }
                else if (block.type === "Remove" && collisionDetected) {
                    block.counter--;
                    block.hitAnimTimer = 10;
                    World.remove(this.engine.world, ball);
                    // Clean up the map when the ball is removed
                    this.ballToVisitedBlocks.delete(ball.id);
                    this.balls = this.balls.filter(b => b !== ball);
                    this.drawRemoveEffect(ball.position.x, ball.position.y);
                    if (block.counter <= 0) {
                        const newBlock = new Block((block.bounds.min.x + block.bounds.max.x) / 2, (block.bounds.min.y + block.bounds.max.y) / 2, block.bounds.max.x - block.bounds.min.x, block.bounds.max.y - block.bounds.min.y, "Empty");
                        if (this.blocks[laneIndex]) {
                            this.blocks[laneIndex][blockIndex] = newBlock;
                        }
                    }
                    shouldContinue = false;
                }
            });
        });
    }
    lineSegmentIntersectsRibbon(x1, y1, x2, y2, block) {
        if (block.type !== "Multiply" && block.type !== "Remove")
            return false;
        const ribbonHeight = (block.bounds.max.y - block.bounds.min.y) / 3;
        const ribbonY = (block.bounds.max.y + block.bounds.min.y) / 2 - ribbonHeight / 2;
        const ribbonTop = ribbonY;
        const ribbonBottom = ribbonY + ribbonHeight;
        const ribbonLeft = block.bounds.min.x;
        const ribbonRight = block.bounds.max.x;
        if (Math.abs(x2 - x1) < 0.0001) {
            const minY = Math.min(y1, y2);
            const maxY = Math.max(y1, y2);
            return x1 >= ribbonLeft && x1 <= ribbonRight && minY <= ribbonBottom && maxY >= ribbonTop;
        }
        const xAtTop = x1 + (x2 - x1) * (ribbonTop - y1) / (y2 - y1);
        const xAtBottom = x1 + (x2 - x1) * (ribbonBottom - y1) / (y2 - y1);
        if ((xAtTop >= ribbonLeft && xAtTop <= ribbonRight && ribbonTop >= Math.min(y1, y2) && ribbonTop <= Math.max(y1, y2)) ||
            (xAtBottom >= ribbonLeft && xAtBottom <= ribbonRight && ribbonBottom >= Math.min(y1, y2) && ribbonBottom <= Math.max(y1, y2))) {
            return true;
        }
        if (Math.abs(y2 - y1) < 0.0001) {
            const minX = Math.min(x1, x2);
            const maxX = Math.max(x1, x2);
            return y1 >= ribbonTop && y1 <= ribbonBottom && minX <= ribbonRight && maxX >= ribbonLeft;
        }
        const yAtLeft = y1 + (y2 - y1) * (ribbonLeft - x1) / (x2 - x1);
        const yAtRight = y1 + (y2 - y1) * (ribbonRight - x1) / (x2 - x1);
        return (yAtLeft >= ribbonTop && yAtLeft <= ribbonBottom && ribbonLeft >= Math.min(x1, x2) && ribbonLeft <= Math.max(x1, x2)) ||
            (yAtRight >= ribbonTop && yAtRight <= ribbonBottom && ribbonRight >= Math.min(x1, x2) && ribbonRight <= Math.max(x1, x2));
    }
    handleMultiplication(ball, block) {
        // Create (value - 1) new balls for the multiply block
        // e.g., x2 creates 1 new ball, x3 creates 2 new balls, etc.
        const newBallsToCreate = block.value - 1;
        // Mark this block as visited for the original ball
        const visitedBlocks = this.ballToVisitedBlocks.get(ball.id);
        if (visitedBlocks) {
            visitedBlocks.add(block);
        }
        else {
            console.warn("Ball ID=" + ball.id + " missing from ballToVisitedBlocks map");
            this.ballToVisitedBlocks.set(ball.id, new Set([block]));
        }
        // Create the new balls based on the multiply value
        for (let i = 0; i < newBallsToCreate; i++) {
            // Add position offset for the new ball (half a ball's width in random direction)
            const positionOffsetX = (Math.random() - 0.5) * this.BALL_RADIUS;
            const positionOffsetY = (Math.random() - 0.5) * this.BALL_RADIUS;
            const newBall = Bodies.circle(ball.position.x + positionOffsetX, ball.position.y + positionOffsetY, this.BALL_RADIUS, {
                restitution: PhysicsGame.GLOBAL_BOUNCE,
                friction: PhysicsGame.GLOBAL_FRICTION,
                render: {
                    fillStyle: '#e74c3c'
                }
            });
            newBall.label = 'ball';
            newBall.id = Math.floor(Math.random() * 1000000);
            // Create a new set for the new ball with the current block already visited
            this.ballToVisitedBlocks.set(newBall.id, new Set([block]));
            // Set velocity to half of the original ball's velocity
            const halfVelocity = {
                x: ball.velocity.x * 0.5,
                y: ball.velocity.y * 0.5
            };
            Body.setVelocity(newBall, halfVelocity);
            World.add(this.engine.world, newBall);
            this.balls.push(newBall);
        }
        this.drawMultiplyEffect(ball.position.x, ball.position.y, block.value);
    }
    handlePlusBlock(ball, block) {
        console.log("handlePlusBlock called with ball id:", ball.id, "and plus value:", block.value);
        // Create the specified number of new balls (block.value)
        const newBallsToCreate = block.value;
        // Create the new balls
        for (let i = 0; i < newBallsToCreate; i++) {
            // Add position offset for the new ball (half a ball's width in random direction)
            const positionOffsetX = (Math.random() - 0.5) * this.BALL_RADIUS;
            const positionOffsetY = (Math.random() - 0.5) * this.BALL_RADIUS;
            const newBall = Bodies.circle(ball.position.x + positionOffsetX, ball.position.y + positionOffsetY, this.BALL_RADIUS, {
                restitution: PhysicsGame.GLOBAL_BOUNCE,
                friction: PhysicsGame.GLOBAL_FRICTION,
                render: {
                    fillStyle: '#e74c3c'
                }
            });
            newBall.label = 'ball';
            newBall.id = Math.floor(Math.random() * 1000000);
            // Create a new set for the new ball
            this.ballToVisitedBlocks.set(newBall.id, new Set());
            // Set velocity to half of the original ball's velocity but in random directions
            const angle = Math.random() * Math.PI * 2;
            const speed = Math.sqrt(ball.velocity.x * ball.velocity.x + ball.velocity.y * ball.velocity.y) * 0.5;
            const newVelocity = {
                x: Math.cos(angle) * speed,
                y: Math.sin(angle) * speed
            };
            Body.setVelocity(newBall, newVelocity);
            World.add(this.engine.world, newBall);
            this.balls.push(newBall);
            console.log("Created new ball from Plus block, id:", newBall.id);
        }
        // Draw the effect
        this.drawPlusEffect(ball.position.x, ball.position.y, block.value);
        console.log("Drew Plus effect");
    }
    endGame() {
        // Set game over state
        this.gameOver = true;
        // Store the final score (total balls collected across all levels)
        // The initialBallCount for the next level would have been set to the total
        // balls collected so far, so it represents our final score
        this.finalScore = this.initialBallCount;
        // Clear any remaining balls
        for (const ball of [...this.balls]) {
            World.remove(this.engine.world, ball);
        }
        this.balls = [];
        // Clear the visited blocks map
        this.ballToVisitedBlocks.clear();
        // Set up game over message
        this.levelCompleteMessage = "Game Over!\nFinal Score: " + this.finalScore;
        this.levelCompleteTimer = this.LEVEL_COMPLETE_MESSAGE_DURATION * 2; // Display for longer
        // Stop the spawning
        this.spawnActive = false;
    }
    restartGame() {
        // Reset game state
        this.gameOver = false;
        this.finalScore = 0;
        this.currentLevel = 0; // Will be incremented to 1 in startNextLevel
        // Remove all blocks and walls
        this.clearExistingBlocks();
        // Start a new game at level 1
        this.startNextLevel();
    }
    createChevronWall(block, laneIndex, blockIndex) {
        // First, make sure we clean up any existing walls to prevent duplicates
        if (block.diagonalWall) {
            World.remove(this.engine.world, block.diagonalWall);
            block.diagonalWall = null;
        }
        if (block.secondaryDiagonalWall) {
            World.remove(this.engine.world, block.secondaryDiagonalWall);
            block.secondaryDiagonalWall = null;
        }
        // For chevron blocks, we don't need direction but for consistency with diagonal blocks
        // we'll set a default value
        block.diagonalDirection = 'leftToRight'; // Direction doesn't matter for chevrons
        if (!block.bounds ||
            typeof block.bounds.min?.x !== 'number' ||
            typeof block.bounds.min?.y !== 'number' ||
            typeof block.bounds.max?.x !== 'number' ||
            typeof block.bounds.max?.y !== 'number') {
            throw Error("Block bounds not properly defined");
        }
        const minX = block.bounds.min.x;
        const minY = block.bounds.min.y;
        const maxX = block.bounds.max.x;
        const maxY = block.bounds.max.y;
        const centerX = (minX + maxX) / 2;
        const centerY = (minY + maxY) / 2;
        const width = maxX - minX;
        const height = maxY - minY;
        // Calculate points for the chevron (^) shape
        // Lower the peak point to make the chevron less steep - move from 30% to 50% from the top
        const peakY = minY + height * 0.5; // Peak is at 50% from the top (middle of the block)
        const leftBaseX = minX;
        const rightBaseX = maxX;
        const baseY = maxY;
        // Thickness for both arms
        const thickness = this.WALL_THICKNESS * 1.5;
        // Calculate chevron left side - using proper perpendicular calculation for a 45-degree rectangle
        const leftDiagonalLength = Math.sqrt(Math.pow(centerX - leftBaseX, 2) + Math.pow(peakY - baseY, 2));
        const leftDiagonalAngle = Math.atan2(peakY - baseY, centerX - leftBaseX);
        // Calculate perpendicular vectors to create proper rectangle
        const perpAngle = leftDiagonalAngle + Math.PI / 2; // 90 degrees (perpendicular) to diagonal
        const perpDx = (thickness / 2) * Math.cos(perpAngle);
        const perpDy = (thickness / 2) * Math.sin(perpAngle);
        // Create corners of the left arm as a proper rotated rectangle
        const leftVertices = [
            { x: leftBaseX + perpDx, y: baseY + perpDy }, // Bottom left corner
            { x: leftBaseX - perpDx, y: baseY - perpDy }, // Bottom right corner
            { x: centerX - perpDx, y: peakY - perpDy }, // Top right corner
            { x: centerX + perpDx, y: peakY + perpDy } // Top left corner
        ];
        // Calculate chevron right side - using similar approach
        const rightDiagonalLength = Math.sqrt(Math.pow(rightBaseX - centerX, 2) + Math.pow(baseY - peakY, 2));
        const rightDiagonalAngle = Math.atan2(baseY - peakY, rightBaseX - centerX);
        // Perpendicular vectors for right arm
        const rightPerpAngle = rightDiagonalAngle + Math.PI / 2;
        const rightPerpDx = (thickness / 2) * Math.cos(rightPerpAngle);
        const rightPerpDy = (thickness / 2) * Math.sin(rightPerpAngle);
        // Create corners of the right arm as a proper rotated rectangle
        const rightVertices = [
            { x: centerX + rightPerpDx, y: peakY + rightPerpDy }, // Bottom left corner
            { x: centerX - rightPerpDx, y: peakY - rightPerpDy }, // Bottom right corner
            { x: rightBaseX - rightPerpDx, y: baseY - rightPerpDy }, // Top right corner
            { x: rightBaseX + rightPerpDx, y: baseY + rightPerpDy } // Top left corner
        ];
        // Remove walls on both sides
        this.removeWallSegment(laneIndex, blockIndex);
        if (laneIndex > 0) {
            this.removeWallSegment(laneIndex, blockIndex);
        }
        if (laneIndex < this.LANE_COUNT - 1) {
            this.removeWallSegment(laneIndex + 1, blockIndex);
        }
        // Create left side of chevron
        const leftDiagonalBody = Bodies.fromVertices((leftBaseX + centerX) / 2, (baseY + peakY) / 2, [leftVertices], {
            isStatic: true,
            render: {
                fillStyle: '#95a5a6'
            }
        });
        // Create right side of chevron
        const rightDiagonalBody = Bodies.fromVertices((rightBaseX + centerX) / 2, (baseY + peakY) / 2, [rightVertices], {
            isStatic: true,
            render: {
                fillStyle: '#95a5a6'
            }
        });
        // Store unique labels for both arms to identify them
        leftDiagonalBody.label = 'chevronWallLeft_' + laneIndex + '_' + blockIndex;
        rightDiagonalBody.label = 'chevronWallRight_' + laneIndex + '_' + blockIndex;
        // Store both bodies in the block for proper tracking and cleanup
        block.diagonalWall = leftDiagonalBody;
        block.secondaryDiagonalWall = rightDiagonalBody;
        // Add both arms to the world
        World.add(this.engine.world, [leftDiagonalBody, rightDiagonalBody]);
    }
    drawChevronForBlock(block, ctx) {
        if (block.type !== "Chevron" || !block.bounds) {
            return;
        }
        const minX = block.bounds.min.x;
        const minY = block.bounds.min.y;
        const maxX = block.bounds.max.x;
        const maxY = block.bounds.max.y;
        const centerX = (minX + maxX) / 2;
        const peakY = minY + (maxY - minY) * 0.5; // Peak is at 50% from the top (middle of the block)
        if (!block.diagonalWall) {
            ctx.save();
            ctx.strokeStyle = '#95a5a6';
            // Use consistent thickness for both sides
            const thickness = this.DIAGONAL_THICKNESS * 1.5;
            ctx.lineWidth = thickness;
            // Draw both sides of the chevron
            ctx.beginPath();
            // Left arm
            ctx.moveTo(minX, maxY);
            ctx.lineTo(centerX, peakY);
            // Right arm
            ctx.moveTo(centerX, peakY);
            ctx.lineTo(maxX, maxY);
            ctx.stroke();
            ctx.restore();
        }
    }
    // Method to find and clean up any stray chevron arms
    cleanupStrayChevronArms() {
        // Get all bodies in the world
        const allBodies = Matter.Composite.allBodies(this.engine.world);
        // Track which chevron arms are actually attached to blocks
        const validChevronArmIds = new Set();
        // First, collect all valid chevron arm IDs from our blocks
        for (const laneArray of this.blocks) {
            if (!laneArray)
                continue;
            for (const block of laneArray) {
                if (!block)
                    continue;
                if (block.type === "Chevron") {
                    if (block.diagonalWall) {
                        validChevronArmIds.add(block.diagonalWall.id);
                    }
                    if (block.secondaryDiagonalWall) {
                        validChevronArmIds.add(block.secondaryDiagonalWall.id);
                    }
                }
            }
        }
        // Then find and remove any chevron arms that aren't in our valid set
        for (const body of allBodies) {
            if (body.label &&
                (body.label.startsWith('chevronWallLeft_') || body.label.startsWith('chevronWallRight_')) &&
                !validChevronArmIds.has(body.id)) {
                // This is a stray chevron arm, remove it
                World.remove(this.engine.world, body);
                console.log("Removed stray chevron arm:", body.label);
            }
        }
    }
}`)

type blockType = Empty | Multiply | Remove | Diagonal | Plus | Chevron
// todo, is there any way to make this type safe? maybe a few selected colors and then hashtag colors?
type cssColor = string

let getFillStyle = (blockType: blockType): cssColor => {
  switch blockType {
  | Multiply
  | Remove
  | Plus
  | Empty => "transparent"
  | Diagonal
  | Chevron => "#f1c40f"
  }
}

// todo option 1: return option<string>
// todo option 2: throw error
// todo option 3: change input type to color with properties instead of string
let blendColors = (color1: string, color2: string, factor: float): string => {
  let or1: option<int> = Int.fromString(String.substring(color1, ~start=1, ~end=3), ~radix=16)
  let og1: option<int> = Int.fromString(String.substring(color1, ~start=3, ~end=5), ~radix=16)
  let ob1: option<int> = Int.fromString(String.substring(color1, ~start=5, ~end=7), ~radix=16)
  let or2: option<int> = Int.fromString(String.substring(color2, ~start=1, ~end=3), ~radix=16)
  let og2: option<int> = Int.fromString(String.substring(color2, ~start=3, ~end=5), ~radix=16)
  let ob2: option<int> = Int.fromString(String.substring(color2, ~start=5, ~end=7), ~radix=16)

  let r1: int = switch or1 {
  | Some(r) => r
  | None => assert(false)
  }
  let g1: int = switch og1 {
  | Some(g) => g
  | None => assert(false)
  }
  let b1: int = switch ob1 {
  | Some(b) => b
  | None => assert(false)
  }
  let r2: int = switch or2 {
  | Some(r) => r
  | None => assert(false)
  }
  let g2: int = switch og2 {
  | Some(g) => g
  | None => assert(false)
  }
  let b2: int = switch ob2 {
  | Some(b) => b
  | None => assert(false)
  }

  let r: int = Int.fromFloat(
    Belt.Float.fromInt(r1) *. factor +. Belt.Float.fromInt(r2) *. (1. -. factor),
  )
  let g: int = Int.fromFloat(
    Belt.Float.fromInt(g1) *. factor +. Belt.Float.fromInt(g2) *. (1. -. factor),
  )
  let b: int = Int.fromFloat(
    Belt.Float.fromInt(b1) *. factor +. Belt.Float.fromInt(b2) *. (1. -. factor),
  )

  let returnval =
    "#" ++
    String.padStart(Int.toString(r, ~radix=16), 2, "0") ++
    String.padStart(Int.toString(g, ~radix=16), 2, "0") ++
    String.padStart(Int.toString(b, ~radix=16), 2, "0")
  returnval
}

// todo: disable running tests in prod
// todo: put error in console if test fails
// todo: maybe use bun test runner instead
// shit create assertEquals function, and that throws an error with the expected and actual.
assert(blendColors("#FF0088", "#FF0088", 0.) == "#ff0088")
assert(blendColors("#000000", "#FF0088", 0.) == "#ff0088")
assert(blendColors("#000000", "#FF0088", 1.) == "#000000")
assert(blendColors("#000000", "#FF0088", 0.5) == "#7f0044")

type point = {x: int, y: int}
type bounds = {min: point, max: point}

type myContext = t

let drawRibbon2 = (ctx, bounds, blockType, value, hitAnimTimer, counter, setHitAnimTimer) => {
  let ribbonHeight = Belt.Float.fromInt(bounds.max.y - bounds.min.y) /. 3.
  let ribbonY = Belt.Float.fromInt(bounds.max.y + bounds.min.y) /. 2. -. ribbonHeight /. 2.
  let ribbonWidth = Belt.Float.fromInt(bounds.max.x - bounds.min.x)
  let centerX = Belt.Float.fromInt(bounds.min.x + bounds.max.x) /. 2.

  // shit, maybe extract ribbon drawing to a function
  switch blockType {
  | Multiply => {
      ctx->save
      ctx->setFillStyle(String, "rgba(39, 174, 96, 0.3)")
      ctx->fillRect(~x=Belt.Int.toFloat(bounds.min.x), ~y=ribbonY, ~w=ribbonWidth, ~h=ribbonHeight)
      ctx->setFillStyle(String, "#27ae60")
      ctx->font("bold 20px Arial")
      ctx->textAlign("center")
      ctx->textBaseline("middle")
      ctx->fillText("x" ++ value, ~x=centerX, ~y=ribbonY +. ribbonHeight /. 2., ())
      ctx->restore
    }
  | Plus => {
      ctx->save

      // Green-yellowish hue for Plus blocks
      ctx->setFillStyle(String, "rgba(160, 200, 60, 0.3)")
      ctx->fillRect(~x=Belt.Int.toFloat(bounds.min.x), ~y=ribbonY, ~w=ribbonWidth, ~h=ribbonHeight)
      ctx->setFillStyle(String, "#9ACD32")
      ctx->font("bold 20px Arial")
      ctx->textAlign("center")
      ctx->textBaseline("middle")
      ctx->fillText("+" ++ value, ~x=centerX, ~y=ribbonY +. ribbonHeight /. 2., ())
      ctx->restore
    }
  | Remove => {
      // shit i think this is just a normal null check, and we should actually make hitAnimTimer not be nullable but just int.
      if hitAnimTimer === None {
        setHitAnimTimer(0)
      }

      let localHitAnimTimer = switch hitAnimTimer {
      | Some(h) => h
      | None => 0
      }

      // shit is it possible to encode this in the type system?
      if localHitAnimTimer < 0 {
        assert(false)
      }

      // shit :thinking: i'm not quite sure how to mutate this variable, and use "object oriented" in rescript.
      if localHitAnimTimer > 0 {
        setHitAnimTimer(localHitAnimTimer - 1)
      }

      ctx->save
      ctx->setFillStyle(String, "rgba(231, 76, 60, 0.3)")

      ctx->fillRect(~x=Belt.Int.toFloat(bounds.min.x), ~y=ribbonY, ~w=ribbonWidth, ~h=ribbonHeight)

      let pulseScale = 0.9 +. 0.1 *. (1. -. Belt.Float.fromInt(localHitAnimTimer) /. 10.)
      let yellowFactor: float = Belt.Float.fromInt(localHitAnimTimer) /. 10.
      let textColor = blendColors("#f1c40f", "#c0392b", yellowFactor)

      ctx->setFillStyle(String, textColor)

      ctx->font("bold " ++ Belt.Float.toString(24. *. pulseScale) ++ "px Arial")
      ctx->textAlign("center")
      ctx->textBaseline("middle")
      ctx->fillText("-" ++ counter, ~x=centerX, ~y=ribbonY +. ribbonHeight /. 2., ())
      ctx->restore
    }
  | Diagonal
  | Chevron
  | Empty => () // These do not have a ribbon
  }
}

// shit this should probably use the existing drawing logic for ribbons? think matter js has a sensors thing.
// shit also, the radius of the balls are not taken into account
let isPointInRibbon2 = (x, y, blockType, bounds) => {
  switch blockType {
  | Plus | Multiply | Remove => {
      let ribbonHeight = Belt.Float.fromInt(bounds.max.y - bounds.min.y) /. 3.

      let ribbonY = Belt.Float.fromInt(bounds.max.y + bounds.min.y) /. 2. -. ribbonHeight /. 2.

      let isInRibbon =
        x >= bounds.min.x && x <= bounds.max.x && y >= ribbonY && y <= ribbonY +. ribbonHeight

      isInRibbon
    }
  | Chevron | Diagonal | Empty => false
  }
}

let sum = myArray => {
  Array.reduce(myArray, 0, (prev, cur) => {prev + cur})
}

let randomWeighted = blockTypeWeights => {
  let weights = Belt.Array.map([...blockTypeWeights], v => {
    let (_, weight) = v
    weight
  })

  let totalWeight = Array.reduce(weights, 0, (prev, cur) => {prev + cur})
  // Console.log(totalWeight)

  let randomValue = Math.random() *. (totalWeight :> float)

  let myValue = ref(None)
  let cumulativeWeight = ref(0.)

  let _ = Array.forEachWithIndex(weights, (x, i) => {
    // Console.log6(x, i, weights2, myValue.contents, nextVal, randomValue)
    let nextVal = cumulativeWeight.contents +. (x :> float)
    if nextVal > randomValue && myValue.contents == None {
      myValue := Some(i)
    }
    cumulativeWeight := nextVal
  })

  switch myValue.contents {
  | Some(num) if num > weights->Array.length - 1 => assert(false)
  | Some(num) => num
  | None => weights->Array.length - 1
  }
}

let results =
  Array.make(~length=1000, 0)->Array.map(_v =>
    randomWeighted([(Empty, 3), (Multiply, 1), (Remove, 1), (Diagonal, 1), (Plus, 1), (Chevron, 3)])
  )
Console.log2(0, results->Array.filter(v => v == 0)->Array.length)
Console.log2(1, results->Array.filter(v => v == 1)->Array.length)
Console.log2(2, results->Array.filter(v => v == 2)->Array.length)
Console.log2(3, results->Array.filter(v => v == 3)->Array.length)
Console.log2(4, results->Array.filter(v => v == 4)->Array.length)
Console.log2(5, results->Array.filter(v => v == 5)->Array.length)
Console.log2("total", results->Array.length)

let getRandomBlockType2 = (currentLevel): blockType => {
  let blockTypeWeights = [
    (Empty, Math.Int.max(10 - currentLevel, 5)),
    (Multiply, Math.Int.min(6 + currentLevel / 2, 12)),
    (Remove, Math.Int.min(5 + currentLevel / 3, 9)),
    (Diagonal, Math.Int.min(6 + currentLevel, 12)),
    (Plus, Math.Int.min(5 + currentLevel / 2, 10)),
    (Chevron, Math.Int.min(4 + currentLevel / 2, 8)),
  ]

  let index = randomWeighted(blockTypeWeights)
  switch blockTypeWeights[index] {
  | Some(returnBlockType, _weight) => returnBlockType
  | None => assert(false)
  }
}

let drawRemoveEffect2 = (x, y, context, ballRadius) => {
  let ctx = context
  ctx->save
  ctx->setStrokeStyle(String, "#f1c40f")
  ctx->lineWidth(2.)
  ctx->beginPath
  ctx->arc(~x, ~y, ~r=ballRadius, ~startAngle=0., ~endAngle=Math.Constants.pi *. 2., ())
  ctx->stroke
  ctx->restore
}

let drawPlusEffect2 = (x, y, value, context, ballRadius) => {
  let ctx = context
  ctx->save
  ctx->setStrokeStyle(String, "#9ACD32")
  ctx->lineWidth(2.)
  ctx->beginPath
  ctx->arc(~x, ~y, ~r=ballRadius, ~startAngle=0., ~endAngle=Math.Constants.pi *. 2., ())
  ctx->stroke
  ctx->setFillStyle(String, "#9ACD32")
  ctx->font("bold 20px Arial")
  ctx->textAlign("center")
  ctx->textBaseline("middle")
  ctx->fillText("+" ++ value, ~x, ~y, ())
  ctx->restore
}

let drawMultiplyEffect2 = (x, y, value, context, ballRadius) => {
  let ctx = context
  ctx->save
  ctx->setStrokeStyle(String, "#27ae60")
  ctx->lineWidth(2.)
  ctx->beginPath
  ctx->arc(~x, ~y, ~r=ballRadius *. 2., ~startAngle=0., ~endAngle=Math.Constants.pi *. 2., ())
  ctx->stroke
  ctx->setFillStyle(String, "#27ae60")
  ctx->font("bold 20px Arial")
  ctx->textAlign("center")
  ctx->textBaseline("middle")
  ctx->fillText("x" ++ value, ~x, ~y, ())
  ctx->restore
}

// ---------------------------------------------

@new external physicsGame: unit => unit = "PhysicsGame"

// shit migrate to use webapi
@val external window: 'a = "window"

if Type.typeof(window) == #object {
  window["onload"] = () => {
    physicsGame()
  }
}
