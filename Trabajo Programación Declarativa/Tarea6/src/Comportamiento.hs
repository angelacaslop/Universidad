module Comportamiento
( reflectVector
) where

import Tipos

-- ============================================================================
-- REFLEXIÓN DE VECTORES
-- ============================================================================

-- Reflejar un vector contra una línea definida por dos puntos
-- Usa la normal de la línea para calcular la reflexión
reflectVector :: Vector -> (Point, Point) -> Vector
reflectVector (vx, vy) ((x1, y1), (x2, y2)) =
  let -- Calcular la normal a la línea (perpendicular)
      dx = x2 - x1
      dy = y2 - y1
      -- La normal sin normalizar
      nx = -dy
      ny = dx
      -- Normalizar
      len = sqrt (nx * nx + ny * ny)
      (nx', ny') = if len > 0 then (nx / len, ny / len) else (0, 1)
      -- Reflejar: v' = v - 2(v·n)n
      dotProd = vx * nx' + vy * ny'
  in (vx - 2 * dotProd * nx', vy - 2 * dotProd * ny')
