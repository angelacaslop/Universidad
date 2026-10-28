-- PRAGMA: Habilita la extensión DeriveFunctor de GHC
-- Sin esta extensión, tendríamos que escribir manualmente:
--   instance Functor GameObject where
--     fmap f (GameObject pos vel size health extra) = GameObject pos vel size health (f extra)
-- Con DeriveFunctor, GHC genera automáticamente esta instancia cuando escribimos "deriving Functor"
{-# LANGUAGE DeriveFunctor #-}

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
, BoundedPosition(..)
, GameAction(..)
, TimedTransform(..)
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
, translateTank
, combineGameObjects
, updatePositionApplicative
, applyMove
, checkBounds
, transformTanks
, combineEffects
, applyPhysics
, scaleVector
, combineMessages

) where

import Data.Time (NominalDiffTime)
-- Operador <|> para elegir la primera opción no-Nothing entre dos Maybe values
import Control.Applicative ((<|>))

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

data GameObject a = GameObject
  { goPosition :: Position     
  , goVelocity :: Vector      
  , goSize     :: Size        
  , goHealth   :: Maybe Health 
  , goExtra    :: a            
  } deriving (Show, Eq, Functor)

-- Applicative: combina posiciones, velocidades y aplica función
instance Applicative GameObject where
  pure x = GameObject (0,0) (0,0) (0,0) Nothing x
  
  (GameObject pos1 vel1 size1 health1 f) <*> (GameObject pos2 vel2 size2 health2 x) = 
    GameObject 
      (addPositions pos1 pos2)  -- Combinar posiciones
      (addVectors vel1 vel2)    -- Combinar velocidades
      (addSizes size1 size2)    -- Combinar tamaños
      (health1 <|> health2)     -- Combinar salud (primera no-Nothing)
      (f x)                     -- Aplicar función

-- FUNCIONES AUXILIARES PARA APPLICATIVE

addPositions :: Position -> Position -> Position
addPositions (x1, y1) (x2, y2) = (x1 + x2, y1 + y2)

addVectors :: Vector -> Vector -> Vector
addVectors (x1, y1) (x2, y2) = (x1 + x2, y1 + y2)

addSizes :: Size -> Size -> Size
addSizes (w1, h1) (w2, h2) = (w1 + w2, h1 + h2)




-- TIPOS DE DATOS DEL JUEGO

data Body = Body
  { bodyCorners :: [Position]
  , bodyVelocity :: Vector
  } deriving (Show, Eq)

data Turret = Turret
  { turretDirection :: Direction
  , turretCooldown  :: Time
  } deriving (Show, Eq)


data Tank = Tank
  { tankBody     :: Body
  , tankTurret   :: Turret
  , tankRange    :: Range
  , tankHealth   :: Health
  , tankMemory   :: Memory
  , tankPosition :: Position
  , tankSize     :: Size
  } deriving (Show, Eq)

data Projectile = Projectile
  { projectileDirection :: Direction
  , projectileDamage    :: Damage
  , projectilePosition  :: Position
  , projectileSize      :: Size
  , projectileVelocity  :: Vector
  } deriving (Show, Eq)

data Move
  = Idle
  | SetVelocity Vector
  | Accelerate Vector
  deriving (Show, Eq)

data Battleground = Battleground
  { bgWidth  :: Distance
  , bgHeight :: Distance
  } deriving (Show, Eq)

data MemoryValue
  = MemInt Int
  | MemDouble Double
  | MemString String
  | MemBool Bool
  | MemPoint Point
  deriving (Show, Eq)

data BotAction
  = MoveTank Vector
  | RotateTurret Angle
  | Shoot
  | Remember String MemoryValue
  | DoNothing
  deriving (Show, Eq)




-- TIPOS AUXILIARES CON FUNCTOR Y APPLICATIVE

-- Contenedor para posición que puede estar fuera de límites
data BoundedPosition a = BoundedPosition
  { bpValue :: a
  , bpInBounds :: Bool
  } deriving (Show, Eq, Functor)

instance Applicative BoundedPosition where
  pure x = BoundedPosition x True
  (BoundedPosition f bounds1) <*> (BoundedPosition x bounds2) = 
    BoundedPosition (f x) (bounds1 && bounds2)

-- Contenedor para acciones del juego
data GameAction a = GameAction
  { gaValue :: a
  , gaIsValid :: Bool
  , gaMessage :: String
  } deriving (Show, Eq, Functor)

instance Applicative GameAction where
  pure x = GameAction x True ""
  
  (GameAction f valid1 msg1) <*> (GameAction x valid2 msg2) = 
    GameAction 
      (f x) 
      (valid1 && valid2)
      (combineMessages msg1 msg2)

-- Contenedor para transformaciones con tiempo delta
data TimedTransform a = TimedTransform
  { ttValue :: a
  , ttDeltaTime :: Double
  } deriving (Show, Eq, Functor)

