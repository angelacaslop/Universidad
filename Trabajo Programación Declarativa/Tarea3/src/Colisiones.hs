module Colisiones
( checkCollision
, detectRobotProjectileCollisions
, detectRobotRobotCollisions
, checkCollisions
) where

import Tipos
import Fisica
import Data.List (tails)

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
