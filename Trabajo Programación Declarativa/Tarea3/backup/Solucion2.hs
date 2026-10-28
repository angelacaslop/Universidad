-- Instrucciones

-- 1. Analiza el funcionamiento del juego y piensa en los tipos que son necesarios. Realiza una lista durante el análisis visual y posteriormente implementa dichos TADs.
-- Nota, copiamos y pegamos todos los tipos implementados en la primera tarea:

-- Point. Un punto 2D en el espacio.
type Point = (Double, Double)

-- Vector. Vector siempre se considera que empieza en (0,0)
type Vector = (Double, Double)

-- Angle. Un angulo con decimales
type Angle = Double

-- Distance. Un valor de distancia con decimales.
type Distance = Double

-- Position. Representa la posición de objeto en un mundo 2D.
type Position = Point

-- Size. Representa el tamaño (ancho, alto)
type Size = (Double, Double)

-- Nuevas implementaciones de tipos:
type Speed = Double
type Health = Double
type Direction = Vector
type Range = Double


data Tank = Tank {
    tankPosition  :: Position,
    tankVelocity  :: Vector,
    tankHealth    :: Health,
    tankRange     :: Range
}

data Proyectile = Proyectile {
    proyectilePosition :: Position,
    projectileSpeed :: Speed,
    proyectileDirection :: Direction
}

data Move
  = Idle
  | SetVelocity Vector
  | Accelerate Vector
  deriving (Show, Eq)



-- 2. Refactoriza las funciones implementadas hasta ahora para usar pattern matching, listas por comprensión y cláusulas where, if-then-else, guardas o case-of cuando proceda.

-- distanceBetween :: Position -> Position -> Distance. Calcula la distancia euclidiana entre dos posiciones en el espacio. Toma dos puntos como entrada y devuelve la distancia lineal que los separa.
distanceBetween :: Position -> Position -> Distance
distanceBetween (x1, y1) (x2, y2) = sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

-- angleToTarget :: Position -> Position -> Angle. Determina el ángulo desde una posición origen hacia una posición objetivo. Útil para calcular la dirección en la que debe apuntar o moverse un objeto.
angleToTarget :: Position -> Position -> Angle
angleToTarget (x1, y1) (x2, y2) = atan2 (y2 - y1) (x2 - x1)

-- sub :: Point -> Point -> Point. Resta un punto de otro, devolviendo un nuevo punto que representa la diferencia entre las coordenadas.
sub :: Point -> Point -> Point
sub (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- dot :: Point -> Point -> Double. Calcula el producto escalar (dot product) entre dos puntos tratados como vectores
dot :: Point -> Point -> Double
dot (x1, y1) (x2, y2) = x1 * x2 + y1 * y2

-- deg2rad :: Angle -> Angle. Convierte un ángulo expresado en grados a su equivalente en radianes.
deg2rad :: Angle -> Angle
deg2rad grados = grados * pi / 180

-- rad2deg :: Angle -> Angle. Convierte un ángulo expresado en radianes a su equivalente en grados.
rad2deg :: Angle -> Angle
rad2deg radianes = radianes * 180 / pi

-- subVec :: Vector -> Vector -> Vector. Realiza la resta de dos vectores, devolviendo un nuevo vector que representa la diferencia entre ellos.
subVec :: Vector -> Vector -> Vector
subVec (x1, y1) (x2, y2) = (x1 - x2, y1 - y2)

-- perp :: Vector -> Vector. Calcula el vector perpendicular a un punto dado (tratado como vector).
perp :: Vector -> Vector
perp (x, y) = (-y, x)

-- getVertices :: (Point, Point, Point, Point, Angle) -> [Point]. Genera una lista de vértices (puntos) a partir de cuatro puntos base y un ángulo de rotación.
getVertices :: (Point, Point, Point, Point, Angle) -> [Point]
getVertices (p1, p2, p3, p4, a) = map rotar [p1, p2, p3, p4]
  where
    rotar (x,y) = (x * cos a - y * sin a, x * sin a + y * cos a)
          
-- isInBounds :: Point -> Size -> Bool. Verifica si un punto se encuentra dentro de los límites definidos por un tamaño dado.
isInBounds :: Point -> Size -> Bool
isInBounds (x, y) (ancho, alto) = x >= 0 && x <= ancho && y >= 0 && y <= alto

modulo :: Vector -> Double
modulo xs = sqrt (x^2 + y^2)
    where (x, y) = xs

unitario :: Vector -> Vector
unitario (0,0) = (0,0)
unitario xs = (x / mod, y / mod)
    where 
        (x, y) = xs
        mod = modulo xs

-- 3. Implementa las siguientes funciones usando pattern matching con los TADs definidos anteriormente:

--   - detectedAgent: Determinar si un agente ha detectado a otro en caso de encontrarse dentro del rango de su radar
detectedAgent :: Tank -> Tank -> Bool
detectedAgent t1 t2 = tankRange t1 >= distanceBetween (tankPosition t1) (tankPosition t2)

--   - isRobotAlive: True si la energía del robot es mayor a 0
isRobotAlive :: Tank -> Bool
isRobotAlive t = tankHealth t > 0

--   - countActiveRobots: Contar los robots que están vivos
countActiveRobots :: [Tank] -> Int
countActiveRobots ts = sum [1 | t <- ts, isRobotAlive t]

--   - updateRobotVelocity: Actualiza la velocidad de un robot con una velocidad dada
updateRobotVelocity :: Tank -> Vector -> Tank
updateRobotVelocity tank v = tank{tankVelocity=v}

--   - updateVelocity: updateVelocity: Actualizar velocidad basada en la acción de movimiento informada por el bot
updateVelocity :: Tank -> Move -> Tank
updateVelocity t Idle              = t
updateVelocity t (SetVelocity v)   = t { tankVelocity = v }
updateVelocity t (Accelerate (dx,dy)) =
  let (vx, vy) = tankVelocity t
  in t { tankVelocity = (vx + dx, vy + dy) }
  
--   - updatePosition: Actualizar una posición en función de la velocidad y el incremento de tiempo
updatePosition :: Tank -> Double -> Tank
updatePosition t dt =
  let (x,y)   = tankPosition t
      (vx,vy) = tankVelocity t
  in t { tankPosition = (x + vx * dt, y + vy * dt) }

--   - mul: tal que (w,h) `mul` (sw,sh) = (wsw, hsh)
mul :: Vector -> Vector -> Vector
mul (w, h) (sw, sh) = (w*sw, h*sh)

-- Nota sobre el uso de LLMs

-- Si usas ChatGPT o cualquier otro LLM, incluye en tu entrega los prompts que has usado e indica si posteriormente has realizado modificaciones.


-- Tarea realizada por Pablo Navidad Moreno, José Manuel Mateos Periáñez, Mario Roldán Molina y Ángela Castilla López


-- Sobre el uso de IA:
-- - Hemos realizado el trabajo nosotros y cuando pensamos que estaba correcto hemos buscado fallos con IA
-- - La conversación con la IA se puede ver en el siguiente enlace: https://chatgpt.com/share/68d187a6-6c4c-8006-9f82-a61e57c1c7d9
-- - No se ha corregido el nuevo concepto de velocidad en "proyectil" ya que lo estudiaremos cuando lo usemos en funciones
-- - Al comienzo de la conversación con la IA se puede ver el código original, realizado por los integrantes del grupo


