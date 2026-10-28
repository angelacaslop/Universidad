module Fisica
( distanceBetween
, distanceBetweenTanks
, angleToTarget
, angleBetweenTanks
, deg2rad
, rad2deg
, detectedAgent
, modulo
) where

import Tipos

-- Calcula la distacia entre dos puntos, función auxiliar de ditanceBetweenTanks
distanceBetween :: Position -> Position -> Distance
distanceBetween (x1, y1) (x2, y2) = sqrt ((x2 - x1) ** 2 + (y2 - y1) ** 2)

-- Dados dos tanques y aprovechandonos de las 2 funciones anteriores calculamos la distancia entre ellos
distanceBetweenTanks :: Tank -> Tank -> Distance
distanceBetweenTanks t1 t2 = distanceBetween (tankPosition t1) (tankPosition t2)

-- Dados dos puntos se calcula el ángulo entre ellos
angleToTarget :: Position -> Position -> Angle
angleToTarget (x1, y1) (x2, y2) = atan2 (y2 - y1) (x2 - x1)

-- Con ayuda de la función anterior y del centro de los tanque se calcula el ángulo entre los tanques
angleBetweenTanks :: Tank -> Tank -> Angle
angleBetweenTanks t1 t2 = angleToTarget (tankPosition t1) (tankPosition t2)

-- Para convertir de grados a radianes
deg2rad :: Angle -> Angle
deg2rad degrees = degrees * pi / 180

-- Para convertir de radianes a grados
rad2deg :: Angle -> Angle
rad2deg radians = radians * 180 / pi

-- modulo de un vector
modulo :: Vector -> Double
modulo (x, y) = sqrt (x**2 + y**2)

-- Dados 2 tanques, devuelve true si el primer tanque tiene dentro de su rango al segundo
detectedAgent :: Tank -> Tank -> Bool
detectedAgent t1 t2 = distanceBetweenTanks t1 t2 <= tankRange t1
