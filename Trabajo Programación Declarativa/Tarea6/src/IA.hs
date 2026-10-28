module IA
( decideActions
) where

import Tipos
import Fisica
import Colisiones
import Mapas (obstaculos, arenaLimites)
import Data.List (minimumBy, nub)

-- decideActions: dado un tanque y el estado del juego, devuelve una lista de acciones
-- Implementa comportamientos principales: evasión de proyectiles, búsqueda/combate, evasión de obstáculos
-- Y detección de bloqueos para escapar de trampas
decideActions :: Tank -> [Tank] -> [Projectile] -> [BotAction]
decideActions tank tanks projectiles =
  let (tx, ty) = tankPosition tank
      aliveTanks = filter (\t -> t /= tank && tankHealth t > 0) tanks
      
      -- DETECCIÓN DE BLOQUEO: Comprobar si el tanque está atrapado (no se movió)
      lastPosStr = case lookup "lastPos" (tankMemory tank) of
                     Just (MemString str) -> str
                     _ -> ""
      isStuck = if not (null lastPosStr)
                then let [lastX, lastY] = read lastPosStr :: [Double]
                         dist = sqrt ((tx - lastX)**2 + (ty - lastY)**2)
                     in dist < 10  -- Aumentado a 10 píxeles para mejor detección
                else False
      
      -- DETECCIÓN DE ESQUINAS Y AISLAMIENTO: Evitar quedarse en las esquinas
      inCorner = abs tx > 280 && abs ty > 280  -- Está en una esquina
      nearEdge = abs tx > 300 || abs ty > 300  -- Muy cerca de los bordes
      onEdge = abs tx > 350 || abs ty > 350    -- EN el borde (peligro alto)
      
      -- Detección de colisión con obstáculos: verificar si hay obstáculo adelante
      (w, h) = tankSize tank
      checkRadius = 60  -- Radio para verificar colisión próxima
      currentAngle = tankAngle tank
      angleRad = currentAngle * pi / 180
      forwardDir = (cos angleRad, -sin angleRad)
      checkPos = (tx + fst forwardDir * checkRadius, ty + snd forwardDir * checkRadius)
      allObstacles = concatMap id obstaculos ++ arenaLimites
      isCollidingAhead = positionCollidesWithLine checkPos (w, h) allObstacles
      
      -- Detección adicional: verificar obstáculos en un radio más amplio
      nearbyObstacleDistance = checkNearbyObstacles tank 80
      isNearObstacle = nearbyObstacleDistance < 80
      
      -- Si hay colisión adelante, forzar cambio de dirección
      needsRedirect = isCollidingAhead || (isStuck && nearEdge)
      
      -- COMPORTAMIENTO 1: Evasión simple de proyectiles cercanos
      dangerousProjectiles = filter (\p -> 
        let (px, py) = projectilePosition p
            dist = sqrt ((tx - px)**2 + (ty - py)**2)
        in dist < 180) projectiles
      
      -- Si hay proyectiles cerca, huir en dirección opuesta
      evadeAction = if not (null dangerousProjectiles)
        then let closest = minimumBy (\p1 p2 -> 
                   let (px1, py1) = projectilePosition p1
                       (px2, py2) = projectilePosition p2
                       d1 = sqrt ((tx - px1)**2 + (ty - py1)**2)
                       d2 = sqrt ((tx - px2)**2 + (ty - py2)**2)
                   in compare d1 d2) dangerousProjectiles
                 (px, py) = projectilePosition closest
                 -- Dirección opuesta al proyectil
                 escapeX = tx - px
                 escapeY = ty - py
                 escapeLen = sqrt (escapeX**2 + escapeY**2)
                 (normX, normY) = if escapeLen > 0 
                                   then (escapeX / escapeLen, escapeY / escapeLen)
                                   else (1, 0)
             in Just (MoveTank (normX, normY))
        else Nothing
      
      -- COMPORTAMIENTO 2: Búsqueda y combate con enemigos (SIEMPRE activo si hay enemigos vivos)
      -- MODIFICADO: Si está en esquina, priorizar salir hacia los enemigos
      combatAction = if not (null aliveTanks)
        then let closestEnemy = minimumBy (\t1 t2 -> 
                       compare (distanceBetweenTanks tank t1) (distanceBetweenTanks tank t2)) aliveTanks
                 (ex, ey) = tankPosition closestEnemy
                 (dirX, dirY) = (ex - tx, ey - ty)
                 len = sqrt (dirX ** 2 + dirY ** 2)
                 (normX, normY) = if len == 0 then (1, 0) else (dirX / len, dirY / len)
                 
                 -- SIEMPRE moverse hacia el enemigo (búsqueda activa)
                 -- Si está en esquina, FORZAR movimiento hacia el enemigo (no strafing)
                 isDetected = any (detectedAgent tank) aliveTanks
                 moveDir = if inCorner
                           then (normX, normY)  -- FORZAR salida de la esquina hacia enemigo
                           else if len < 60  -- MUY CERCA: alejarse para mantener distancia
                           then (-normX, -normY)
                           else if isDetected && len < 200 && len > 60
                           then let perpX = -normY * 0.5  -- Componente lateral
                                    perpY = normX * 0.5
                                    -- IMPORTANTE: Mezclar strafing con acercamiento
                                    -- A distancia óptima (100-150), más strafing
                                    approachWeight = if len > 100 then 0.7 else 0.3
                                    strafeWeight = if len > 100 then 0.3 else 0.7
                                    mixX = normX * approachWeight + perpX * strafeWeight
                                    mixY = normY * approachWeight + perpY * strafeWeight
                                    mixLen = sqrt (mixX**2 + mixY**2)
                                in if mixLen > 0 
                                   then (mixX / mixLen, mixY / mixLen)
                                   else (normX, normY)
                           else (normX, normY)  -- LEJOS: acercarse directamente
                 
                 -- IMPORTANTE: Solo disparar si el camino está libre de obstáculos y a distancia óptima
                 shouldShoot = isDetected && len < 250 && not (hasObstacleInPath tank closestEnemy)
             in Just (moveDir, shouldShoot)
        else Nothing
      
      -- COMPORTAMIENTO 3: Evasión de obstáculos - ajustar movimiento si hay colisión próxima
      avoidanceDir = avoidObstacles tank
      
      -- COMPORTAMIENTO 4: Escape si está atrapado o colisionando
      -- Si el tanque está chocando con algo o atrapado, buscar nueva dirección
      escapeDirection = if needsRedirect
                        then findEscapeDirection tank
                        else avoidanceDir
      
      -- COMPORTAMIENTO 5: Si está en esquina sin enemigos, ir al centro
      -- PRIORIDAD: Salir de esquinas es MÁS importante que explorar
      antiCornerDir = if inCorner
                      then let toCenterX = -tx
                               toCenterY = -ty
                               centerLen = sqrt (toCenterX**2 + toCenterY**2)
                           in if centerLen > 0
                              then (toCenterX / centerLen, toCenterY / centerLen)
                              else (1, 0)
                      else (0, 0)
      
      -- COMPORTAMIENTO POR DEFECTO: Explorar activamente (NUNCA quedarse estático)
      -- Si no hay enemigos visibles, moverse en patrón de búsqueda
      defaultDir = let distToCenter = sqrt (tx**2 + ty**2)
                       -- Obtener tiempo de exploración desde memoria
                       explorePhase = case lookup "explorePhase" (tankMemory tank) of
                                       Just (MemInt phase) -> fromIntegral phase
                                       _ -> 0.0
                       -- Crear patrón de exploración variado (8 direcciones principales)
                       angle = explorePhase * (pi / 4)
                       exploreX = cos angle
                       exploreY = sin angle
                   in if distToCenter > 200  -- Si está muy lejos del centro
                      then (-tx / distToCenter, -ty / distToCenter)  -- Volver al centro
                      else (exploreX, exploreY)  -- Patrón de exploración circular
      
      -- Decisión final: 
      -- Prioridad: evasión proyectiles > bordes > colisión/atascado > esquina > combate > exploración
      finalMove = case evadeAction of
                    Just move -> move
                    Nothing -> if onEdge
                              -- PRIORIDAD ALTA: Si está en el borde, forzar volver al centro
                              then let toCenterX = -tx
                                       toCenterY = -ty
                                       centerLen = sqrt (toCenterX**2 + toCenterY**2)
                                   in if centerLen > 0
                                      then MoveTank (toCenterX / centerLen, toCenterY / centerLen)
                                      else MoveTank (1, 0)
                              else if needsRedirect
                              then MoveTank escapeDirection  -- Si choca o atascado, cambiar dirección
                              else if inCorner && null aliveTanks
                              then MoveTank antiCornerDir  -- Si en esquina sin enemigos, salir
                              else case combatAction of
                                     Just (dir, _) -> 
                                       let (avX, avY) = if isCollidingAhead then escapeDirection else avoidanceDir
                                           (dirX, dirY) = dir
                                           -- REDUCIR peso de evasión - priorizar combate
                                           avoidWeight = if isCollidingAhead 
                                                        then 0.5  -- Colisión inminente: prioridad media
                                                        else if isNearObstacle 
                                                        then 0.35  -- Obstáculo cerca: prioridad baja-media
                                                        else 0.2  -- Normal: prioridad muy baja
                                           -- Si está cerca del borde, añadir componente hacia centro
                                           (centerX, centerY) = if nearEdge
                                                               then let toCX = -tx
                                                                        toCY = -ty
                                                                        centerLen = sqrt (toCX**2 + toCY**2)
                                                                    in if centerLen > 0
                                                                       then (toCX / centerLen * 0.4, toCY / centerLen * 0.4)
                                                                       else (0, 0)
                                                               else (0, 0)
                                           -- Mezclar dirección de combate con evasión de obstáculos y centro
                                           blendX = (dirX + avX * avoidWeight + centerX) / (1 + avoidWeight + (if nearEdge then 0.4 else 0))
                                           blendY = (dirY + avY * avoidWeight + centerY) / (1 + avoidWeight + (if nearEdge then 0.4 else 0))
                                           blendLen = sqrt (blendX**2 + blendY**2)
                                       in if blendLen > 0
                                          then MoveTank (blendX / blendLen, blendY / blendLen)
                                          else MoveTank escapeDirection
                                     Nothing -> 
                                       let (avX, avY) = if isNearObstacle then escapeDirection else avoidanceDir
                                           (defX, defY) = defaultDir
                                           -- REDUCIR peso de evasión durante exploración
                                           avoidWeight = if isNearObstacle then 0.5 else 0.3
                                           -- Si cerca del borde, ir al centro en vez de explorar
                                           finalDefDir = if nearEdge
                                                        then let toCX = -tx
                                                                 toCY = -ty
                                                                 centerLen = sqrt (toCX**2 + toCY**2)
                                                             in if centerLen > 0
                                                                then (toCX / centerLen, toCY / centerLen)
                                                                else (defX, defY)
                                                        else (defX, defY)
                                           blendX = (fst finalDefDir + avX * avoidWeight) / (1 + avoidWeight)
                                           blendY = (snd finalDefDir + avY * avoidWeight) / (1 + avoidWeight)
                                           blendLen = sqrt (blendX**2 + blendY**2)
                                       in if blendLen > 0
                                          then MoveTank (blendX / blendLen, blendY / blendLen)
                                          else MoveTank defaultDir
      
      shouldShoot = case combatAction of
                      Just (_, shoot) -> shoot
                      Nothing -> False
      
      -- Recordar posición actual para detectar bloqueos en la siguiente llamada
      rememberAction = Remember "lastPos" (MemString (show [tx, ty]))
      
      -- Actualizar fase de exploración (para movimiento variado cuando no hay enemigos)
      currentPhase = case lookup "explorePhase" (tankMemory tank) of
                       Just (MemInt p) -> p
                       _ -> 0
      newPhase = (currentPhase + 1) `mod` 8  -- Rotar entre 8 direcciones
      rememberPhase = Remember "explorePhase" (MemInt newPhase)
      
  in [finalMove, rememberAction, rememberPhase] ++ (if shouldShoot then [Shoot] else [])