instance Applicative TimedTransform where
  pure :: a -> TimedTransform a
  pure x = TimedTransform x 1.0
  
  (<*>) :: TimedTransform (a -> b) -> TimedTransform a -> TimedTransform b
  (TimedTransform f dt1) <*> (TimedTransform x dt2) = 
    TimedTransform (f x) (dt1 * dt2)  -- Multiplicar delta times




-- FUNCIONES DEL SISTEMA GAMEOBJECT

tankToObject :: Tank -> GameObject Tank
tankToObject tank = GameObject
  { goPosition = tankPosition tank
  , goVelocity = bodyVelocity (tankBody tank)
  , goSize     = tankSize tank
  , goHealth   = Just (tankHealth tank)
  , goExtra    = tank
  }

projectileToObject :: Projectile -> GameObject Projectile
projectileToObject proj = GameObject
  { goPosition = projectilePosition proj
  , goVelocity = projectileVelocity proj
  , goSize     = projectileSize proj
  , goHealth   = Nothing
  , goExtra    = proj
  }

getObjectPosition :: GameObject a -> Position
getObjectPosition = goPosition

getObjectVelocity :: GameObject a -> Vector
getObjectVelocity = goVelocity

getObjectHealth :: GameObject a -> Maybe Health
getObjectHealth = goHealth

getObjectSize :: GameObject a -> Size
getObjectSize = goSize

updateObjectPosition :: GameObject a -> Position -> GameObject a
updateObjectPosition obj pos = obj { goPosition = pos }

updateObjectVelocity :: GameObject a -> Vector -> GameObject a
updateObjectVelocity obj vel = obj { goVelocity = vel }


projectileCorners :: Projectile -> [Point]
projectileCorners proj = 
  let (x, y) = projectilePosition proj
      (w, h) = projectileSize proj
      halfW = w / 2
      halfH = h / 2
  in [(x - halfW, y - halfH), (x + halfW, y - halfH), 
      (x + halfW, y + halfH), (x - halfW, y + halfH)]

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




-- FUNCIONES USANDO FUNCTOR Y APPLICATIVE

-- Funciones auxiliares
combineMessages :: String -> String -> String
combineMessages "" msg = msg
combineMessages msg "" = msg
combineMessages msg1 msg2 = msg1 ++ "; " ++ msg2

scaleVector :: Double -> Vector -> Vector
scaleVector s (x, y) = (s * x, s * y)

-- Usar fmap para transformar posiciones
translateTank :: Vector -> Tank -> Tank
translateTank offset tank = tank { tankPosition = addPositions offset (tankPosition tank) }

-- Usar Applicative para combinar GameObjects
combineGameObjects :: GameObject Tank -> GameObject Projectile -> GameObject (Tank, Projectile)
combineGameObjects tankObj projObj = (,) <$> pure (goExtra tankObj) <*> pure (goExtra projObj)

-- Actualizar posición usando TimedTransform y Applicative
updatePositionApplicative :: Double -> Tank -> TimedTransform Tank
updatePositionApplicative dt tank = 
  let currentVel = bodyVelocity (tankBody tank)
      newPos = addPositions (tankPosition tank) (scaleVector dt currentVel)
      updatedTank = tank { tankPosition = newPos }
  in TimedTransform updatedTank dt

-- Aplicar movimiento usando Applicative
applyMove :: Move -> Tank -> GameAction Tank
applyMove Idle tank = pure tank
applyMove (SetVelocity v) tank = 
  let updateBody body = body { bodyVelocity = v }
      result = tank { tankBody = updateBody (tankBody tank) }
  in GameAction result True "Velocity set"
applyMove (Accelerate acc) tank = 
  let currentVel = bodyVelocity (tankBody tank)
      newVel = addVectors currentVel acc
      updateBody body = body { bodyVelocity = newVel }
      result = tank { tankBody = updateBody (tankBody tank) }
  in GameAction result True "Acceleration applied"

-- Verificar límites usando BoundedPosition
checkBounds :: Position -> Size -> BoundedPosition Position
checkBounds pos (width, height) = 
  let (x, y) = pos
      inBounds = x >= 0 && x <= width && y >= 0 && y <= height
  in BoundedPosition pos inBounds

-- Transformar múltiples tanques usando fmap
transformTanks :: (Tank -> Tank) -> [Tank] -> [Tank]
transformTanks = fmap

-- Combinar efectos usando Applicative
combineEffects :: GameObject a -> Vector -> Health -> GameObject a
combineEffects obj velocity healthBonus = 
  obj { goVelocity = velocity, goHealth = fmap (+ healthBonus) (goHealth obj) }

-- Aplicar física usando Applicative
applyPhysics :: Double -> Tank -> Tank
applyPhysics dt tank = 
  let currentVel = bodyVelocity (tankBody tank)
      newPosition = addPositions (tankPosition tank) (scaleVector dt currentVel)
  in tank { tankPosition = newPosition }





