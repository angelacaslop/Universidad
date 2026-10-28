module Comportamiento
( updateRobotVelocity
, updateVelocity
, updatePosition
, updateObjectBehavior
, moveObject
) where

import Tipos
import Fisica

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
      (x, y)   = tankPosition t
      newPos   = (x + vx * dt, y + vy * dt)
      moved    = [ (px + vx * dt, py + vy * dt) | (px,py) <- bodyCorners b ]
  in t { tankPosition = newPos, tankBody = b { bodyCorners = moved } }

-- ============================================================================
-- FUNCIONES PARA GAMEOBJECT
-- ============================================================================

-- Actualizar comportamiento de cualquier GameObject
updateObjectBehavior :: GameObject a -> Double -> GameObject a
updateObjectBehavior obj dt =
  let (vx, vy) = goVelocity obj
      (x, y) = goPosition obj
      newPos = (x + vx * dt, y + vy * dt)
  in obj { goPosition = newPos }

-- Mover un GameObject a una nueva posición
moveObject :: GameObject a -> Vector -> GameObject a
moveObject obj velocity = obj { goVelocity = velocity }
