module Tipos
( Point
, Vector
, Angle
, Distance
, Position
, Size
, Speed
, Health
, Direction
, Range
, Damage
, Time
, Body(..)
, Turret(..)
, Tank(..)
, Projectile(..)
, Move(..)
, Battleground(..)
, MemoryValue(..)
, Memory
, BotAction(..)
) where

module Memoria
( emptyMemory
, remember
, recall
, forget
, rememberTank
, recallTank
) where

module Fisica
( centerOf
, distanceBetween
, distanceBetweenTanks
, angleToTarget
, angleBetweenTanks
, sub
, dot
, deg2rad
, rad2deg
, subVec
, perp
, getVertices
, rotarTanque
, isInBounds
, modulo
, unitario
, detectedAgent
, isRobotAlive
, countActiveRobots
, mul
) where

module IA
( decideActions
) where

module Comportamiento
( updateRobotVelocity
, updateVelocity
, updatePosition
) where

module Colisiones
( checkCollision
, detectRobotProjectileCollisions
, detectRobotRobotCollisions
, checkCollisions
) where

import Data.Time (NominalDiffTime)

-- ###############TIPOS##############################

type Point = (Double, Double)
type Vector = (Double, Double)
type Angle = Double
type Distance = Double
type Position = Point
type Size = (Double, Double)
type Speed = Double
type Health = Double
type Direction = Vector
type Range = Double
type Damage = Double
type Time = NominalDiffTime
type TankObject = GameObject Tank
type ProjectileObject = GameObject Projectile
type Memory = [(String, MemoryValue)]

-- GameObject
data GameObject a = GameObject
  { goPosition :: Position     
  , goVelocity :: Vector      
  , goSize     :: Size        
  , goHealth   :: Maybe Health 
  , goExtra    :: a            
  } deriving (Show, Eq)
  
-- Cuerpo del tanque
data Body = Body
  { bodyCorners :: [Position]
  } deriving (Show, Eq)

--Torreta del tanque
data Turret = Turret
  { turretDirection :: Direction
  , turretCooldown  :: Time
  } deriving (Show, Eq)

-- Tanque
data Tank = Tank
  { tankBody   :: Body
  , tankTurret :: Turret
  , tankRange  :: Range
  , tankMemory :: Memory      -- NUEVO CAMPO: memoria del tanque
  } deriving (Show, Eq)

-- Proyectil
data Projectile = Projectile
  { projectileDirection :: Direction
  , projectileDamage    :: Damage
  } deriving (Show, Eq)

-- Movimiento
data Move
  = Idle
  | SetVelocity Vector
  | Accelerate Vector
  deriving (Show, Eq)

-- Campo de batalla
data Battleground = Battleground
  { bgWidth  :: Distance
  , bgHeight :: Distance
  } deriving (Show, Eq)

-- Memoria:

data MemoryValue
  = MemInt Int
  | MemDouble Double
  | MemString String
  | MemBool Bool
  | MemPoint Point
  deriving (Show, Eq)

data BotAction
  = MoveTank Vector          -- moverse en una dirección
  | RotateTurret Angle       -- rotar la torreta
  | Shoot                    -- disparar
  | Remember String MemoryValue  -- guardar algo en memoria
  | DoNothing                -- no hacer nada
  deriving (Show, Eq)


-- ###################### MEMORIA #######################
  -- Crear memoria vacía
emptyMemory :: Memory
emptyMemory = []

-- Guardar o actualizar un valor
remember :: String -> MemoryValue -> Memory -> Memory
remember key val mem =
  (key, val) : filter ((/= key) . fst) mem

-- Recuperar un valor (si existe)
recall :: String -> Memory -> Maybe MemoryValue
recall key mem = lookup key mem

-- Eliminar una clave
forget :: String -> Memory -> Memory
forget key mem = filter ((/= key) . fst) mem

-- Asignar un nuevo valor en la memoria del tanque
rememberTank :: Tank -> String -> MemoryValue -> Tank
rememberTank tank key val =
  tank { tankMemory = remember key val (tankMemory tank) }

-- Consultar un valor de la memoria del tanque
recallTank :: Tank -> String -> Maybe MemoryValue
recallTank tank key = recall key (tankMemory tank)