-- ============================================================================
-- FUNCIONES AUXILIARES PARA DETECCIÓN DE OBSTÁCULOS
-- ============================================================================

-- Detectar si hay un obstáculo en la línea recta entre dos tanques
-- Devuelve True si el camino está bloqueado
hasObstacleInPath :: Tank -> Tank -> Bool
hasObstacleInPath tank1 tank2 =
  let (x1, y1) = tankPosition tank1
      (x2, y2) = tankPosition tank2
      lineOfSight = ((x1, y1), (x2, y2))
      allObstacles = concatMap id obstaculos ++ arenaLimites
  in any (lineIntersection lineOfSight) allObstacles

-- Evitar obstáculos cercanos - ajustar dirección si hay colisión próxima
-- Devuelve una dirección que evita obstáculos
avoidObstacles :: Tank -> (Double, Double)
avoidObstacles tank =
  let (tx, ty) = tankPosition tank
      (w, h) = tankSize tank
      detectionRadius = 100  -- Distancia de detección de obstáculos
      
      -- Probar varias direcciones alrededor del tanque
      testDirections = [(cos a, sin a) | a <- [0, pi/4, pi/2, 3*pi/4, pi, 5*pi/4, 3*pi/2, 7*pi/4]]
      
      -- Para cada dirección, comprobar si hay colisión con obstáculos
      isSafe (dx, dy) =
        let testPos = (tx + dx * detectionRadius, ty + dy * detectionRadius)
            allObstacles = concatMap id obstaculos ++ arenaLimites
        in not (positionCollidesWithLine testPos (w, h) allObstacles)
      
      -- Encontrar la dirección más segura (preferiblemente hacia adelante)
      safeDirections = filter isSafe testDirections
      bestDir = if not (null safeDirections)
                then head safeDirections
                else (1, 0)  -- Fallback: intentar hacia adelante
  in bestDir


