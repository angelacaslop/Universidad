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
, GameObject(..)
, TankObject
, ProjectileObject
, tankToObject
, projectileToObject
, getObjectPosition
, getObjectVelocity
, getObjectHealth
, getObjectSize
, updateObjectPosition
, updateObjectVelocity
, projectileCorners
, createExampleTank
, createExampleProjectile
) where

import Data.Time (NominalDiffTime)

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
  , bodyVelocity :: Vector
  } deriving (Show, Eq)

--Torreta del tanque
data Turret = Turret
  { turretDirection :: Direction
  , turretCooldown  :: Time
  } deriving (Show, Eq)

-- Tanque
data Tank = Tank
  { tankBody     :: Body
  , tankTurret   :: Turret
  , tankRange    :: Range
  , tankHealth   :: Health
  , tankMemory   :: Memory
  , tankPosition :: Position     -- Posición del tanque
  , tankSize     :: Size         -- Tamaño del tanque
  } deriving (Show, Eq)

-- Proyectil
data Projectile = Projectile
  { projectileDirection :: Direction
  , projectileDamage    :: Damage
  , projectilePosition  :: Position     -- Posición del proyectil
  , projectileSize      :: Size         -- Tamaño del proyectil
  , projectileVelocity  :: Vector       -- Velocidad del proyectil
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

-- ============================================================================
-- FUNCIONES DE GAMEOBJECT
-- ============================================================================

-- Convertir Tank a GameObject
tankToObject :: Tank -> GameObject Tank
tankToObject tank = GameObject
  { goPosition = tankPosition tank
  , goVelocity = bodyVelocity (tankBody tank)
  , goSize     = tankSize tank
  , goHealth   = Just (tankHealth tank)
  , goExtra    = tank
  }

-- Convertir Projectile a GameObject
projectileToObject :: Projectile -> GameObject Projectile
projectileToObject proj = GameObject
  { goPosition = projectilePosition proj
  , goVelocity = projectileVelocity proj
  , goSize     = projectileSize proj
  , goHealth   = Nothing  -- Los proyectiles no tienen salud
  , goExtra    = proj
  }

-- Funciones de acceso a GameObject
getObjectPosition :: GameObject a -> Position
getObjectPosition = goPosition

getObjectVelocity :: GameObject a -> Vector
getObjectVelocity = goVelocity

getObjectHealth :: GameObject a -> Maybe Health
getObjectHealth = goHealth

getObjectSize :: GameObject a -> Size
getObjectSize = goSize

-- Funciones de actualización de GameObject
updateObjectPosition :: GameObject a -> Position -> GameObject a
updateObjectPosition obj pos = obj { goPosition = pos }

updateObjectVelocity :: GameObject a -> Vector -> GameObject a
updateObjectVelocity obj vel = obj { goVelocity = vel }

-- Función para obtener las esquinas de un proyectil (como un pequeño rectángulo)
projectileCorners :: Projectile -> [Point]
projectileCorners proj = 
  let (x, y) = projectilePosition proj
      (w, h) = projectileSize proj
      halfW = w / 2
      halfH = h / 2
  in [(x - halfW, y - halfH), (x + halfW, y - halfH), 
      (x + halfW, y + halfH), (x - halfW, y + halfH)]

-- Funciones de ejemplo para crear objetos
createExampleTank :: Tank
createExampleTank = Tank
  { tankBody = Body [(0,0), (2,0), (2,1), (0,1)] (0,0)
  , tankTurret = Turret (1,0) 0
  , tankRange = 10.0
  , tankHealth = 100.0
  , tankMemory = []
  , tankPosition = (1.0, 0.5)
  , tankSize = (2.0, 1.0)
  }

createExampleProjectile :: Projectile
createExampleProjectile = Projectile
  { projectileDirection = (1, 0)
  , projectileDamage = 25.0
  , projectilePosition = (1.5, 0.5)
  , projectileSize = (0.2, 0.2)
  , projectileVelocity = (5.0, 0.0)
  }
