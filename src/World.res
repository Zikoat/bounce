type world
type composite
type constraintType
type mouseConstraint

@val external create: {..} => world = "Matter.World.create"

@val external add: (world, Bodies.body) => world = "Matter.World.add"

@val external addBody: (world, Bodies.body) => world = "Matter.World.addBody"

@val external addComposite: (world, composite) => world = "Matter.World.addComposite"

@val external addConstraint: (world, constraintType) => world = "Matter.World.addConstraint"

@val external clear: (world, bool) => unit = "Matter.World.clear"

@val external remove: (world, Bodies.body) => world = "Matter.World.remove"
