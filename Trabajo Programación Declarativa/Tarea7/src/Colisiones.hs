module Colisiones
( lineIntersection
, positionCollidesWithLine
) where

import Tipos

-- ============================================================================
-- COLISIONES CON LÍNEAS (para arena y obstáculos)
-- ============================================================================

-- Detectar si un segmento de línea choca con otro
lineIntersection :: (Point, Point) -> (Point, Point) -> Bool
lineIntersection ((x1, y1), (x2, y2)) ((x3, y3), (x4, y4)) =
  let det = (x2 - x1) * (y4 - y3) - (y2 - y1) * (x4 - x3)
  in if abs det < 1e-10
     then False  -- Líneas paralelas
     else let t = ((x3 - x1) * (y4 - y3) - (y3 - y1) * (x4 - x3)) / det
              u = ((x3 - x1) * (y2 - y1) - (y3 - y1) * (x2 - x1)) / det
          in t >= 0 && t <= 1 && u >= 0 && u <= 1

-- Comprobar si una posición (con su tamaño como rectángulo) choca con alguna línea de límite
positionCollidesWithLine :: Position -> Size -> [(Point, Point)] -> Bool
positionCollidesWithLine (x, y) (w, h) limits =
  let corners = [(x - w/2, y - h/2), (x + w/2, y - h/2), (x + w/2, y + h/2), (x - w/2, y + h/2)]
      edges = zip corners (tail corners ++ [head corners])
  in any (\edge -> any (lineIntersection edge) limits) edges
