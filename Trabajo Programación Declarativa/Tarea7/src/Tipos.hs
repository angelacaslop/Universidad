-- PRAGMA: Habilita la extensión DeriveFunctor de GHC
-- Sin esta extensión, tendríamos que escribir manualmente:
--   instance Functor GameObject where
--     fmap f (GameObject pos vel size health extra) = GameObject pos vel size health (f extra)
-- Con DeriveFunctor, GHC genera automáticamente esta instancia cuando escribimos "deriving Functor"
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE InstanceSigs #-}

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
, TankId
, Turret(..)
, Tank(..)
, Projectile(..)
, GameState(..)
, GameScreen(..)
, MemoryValue(..)
, Memory
, BotAction(..)
, GameObject(..)
, TankObject
, ProjectileObject
, defaultTank
, createTankAtPosition
, addPositions
, scaleVector
, addVectors

) where

import Data.Time (NominalDiffTime)
import Graphics.Gloss (Picture)
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
type TankId = Int
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

-- Escalar vector
scaleVector :: Double -> Vector -> Vector
scaleVector s (x, y) = (s * x, s * y)




-- TIPOS DE DATOS DEL JUEGO

data Turret = Turret
  { turretDirection :: Direction
  , turretCooldown  :: Time
  } deriving (Show, Eq)

data Tank = Tank
  { tankId             :: TankId         -- Identificador único del tanque
  , tankTurret         :: Turret
  , tankRange          :: Range
  , tankHealth         :: Health
  , tankMemory         :: Memory
  , tankPosition       :: Position
  , tankSize           :: Size
  , tankAngle          :: Double  -- Ángulo de rotación del tanque en grados
  , tankMoveSpeed      :: Speed   -- Velocidad de movimiento lineal
  , tankRotationSpeed  :: Speed   -- Velocidad de rotación angular (grados/segundo)
  } deriving (Show, Eq)

data Projectile = Projectile
  { projectileDirection :: Direction
  , projectileDamage    :: Damage
  , projectilePosition  :: Position
  , projectileSize      :: Size
  , projectileVelocity  :: Vector
  , projectileOwner     :: Int  -- Índice del tanque que lo disparó
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

-- Pantallas del juego
data GameScreen
  = MenuScreen Int  -- Pantalla de menú con número de bots seleccionado
  | PlayingScreen   -- Jugando
  | GameOverScreen Bool  -- Game over (True = victoria, False = derrota)
  deriving (Show, Eq)

-- Estado del juego
data GameState = GameState
  { tanks :: [Tank]
  , projectiles :: [Projectile]
  , gameTime :: Float
  , explosions :: [(Position, Float)]  -- (posición, radio)
  , mousePos :: Position  -- Posición del ratón
  , keysPressed :: [Char]  -- Teclas presionadas (W, A, S, D)
  , backgroundImage :: Maybe Picture  -- Imagen de fondo cacheada
  , tankBodySprite :: Maybe Picture  -- Sprite de base del tanque
  , tankTurretSprite :: Maybe Picture  -- Sprite de torreta
  , bulletSprite :: Maybe Picture  -- Sprite de bala
  , explosionFrames :: [Picture]  -- 27 frames de explosión
  , currentScreen :: GameScreen  -- Pantalla actual del juego
  } deriving (Show)



-- FUNCIONES DE EJEMPLO PARA CREAR TANQUES

-- Tanque por defecto con configuración estándar
defaultTank :: Tank
defaultTank = Tank
  { tankId = 0  -- Identificador único (será actualizado al crear tanques)
  , tankTurret = Turret
      { turretDirection = (1, 0)  -- Apunta a la derecha
      , turretCooldown = 0  -- Listo para disparar
      }
  , tankRange = 300  -- Rango máximo del disparo
  , tankHealth = 100  -- Vida inicial completa
  , tankMemory = []  -- Sin memoria
  , tankPosition = (0, 50)  -- 50 píxeles arriba en Y
  , tankSize = (50, 30)  -- Ancho 50, alto 30
  , tankAngle = 0  -- Sin rotación inicial
  , tankMoveSpeed = 75  -- Velocidad de movimiento: 150 píxeles/segundo
  , tankRotationSpeed = 100  -- Velocidad de rotación: 100 grados/segundo
  }

-- Crear un tanque en una posición específica
createTankAtPosition :: TankId -> Position -> Tank
createTankAtPosition tid pos = defaultTank { tankId = tid, tankPosition = pos, tankAngle = 0 }





