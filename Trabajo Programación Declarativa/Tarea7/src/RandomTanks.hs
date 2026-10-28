module RandomTanks (randomTankPositionsIO) where

import System.Random (StdGen, newStdGen, randomR)
import Tipos
import Colisiones
import Mapas (obstaculos)

-- Tamaño de cada tanque (igual que en defaultTank)
defaultTankSize :: (Double, Double)
defaultTankSize = (50, 30)

-- Límites seguros del mapa (coinciden con arena de Mapas.hs)
-- Arena límites: X: -365 a 379, Y: -384 a 352
-- Agregamos margen para que los tanques no salgan parcialmente
xRange, yRange :: (Double, Double)
xRange = (-340, 354)
yRange = (-359, 327)

-----------------------------------------------------
-- 🔹 FUNCIÓN PRINCIPAL (IO, con semilla del sistema)
-----------------------------------------------------
randomTankPositionsIO :: Int -> IO [(Double, Double)]
randomTankPositionsIO n = do
  gen <- newStdGen
  pure $ randomTankPositions gen [] n

-----------------------------------------------------
-- 🔹 FUNCIÓN PURA INTERNA (usa el generador)
-----------------------------------------------------
randomTankPositions :: StdGen -> [(Double, Double)] -> Int -> [(Double, Double)]
randomTankPositions _ acc 0 = acc
randomTankPositions gen acc remaining =
  let (pos, gen') = randomValidPos gen acc
  in randomTankPositions gen' (pos : acc) (remaining - 1)

-----------------------------------------------------
-- 🔹 GENERAR UNA POSICIÓN VÁLIDA
-----------------------------------------------------
randomValidPos :: StdGen -> [(Double, Double)] -> ((Double, Double), StdGen)
randomValidPos gen existing =
  let (x, gen1) = randomR xRange gen
      (y, gen2) = randomR yRange gen1
      pos = (x, y)
  in if collidesWithAnyObstacle pos || any (tanksOverlap pos) existing
        then randomValidPos gen2 existing   -- Reintentar si hay colisión
        else (pos, gen2)

-----------------------------------------------------
-- 🔹 FUNCIONES DE COLISIÓN
-----------------------------------------------------

-- Colisión con obstáculos del mapa
collidesWithAnyObstacle :: (Double, Double) -> Bool
collidesWithAnyObstacle pos =
  any (positionCollidesWithLine pos defaultTankSize) obstaculos

-- Evitar solapamiento entre tanques
tanksOverlap :: (Double, Double) -> (Double, Double) -> Bool
tanksOverlap (x1, y1) (x2, y2) =
  let (w, h) = defaultTankSize
      margin = 10  -- espacio adicional
  in abs (x1 - x2) < (w + margin) && abs (y1 - y2) < (h + margin)