-- Encontrar dirección de escape cuando el tanque está atrapado
-- Intenta todas las direcciones posibles hasta encontrar una que funcione
findEscapeDirection :: Tank -> (Double, Double)
findEscapeDirection tank =
  let (tx, ty) = tankPosition tank
      (w, h) = tankSize tank
      escapeRadius = 90  -- Radio medio para escape
      
      -- Generar más direcciones para tener más opciones (20 en vez de 16)
      testAngles = [fromIntegral i * (2 * pi / 20) | i <- [0..19]]
      testDirections = [(cos a, sin a) | a <- testAngles]
      
      -- Comprobar si una posición es segura (sin obstáculos)
      canMoveTo (dx, dy) =
        let testPos = (tx + dx * escapeRadius, ty + dy * escapeRadius)
            allObstacles = concatMap id obstaculos ++ arenaLimites
        in not (positionCollidesWithLine testPos (w, h) allObstacles)
      
      -- Encontrar dirección segura
      safeDirections = filter canMoveTo testDirections
      
      -- Si hay direcciones seguras, elegir la que más se aleje de los bordes
      bestDir = if not (null safeDirections)
                then let -- Preferir direcciones hacia el centro
                         scoredDirs = [(d, abs (fst d * tx) + abs (snd d * ty)) | d <- safeDirections]
                         bestScored = minimumBy (\(_, s1) (_, s2) -> compare s1 s2) scoredDirs
                     in fst bestScored
                else (-tx / max (abs tx) 1, -ty / max (abs ty) 1)  -- Hacia el centro
  in bestDir

-- Verificar distancia al obstáculo más cercano
-- Devuelve la distancia mínima a cualquier obstáculo en el radio especificado
checkNearbyObstacles :: Tank -> Double -> Double
checkNearbyObstacles tank radius =
  let (tx, ty) = tankPosition tank
      (w, h) = tankSize tank
      allObstacles = concatMap id obstaculos ++ arenaLimites
      
      -- Probar varias distancias hasta encontrar colisión
      testDistances = [radius, radius * 0.75, radius * 0.5, radius * 0.25]
      
      -- Para cada distancia, verificar si hay colisión en alguna dirección
      findCollisionDistance dist =
        let testAngles = [fromIntegral i * (2 * pi / 12) | i <- [0..11]]
            testPositions = [(tx + cos a * dist, ty + sin a * dist) | a <- testAngles]
            hasCollision = any (\pos -> positionCollidesWithLine pos (w, h) allObstacles) testPositions
        in if hasCollision then Just dist else Nothing
      
      -- Encontrar la distancia más cercana con colisión
      collisionDistances = [d | d <- testDistances, findCollisionDistance d == Just d]
  in if null collisionDistances then radius else minimum collisionDistances