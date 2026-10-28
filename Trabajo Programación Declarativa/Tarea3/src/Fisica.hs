module Fisica
( centerOf
, distanceBetween
, distanceBetweenTanks
, angleToTarget
, angleBetweenTanks
, sub
, dot
, deg2rad
, rad2deg
, subVec
, perp
, getVertices
, rotarTanque
, isInBounds
, modulo
, unitario
, detectedAgent
, isRobotAlive
, countActiveRobots
, mul
) where

import Tipos

-- Recibe el cuerpo de un tanque y calcula el centro del mismo, muy útil para diversas operaciones posteriores
centerOf :: Body -> Position
centerOf body =
  let corners = bodyCorners body
      (sx, sy, n) = foldr (\(x, y) (ax, ay, c) -> (ax + x, ay + y, c + 1)) (0,0,0) corners
  in (sx / fromIntegral n, sy / fromIntegral n)

-- Calcula la distacia entre dos puntos, función auxiliar de ditanceBetweenTanks
distanceBetween :: Position -> Position -> Distance
distanceBetween (x1, y1) (x2, y2) = sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

-- Dados dos tanques y aprovechandonos de las 2 funciones anteriores calculamos la distancia entre ellos
distanceBetweenTanks :: Tank -> Tank -> Distance
distanceBetweenTanks t1 t2 = distanceBetween (tankPosition t1) (tankPosition t2)

-- Dados dos puntos se calcula el ángulo entre ellos
angleToTarget :: Position -> Position -> Angle
angleToTarget (x1, y1) (x2, y2) = atan2 (y2 - y1) (x2 - x1)

-- Con ayuda de la función anterior y del centro de los tanque se calcula el ángulo entre los tanques
angleBetweenTanks :: Tank -> Tank -> Angle
angleBetweenTanks t1 t2 = angleToTarget (tankPosition t1) (tankPosition t2)

-- Resta de puntos
sub :: Point -> Point -> Point
sub (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- módulo de 2 puntos
dot :: Point -> Point -> Double
dot (x1, y1) (x2, y2) = x1 * x2 + y1 * y2

-- Para convertir de grados a radianes
deg2rad :: Angle -> Angle
deg2rad degrees = degrees * pi / 180

-- Para convertir de radianes a grados
rad2deg :: Angle -> Angle
rad2deg radians = radians * 180 / pi

-- Resta de vectores
subVec :: Vector -> Vector -> Vector
subVec (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- Dado un vector obtenemos su perpendicular
perp :: Vector -> Vector
perp (x, y) = (-y, x)

-- Rotamos todos los vértices, sirve para rotar el tanque
getVertices :: (Point, Point, Point, Point, Angle) -> [Point]
getVertices (p1, p2, p3, p4, a) = map rotar [p1, p2, p3, p4]
  where
    rotar (x,y) = (x * cos a - y * sin a, x * sin a + y * cos a)

-- rotar el tanque ayudandose de la funcion anterior
rotarTanque :: Body -> Angle -> Body
rotarTanque body angle =
  body { bodyCorners = getVertices (c1, c2, c3, c4, angle) }
  where [c1, c2, c3, c4] = bodyCorners body

-- Comprueba que un punto esta dentro de un area
isInBounds :: Point -> Size -> Bool
isInBounds (x, y) (width, height) = x >= 0 && x <= width && y >= 0 && y <= height

-- modulo de un vector
modulo :: Vector -> Double
modulo (x, y) = sqrt (x^2 + y^2)

-- dado un vector calcular su unitario
unitario :: Vector -> Vector
unitario (0,0) = (0,0)
unitario v@(x, y) = (x / m, y / m)
  where m = modulo v

-- Dados 2 tanques, devuelve true si el primer tanque tiene dentro de su rango al segundo
detectedAgent :: Tank -> Tank -> Bool
detectedAgent t1 t2 = distanceBetweenTanks t1 t2 <= tankRange t1

-- Para saber si el bot está vivo
isRobotAlive :: Tank -> Bool
isRobotAlive t = tankHealth t > 0

-- Nos ayudamos de la función anterior para saber cuantos bots vivos quedan
countActiveRobots :: [Tank] -> Int
countActiveRobots ts = length (filter isRobotAlive ts)

-- multiplicacion de vectores
mul :: Vector -> Vector -> Vector
mul (w, h) (sw, sh) = (w * sw, h * sh)
