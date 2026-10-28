-- | Módulo Mapas: Define las colisiones de la arena y obstáculos
module Mapas
  ( arenaLimites
  , obstaculos
  , todasLasLineas
  ) where

import Tipos

-- ============================================================
-- ARENA: Límites principales del mapa
-- ============================================================
-- 4 puntos que forman las esquinas del mapa
arenaLimites :: [(Position, Position)]
arenaLimites =
  [ ((-365, 352), (379, 356))    -- Línea superior
  , ((379, 356), (384, -384))    -- Línea derecha
  , ((384, -384), (-371, -381))  -- Línea inferior
  , ((-371, -381), (-365, 352))  -- Línea izquierda
  ]

-- ============================================================
-- OBSTÁCULOS: Polígonos dentro del mapa
-- ============================================================
-- Cada obstáculo es una lista de líneas que lo forman
-- Agrupados de 4 en 4 puntos (rectángulos)

obstaculos :: [[(Position, Position)]]
obstaculos =
  [ -- Obstáculo 1
    [ ((164, 295), (223, 295))
    , ((223, 295), (223, 270))
    , ((223, 270), (164, 270))
    , ((164, 270), (164, 295))
    ]
  
  , -- Obstáculo 2
    [ ((97, 79), (118, 79))
    , ((118, 79), (118, 35))
    , ((118, 35), (97, 35))
    , ((97, 35), (97, 79))
    ]
  
  , -- Obstáculo 3
    [ ((-144, -52), (-124, -52))
    , ((-124, -52), (-124, -102))
    , ((-124, -102), (-143, -102))
    , ((-143, -102), (-144, -52))
    ]
  
  , -- Obstáculo 4
    [ ((-51, -169), (-30, -169))
    , ((-30, -169), (-30, -214))
    , ((-30, -214), (-51, -214))
    , ((-51, -214), (-51, -169))
    ]
  
  , -- Obstáculo 5
    [ ((26, -166), (48, -166))
    , ((48, -166), (48, -208))
    , ((48, -208), (27, -208))
    , ((27, -207), (26, -166))
    ]
  
  , -- Obstáculo 6
    [ ((-229, -276), (-168, -276))
    , ((-168, -276), (-168, -300))
    , ((-168, -300), (-229, -300))
    , ((-229, -300), (-229, -276))
    ]
    
  ,
    [ ((-15, 12), (18, 12))
    , ((18, 12), (18, -33))
    , ((18, -33), (-15, -33))
    , ((-15, -34), (-15, 12))
    ]
  ]

-- ============================================================
-- FUNCIÓN AUXILIAR: Obtener todas las líneas (arena + obstáculos)
-- ============================================================
-- Útil para dibujar todas las colisiones de una vez
todasLasLineas :: [(Position, Position)]
todasLasLineas = arenaLimites ++ concatMap id obstaculos