-- ##################################FISICA#############################

-- Recibe el cuerpo de un tanque y calcula el centro del mismo, muy útil para diversas operaciones posteriores
centerOf :: Body -> Position
centerOf (Body corners _) =
  let (sx, sy, n) = foldr (\(x, y) (ax, ay, c) -> (ax + x, ay + y, c + 1)) (0,0,0) corners
  in (sx / fromIntegral n, sy / fromIntegral n)

-- Calcula la distacia entre dos puntos, función auxiliar de ditanceBetweenTanks
distanceBetween :: Position -> Position -> Distance
distanceBetween (x1, y1) (x2, y2) = sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

-- Dados dos tanques y aprovechandonos de las 2 funciones anteriores calculamos la distancia entre ellos
distanceBetweenTanks :: Tank -> Tank -> Distance
distanceBetweenTanks t1 t2 = distanceBetween (centerOf (tankBody t1)) (centerOf (tankBody t2))

-- Dados dos puntos se calcula el ángulo entre ellos
angleToTarget :: Position -> Position -> Angle
angleToTarget (x1, y1) (x2, y2) = atan2 (y2 - y1) (x2 - x1)

-- Con ayuda de la función anterior y del centro de los tanque se calcula el ángulo entre los tanques
angleBetweenTanks :: Tank -> Tank -> Angle
angleBetweenTanks t1 t2 = angleToTarget (centerOf (tankBody t1)) (centerOf (tankBody t2))

