module IA
( decideActions
) where

import Tipos
import Memoria
import Fisica

-- decideActions: dado un tanque y el estado del juego, devuelve una lista de acciones
decideActions :: Tank -> [Tank] -> [Projectile] -> [BotAction]
decideActions tank tanks projectiles
  | any (detectedAgent tank) (filter (/= tank) tanks)
    = [Remember "enemigoDetectado" (MemBool True), Shoot]
  | otherwise
    = [MoveTank (1, 0), DoNothing]
