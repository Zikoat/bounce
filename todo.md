the plan:
create a game like a shitty mobile ad game where there are balls coming down from the top, and you can choose where the balls go, and then there are numbers where they multiply or get removed, and then you have to get as many balls as possible.

sub-goals: 
* [x] control where the balls go
* [x] create 5 "lanes" where the balls can go down. between each lane there are vertical walls.
* [x] each lane is split into a few (maybe 5) blocks, where we can put some obstacle or powerup.
    * [x] add visual text to show block values/counters
    * [x] implement multiply block functionality (create new ball on collision)
    * [x] implement remove block counter system (count balls and remove block when satisfied)
    * [x] implement diagonal block physics (change ball trajectory)
* [x] one type of powerup is a "multiply by 2" where when one ball touches the powerup
* [x] obstacle: -x where the balls get removed, and there is a counter on it which says how many have been removed, and when it has been satisfied then it is removed.
* [x] diagonal block implementation:
    * [x] modify vertical walls to be segmented per block section rather than continuous
    * [x] create diagonal walls going from top-left to bottom-right or top-right to bottom-left of a block
    * [x] when a diagonal block is present, remove the vertical wall segments for that section
    * [x] fix linter errors and ensure proper physics for balls to bounce off diagonal surfaces
    * [x] make the diagonals gray instead of yellow
    * [x] remove walls on both sides of diagonal blocks (not just the side it points towards)
    * [x] increase diagonal thickness to make it more visible
    * [x] decrease the block height by adding a configurable constant
    * [x] remove the bottom wall and implement proper off-screen ball cleanup
        * [x] extend side walls down by one ball height past the screen
        * [x] add a trigger zone below the screen for ball cleanup
        * [x] ensure balls only despawn when truly off-screen
* [ ] game progression features:
    * [x] when starting a new level, place blocks randomly
    * [x] increase score when the balls despawn
    * [x] add score counter
    * [x] counter for how many balls are on the field right now
    * [x] limit of x balls that you can spawn from the top
    * [x] when all balls are used and no balls left on the screen, then continue to the next level
    * [x] start of next level includes the same amount of balls that you collected the previous level
    * [x] collect balls by making them touch the bottom and then despawn
    * [x] after 3 levels, stop the game and give the player his final score. start the game from the beginning.
    * [x] when there are many balls, then we should increase the rate at which the balls are spawned at the top, such that we at most use 1 minute to drop all the balls.
* [ ] UI and additional gameplay features:
    * [x] show current level indicator
    * [x] show level results, and a button where you can press to go to the next level. the button should have a 3 second slider, and when the time is out it automatically goes to the next level.
* [ ] block variations:
    * [x] multiply powerups can go up to 5, the amount is random
    * [ ] wide blocks, which span multiple blocks horizontally
    * [x] multiply powerups with random values (2, 3, 4, or 5)
    * [ ] 0.5 blocks, which only let a few of the balls pass through, and despawn others. despawns 1 every x, or passes through 1 every x, so the multiplier should say this. 
    * [ ] the same above, but with different multipliers
    * [ ] keys and locked blocks, where you need to take the key to open the locked block.
    * [ ] diagonals that span multiple horizontal blocks
    * [ ] walls can either be there or not
    * [ ] portals, where a ball which passes through, is teleported to the other block
    * [ ] random blocks, where you don't know what they do before you pass through them, and then revealing a different type of block
    * [ ] an "upgrade" block where you can increase the multiplier of another block, or delete a negative block.
    * [x] a "plus" block, where when you hit it, it gets removed and then it spawns x new balls.
    * [ ] wide blocks, where a block spans multiple horizontal lengths
    * [ ] "bounce" blocks, where a block bounces all the way back up to the top
    * [ ] "virus" blocks which infect a single ball and then the block is removed. that infected ball infect other balls it touches for more than 1 second, and when an infected ball has been alive for more than 10 seconds it dies.
    * [ ] "fire" blocks, than when you pick it up it will create a "fire upgrade" ball, if you collect that "fire upgrade" ball, it will make the first ball in the next level a "fire" ball, and that ball will despawn the first block it touches.
    * [ ] ^ blocks, which work the same as diagonals, but instead of going all the way diagonal, it is 2 small diagonals that meet in the middle, such that it will split the balls in 2 paths. in the same way as diagonals it should remove the walls on the left and right.
    * [ ] black hole, which is basically a remove block with infinite count. it destroys all balls which touch it.
    * [ ] big ball, where there is 1 big ball which acts like all the other balls. it should be big enough to pass through diagonals.
    * [ ] we could put a "limit" on the amount of balls you can create, and as such all extra balls are turned into "spirits" which are only score but cannot be spawned in the next level. then we can create a block which increases the maximum count of balls you can have.
* [ ] visual improvements:
    * [ ] add funnel at the bottom to collect balls
    * [ ] add particles and effects for block interactions
    * [ ] improve overall visual styling and animations
    * [ ] add sound effects
    * [ ] when balls spawn at the top, add an initial downwards velocity when they spawn so they  faster clear each other and dont spread out. could also spawn the next ball in a spot which isn't already used. 
    * [ ] add a bar which says how many balls there are left to spawn
* [ ] more gameplay:
    * [ ] after a level you can buy keys and chests, and these allow you to unlock more block types.
    * [ ] you can create a "deck" of upgrades based on the cards you have. a card has both a positive and a negative effect, which is randomly added. 