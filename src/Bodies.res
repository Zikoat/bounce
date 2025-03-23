type vector = {x: float, y: float}

type bounds = {
  min: vector,
  max: vector,
}

type collisionFilter = {
  category: int,
  mask: int,
  group: int,
}

type spriteOptions = {
  texture?: string,
  xScale?: float,
  yScale?: float,
}

type renderOptions = {
  visible?: bool,
  opacity?: float,
  sprite?: spriteOptions,
  lineWidth?: float,
  fillStyle?: string,
  strokeStyle?: string,
}

type pluginOptions = {
  name: string,
  version: string,
  install: option<unit => unit>,
  uninstall: option<unit => unit>,
}

type rec body = {
  angle: float,
  angularSpeed: float,
  angularVelocity: float,
  area: float,
  axes: array<vector>,
  bounds: bounds,
  circleRadius: option<float>,
  density: float,
  force: vector,
  friction: float,
  frictionAir: float,
  frictionStatic: float,
  id: int,
  inertia: float,
  inverseInertia: float,
  inverseMass: float,
  isSleeping: bool,
  isStatic: bool,
  isSensor: bool,
  mutable label: string,
  mass: float,
  motion: float,
  position: vector,
  render: renderOptions,
  restitution: float,
  sleepThreshold: float,
  slop: float,
  speed: float,
  timeScale: float,
  torque: float,
  type_: string,
  velocity: vector,
  vertices: array<vector>,
  parts: array<body>,
  parent: body,
  plugin: pluginOptions,
  collisionFilter: collisionFilter,
}

type bodyDefinition = {
  isStatic?: bool,
  isSensor?: bool,
  isSleeping?: bool,
  mass?: float,
  inertia?: float,
  render?: renderOptions,
}

type chamferOptions = {
  radius: float,
  quality: float,
  qualityMin: float,
  qualityMax: float,
}

type chamferableBodyDefinition = {
  chamfer?: chamferOptions,
  isStatic?: bool,
  isSensor?: bool,
  isSleeping?: bool,
  mass?: float,
  inertia?: float,
  render?: renderOptions,
}

@val
external circle: (
  ~x: float,
  ~y: float,
  ~radius: float,
  ~options: bodyDefinition=?,
  ~maxSides: option<int>=?,
  unit,
) => body = "Matter.Bodies.circle"

@val
external polygon: (
  ~x: float,
  ~y: float,
  ~sides: int,
  ~radius: float,
  ~options: chamferableBodyDefinition=?,
  unit,
) => body = "Matter.Bodies.polygon"

@val
external rectangle: (
  ~x: float,
  ~y: float,
  ~width: float,
  ~height: float,
  ~options: chamferableBodyDefinition=?,
  unit,
) => body = "Matter.Bodies.rectangle"

@val
external trapezoid: (
  ~x: float,
  ~y: float,
  ~width: float,
  ~height: float,
  ~slope: float,
  ~options: chamferableBodyDefinition=?,
  unit,
) => body = "Matter.Bodies.trapezoid"

@val
external fromVertices: (
  ~x: float,
  ~y: float,
  ~vertexSets: array<array<vector>>,
  ~options: bodyDefinition=?,
  ~flagInternal: bool=?,
  ~removeCollinear: float=?,
  ~minimumArea: float=?,
  ~removeDuplicatePoints: float=?,
  unit,
) => body = "Matter.Bodies.fromVertices"