-- Resta de puntos
sub :: Point -> Point -> Point
sub (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- módulo de 2 puntos
dot :: Point -> Point -> Double
dot (x1, y1) (x2, y2) = x1 * x2 + y1 * y2

-- Para convertir de grados a radianes
deg2rad :: Angle -> Angle
deg2rad degrees = degrees * pi / 180

-- Para convertir de radianes a grados
rad2deg :: Angle -> Angle
rad2deg radians = radians * 180 / pi

-- Resta de vectores
subVec :: Vector -> Vector -> Vector
subVec (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- Dado un vector obtenemos su perpendicular
perp :: Vector -> Vector
perp (x, y) = (-y, x)

-- Rotamos todos los vértices, sirve para rotar el tanque
getVertices :: (Point, Point, Point, Point, Angle) -> [Point]
getVertices (p1, p2, p3, p4, a) = map rotar [p1, p2, p3, p4]
  where
    rotar (x,y) = (x * cos a - y * sin a, x * sin a + y * cos a)

-- rotar el tanque ayudandose de la funcion anterior
rotarTanque :: Body -> Angle -> Body
rotarTanque body angle =
  body { bodyCorners = getVertices (c1, c2, c3, c4, angle) }
  where [c1, c2, c3, c4] = bodyCorners body

-- Comprueba que un punto esta dentro de un area
isInBounds :: Point -> Size -> Bool
isInBounds (x, y) (width, height) = x >= 0 && x <= width && y >= 0 && y <= height

-- modulo de un vector
modulo :: Vector -> Double
modulo (x, y) = sqrt (x^2 + y^2)

-- dado un vector calcular su unitario
unitario :: Vector -> Vector
unitario (0,0) = (0,0)
unitario v@(x, y) = (x / m, y / m)
  where m = modulo v

-- Dados 2 tanques, devuelve true si el primer tanque tiene dentro de su rango al segundo
detectedAgent :: Tank -> Tank -> Bool
detectedAgent t1 t2 = distanceBetweenTanks t1 t2 <= tankRange t1

-- Para saber si el bot está vivo
isRobotAlive :: Tank -> Bool
isRobotAlive t = tankHealth t > 0

-- Nos ayudamos de la función anterior para saber cuantos bots vivos quedan
countActiveRobots :: [Tank] -> Int
countActiveRobots ts = length (filter isRobotAlive ts)

-- multiplicacion de vectores
mul :: Vector -> Vector -> Vector
mul (w, h) (sw, sh) = (w * sw, h * sh)

-- ##############################IA############################

-- decideActions: dado un tanque y el estado del juego, devuelve una lista de acciones
decideActions :: Tank -> [Tank] -> [Projectile] -> [BotAction]
decideActions tank tanks projectiles
  | any (detectedAgent tank) (filter (/= tank) tanks)
    = [Remember "enemigoDetectado" (MemBool True), Shoot]
  | otherwise
    = [MoveTank (1, 0), DoNothing]

-- ############################COMPORTAMIENTO#######################

-- Función para modificar la velocidad de un tanque
updateRobotVelocity :: Tank -> Vector -> Tank
updateRobotVelocity tank v =
  tank { tankBody = (tankBody tank) { bodyVelocity = v } }

-- Función para que el tanque se mueva
updateVelocity :: Tank -> Move -> Tank
updateVelocity t Idle = t
updateVelocity t (SetVelocity v) =
  t { tankBody = (tankBody t) { bodyVelocity = v } }
updateVelocity t (Accelerate (dx,dy)) =
  let (vx,vy) = bodyVelocity (tankBody t)
  in t { tankBody = (tankBody t) { bodyVelocity = (vx + dx, vy + dy) } }

-- Función para actualizar la posición del tanque
updatePosition :: Tank -> Double -> Tank
updatePosition t dt =
  let b        = tankBody t
      (vx,vy)  = bodyVelocity b
      moved    = [ (x + vx * dt, y + vy * dt) | (x,y) <- bodyCorners b ]
  in t { tankBody = b { bodyCorners = moved } }

  -- ###########################COLISIONES###############################

  -- Comprueba si hay colision dada la posicion de 2 tanques
checkCollision :: [Point] -> [Point] -> Bool
checkCollision rect1 rect2 = 
  let axes = getAxes rect1 ++ getAxes rect2
  in all (not . isAxisSeparating rect1 rect2) axes

-- Calculo de los ejes de proyección de los vértices para implementar el algoritmo SAT
getAxes :: [Point] -> [Vector]
getAxes [] = []
getAxes [_] = []
getAxes points = map (normalize . perp . getEdge) edges
  where
    edges = zip points (tail points ++ [head points])
    getEdge ((x1, y1), (x2, y2)) = (x2 - x1, y2 - y1)
    normalize v@(x, y)
      | modulo v == 0 = (0, 0)
      | otherwise = (x / modulo v, y / modulo v)

-- Función para ver si las proyecciones están en contacto, si alguna de las proyecciones no está en contacto,
-- entonces los bots no estaran en contacto
isAxisSeparating :: [Point] -> [Point] -> Vector -> Bool
isAxisSeparating rect1 rect2 axis =
  let proj1 = projectToAxis rect1 axis
      proj2 = projectToAxis rect2 axis
  in not (projectOverlap proj1 proj2)

-- Proyecta los ejes de un polígono sobre un eje
projectToAxis :: [Point] -> Vector -> (Double, Double)
projectToAxis points axis =
  let projections = map (`dot` axis) points
  in (minimum projections, maximum projections)

-- Con las funciones anteriores, hemos calculado un rango, si esos rangos se solapan hay colisión y devuelve true
projectOverlap :: (Double, Double) -> (Double, Double) -> Bool
projectOverlap (min1, max1) (min2, max2) = min1 <= max2 && min2 <= max1

-- Función para saber si un proyectil ha alcanzado un bot
detectRobotProjectileCollisions :: [Tank] -> [Projectile] -> [(Tank, Projectile)]
detectRobotProjectileCollisions tanks projectiles = 
  [(tank, proj) | tank <- tanks, proj <- projectiles, 
   checkCollision (bodyCorners (tankBody tank)) (projectileCorners proj)]

-- Se detectan las colisiones entre los bot
detectRobotRobotCollisions :: [Tank] -> [(Tank, Tank)]
detectRobotRobotCollisions tanks = 
  [(t1, t2) | (t1:rest) <- tails tanks, t2 <- rest,
   checkCollision (bodyCorners (tankBody t1)) (bodyCorners (tankBody t2))]

-- Función que nos dice todas las colisiones que ha habido
checkCollisions :: [Tank] -> [Projectile] -> ([(Tank, Tank)], [(Tank, Projectile)])
checkCollisions tanks projectiles = 
  (detectRobotRobotCollisions tanks, detectRobotProjectileCollisions tanks projectiles)
