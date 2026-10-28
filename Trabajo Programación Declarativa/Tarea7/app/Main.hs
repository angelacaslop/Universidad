module Main where

import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Game
import Graphics.Gloss.Juicy (loadJuicyPNG)
import Data.List (minimumBy, partition)
import RandomTanks (randomTankPositionsIO)
import qualified Graphics.UI.GLUT as GLUT
import System.Environment (getProgName, getArgs)


-- Importamos todos los módulos del proyecto
import Tipos
import Colisiones
import Comportamiento
import Fisica
import IA
import Renderizar
import Mapas

-- ============================================================================
-- SECCIÓN 1: CONSTANTES Y CONFIGURACIÓN
-- ============================================================================

-- Configuración de la ventana
windowWidth :: Int
windowWidth = 1024

windowHeight :: Int
windowHeight = 1024

windowDisplay :: Display
windowDisplay = InWindow "Proyecto Tanques" (windowWidth, windowHeight) (100, 100)

backgroundColor :: Color
backgroundColor = black

-- Ruta de la imagen de fondo
arenaImagePath :: String
arenaImagePath = "sprites/Arena.png"

-- Fondo por defecto (verde)
arenaBackground :: Picture
arenaBackground = Color (makeColor 0.2 0.7 0.2 1.0) (rectangleSolid (fromIntegral windowWidth) (fromIntegral windowHeight))

-- ============================================================================
-- SECCIÓN 2: INICIALIZACIÓN DEL ESTADO DEL JUEGO
-- ============================================================================

-- Estado inicial del juego con 1 jugador y 2 bots (en menú)
initialGameState :: GameState
initialGameState = GameState
  { tanks = []  -- Sin tanques hasta que empiece el juego
  , projectiles = []
  , gameTime = 0
  , explosions = []
  , mousePos = (0, 0)
  , keysPressed = []
  , backgroundImage = Nothing
  , tankBodySprite = Nothing
  , tankTurretSprite = Nothing
  , bulletSprite = Nothing
  , explosionFrames = []
  , currentScreen = MenuScreen 2  -- Empezar en menú con 2 bots por defecto
  }

-- Cargar recursos (sprites) del juego
loadGameResources :: IO GameState
loadGameResources = do
  bgImg <- loadJuicyPNG arenaImagePath
  bodySprite <- loadJuicyPNG "sprites/tankbody.png"
  turretSprite <- loadJuicyPNG "sprites/tankturret.png"
  bulletSprite <- loadJuicyPNG "sprites/tankbullet.png"

  -- Cargar todos los frames de explosión (1-27)
  explosionPics <- mapM (\i -> loadJuicyPNG ("sprites/explotion/" ++ show i ++ ".png")) [1..27]
  let explosionFrames = [pic | Just pic <- explosionPics]

  pure initialGameState
    { backgroundImage = bgImg
    , tankBodySprite = bodySprite
    , tankTurretSprite = turretSprite
    , bulletSprite = bulletSprite
    , explosionFrames = explosionFrames
    }

-- Iniciar el juego con el número de bots especificado
startGame :: Int -> GameState -> IO GameState
startGame numBots gameState = do
  -- Generar posiciones aleatorias para los bots
  botPositions <- randomTankPositionsIO numBots
  let botTanks = [createTankAtPosition i pos | (i, pos) <- zip [1..numBots] botPositions]
  
  pure gameState
    { tanks = defaultTank { tankId = 0 } : botTanks  -- Jugador + bots
    , projectiles = []
    , gameTime = 0
    , explosions = []
    , keysPressed = []
    , mousePos = (0,0)
    , currentScreen = PlayingScreen
    }


-- ============================================================================
-- SECCIÓN 3: RENDERIZADO
-- ============================================================================

-- Renderizar el estado actual del juego
renderGame :: GameState -> IO Picture
renderGame gameState = 
  return $ render gameState  -- Usa la función render de Renderizar.hs

-- ============================================================================
-- SECCIÓN 4: ACTUALIZACIÓN DEL JUEGO (GAME LOOP)
-- ============================================================================

-- Actualizar el juego cada frame (60 FPS)
updateGame :: Float -> GameState -> IO GameState
updateGame deltaTime gameState = do
  case currentScreen gameState of
    MenuScreen _ -> return gameState  -- No actualizar en menú
    PlayingScreen -> updatePlayingGame deltaTime gameState
    GameOverScreen _ -> return gameState  -- No actualizar en game over

-- Actualizar el juego mientras se está jugando
updatePlayingGame :: Float -> GameState -> IO GameState
updatePlayingGame deltaTime gameState =
  let tanksOld = tanks gameState

      -- Paso 1: Actualizar cada tanque (movimiento y rotación)
      tanks' = map (updateTankWithAI gameState deltaTime) tanksOld

      -- Paso 2: Crear proyectiles de bots que deciden disparar
      -- También resetear cooldown de bots que dispararon
      (botProjectiles, tanksWithBotCooldownReset) =
        let shoot tank =
              if any (== Shoot) (decideActions tank tanksOld (projectiles gameState))
                 && turretCooldown (tankTurret tank) <= 0 && tankId tank /= 0
              then (Just (createProjectile tank (tankId tank)), True)
              else (Nothing, False)
            results = [shoot tank | tank <- tanksOld]
            botProjs = concat [[p | Just p <- [fst r]] | r <- results]
            tanksWithReset = zipWith (\tank (_, shot) -> if shot then let turret = tankTurret tank in tank { tankTurret = turret { turretCooldown = 1.5 } } else tank) tanks' results
        in (botProjs, tanksWithReset)

      -- Paso 3: Decrementar cooldowns de todas las torretas
      tanksWithCooldown = updateTurretCooldowns deltaTime [] tanksOld tanksWithBotCooldownReset

      -- Paso 3.5: Daño por contacto (implementación mínima usando tankMemory)
      contactDamage = 2
      contactCooldown = 0.5
      nowTime = gameTime gameState
      applyContact t =
        let (w, h) = tankSize t
            pad = 12.0
            paddedSize = (w + pad, h + pad)
            touching = positionCollidesWithLine (tankPosition t) paddedSize (concatMap id obstaculos)
            lastContact = case lookup "lastContact" (tankMemory t) of
                            Just (MemDouble v) -> v
                            _ -> -1e9
            nowTimeD = realToFrac nowTime :: Double
            contactCooldownD = realToFrac contactCooldown :: Double
        in if touching && (nowTimeD - lastContact) >= contactCooldownD
           then let newMem = ("lastContact", MemDouble nowTimeD) : filter (\(k, _) -> k /= "lastContact") (tankMemory t)
                    newHealth = max 0 (tankHealth t - contactDamage)
                in t { tankHealth = newHealth, tankMemory = newMem }
           else t
      tanksAfterContact = map applyContact tanksWithCooldown

      -- Paso 4: Actualizar posición de todos los proyectiles (movimiento + rebotes)
      projectiles' = [updateProjectile deltaTime proj | proj <- projectiles gameState ++ botProjectiles]

      -- Paso 5: Detectar colisiones proyectil-tanque y aplicar daño
      (tanksAfterDamage, projectilesAfterCollision, newExplosions) = applyProjectileDamage tanksAfterContact projectiles'

      -- Paso 6: Separar tanques vivos de muertos (crear explosiones de muerte)
      (tanksAlive, deathExplosions) = separateLivingAndDeadTanks tanksAfterDamage

      -- Paso 7: Filtrar proyectiles que salieron de pantalla
      projectilesFiltered = [proj | proj <- projectilesAfterCollision, not (isOffScreen proj)]

      -- Paso 8: Actualizar duración de explosiones (decrementar tiempo de vida)
      explosionsUpdated = [(pos, age - deltaTime) | (pos, age) <- explosions gameState ++ newExplosions ++ deathExplosions, age > 0]

      -- Paso 9: Verificar condiciones de game over
      playerAlive = any (\t -> tankId t == 0 && tankHealth t > 0) tanksAlive
      botsAlive = any (\t -> tankId t /= 0 && tankHealth t > 0) tanksAlive

      newScreen = if not playerAlive then GameOverScreen False else if not botsAlive then GameOverScreen True else PlayingScreen
  in return gameState
       { gameTime = gameTime gameState + deltaTime
       , tanks = tanksAlive
       , projectiles = projectilesFiltered
       , explosions = explosionsUpdated
       , currentScreen = newScreen
       }

-- ============================================================================
-- SECCIÓN 6: COOLDOWN DE TORRETAS
-- ============================================================================

-- Decrementar cooldown de todas las torretas cada frame
-- El reset del cooldown ocurre:
--   - En handleEvent para el jugador (0.8s)
--   - En updateGame para los bots (1.5s)
updateTurretCooldowns :: Float -> [Projectile] -> [Tank] -> [Tank] -> [Tank]
updateTurretCooldowns dt _ _ tanksUpdated =
  map (\tank -> 
    let turret = tankTurret tank
        -- Decrementar cooldown sin dejar que sea negativo
        newCooldown = max 0 (turretCooldown turret - realToFrac dt)
    in tank { tankTurret = turret { turretCooldown = newCooldown } }
  ) tanksUpdated

-- ============================================================================
-- SECCIÓN 5: ACTUALIZACIÓN DE TANQUES
-- ============================================================================

-- Actualizar un tanque según si es jugador (controles) o bot (IA)
-- El tanque con tankId 0 es el jugador, los demás (1, 2, ...) son bots
updateTankWithAI :: GameState -> Float -> Tank -> Tank
updateTankWithAI gameState dt tank
  | tankId tank == 0 = updateTank gameState dt tank          -- Jugador: controles WASD + ratón
  | otherwise = updateBotTank gameState dt tank      -- Bot: IA automática

-- Actualizar tanque del jugador: movimiento con WASD y turreta con ratón
updateTank :: GameState -> Float -> Tank -> Tank
updateTank gameState dt tank = 
  -- Paso 1: Calcular rotación del tanque (A/D)
  let rotationInput = calculateRotation (keysPressed gameState)
      newAngle = tankAngle tank + rotationInput * realToFrac dt * tankRotationSpeed tank
      
      -- Paso 2: Calcular dirección del tanque basada en el nuevo ángulo
      angleRad = newAngle * pi / 180
      tankDirection = (cos angleRad, -sin angleRad)  -- Y invertido para Gloss
      
      -- Paso 3: Calcular movimiento adelante/atrás (W/S)
      movementInput = calculateMovementForward (keysPressed gameState)
      movementVec = scaleVector (movementInput * realToFrac dt * tankMoveSpeed tank) tankDirection
      newPos = addPositions (tankPosition tank) movementVec
      
      -- Paso 4: Comprobar colisiones con arena y obstáculos
      collidesArena = positionCollidesWithLine newPos (tankSize tank) arenaLimites
      collidesObstacles = positionCollidesWithLine newPos (tankSize tank) (concatMap id obstaculos)
      finalPos = if collidesArena || collidesObstacles
                 then tankPosition tank          -- Si colisiona, mantener posición
                 else newPos                     -- Si no, usar nueva posición
      
      -- Paso 5: Actualizar tanque con movimiento
      tank1 = tank { tankPosition = finalPos, tankAngle = newAngle }
      
      -- Paso 6: Apuntar turreta hacia el ratón (independiente del ángulo del tanque)
      tankCenter = tankPosition tank1
      mousePosition = mousePos gameState
      dirToMouse = (fst mousePosition - fst tankCenter, -(snd mousePosition - snd tankCenter))
      normalizedDir = normalizeVector dirToMouse
      
      -- Paso 7: Actualizar turreta con dirección hacia el ratón
      oldTurret = tankTurret tank1
      newTurret = oldTurret { turretDirection = normalizedDir }
  in tank1 { tankTurret = newTurret }

-- Actualizar tanque bot: movimiento según IA y turreta apuntando al enemigo más cercano
updateBotTank :: GameState -> Float -> Tank -> Tank
updateBotTank gameState dt tank =
  -- Paso 1: Decidir acciones usando IA (MoveTank, Shoot, etc.)
  let allTanks = tanks gameState
      actions = decideActions tank allTanks (projectiles gameState)
      
      -- Paso 2: Aplicar todas las acciones (movimiento, rotación, etc.)
      tank1 = applyBotActions dt tank actions
      
      -- Paso 3: Apuntar turreta hacia el enemigo más cercano
      otherTanks = filter (/= tank) allTanks
  in if null otherTanks
     then tank1  -- Sin enemigos: mantener turreta como está
     else let closestEnemy = minimumBy (\t1 t2 -> compare (distanceBetweenTanks tank t1) (distanceBetweenTanks tank t2)) otherTanks
              dirToEnemy = (fst (tankPosition closestEnemy) - fst (tankPosition tank1), 
                           -(snd (tankPosition closestEnemy) - snd (tankPosition tank1)))
              normalizedDir = normalizeVector dirToEnemy
              oldTurret = tankTurret tank1
              newTurret = oldTurret { turretDirection = normalizedDir }
          in tank1 { tankTurret = newTurret }

-- Aplicar todas las acciones del bot de forma secuencial
applyBotActions :: Float -> Tank -> [BotAction] -> Tank
applyBotActions dt tank actions = foldl (applyBotAction dt) tank actions

-- Aplicar una acción individual del bot al tanque
applyBotAction :: Float -> Tank -> BotAction -> Tank
applyBotAction dt tank action = case action of
  -- Movimiento del tanque: mover en dirección especificada
  MoveTank (vx, vy) ->
    let -- Normalizar dirección de movimiento
        (normVx, normVy) = normalizeVector (vx, vy)
        
        -- Convertir vector a ángulo (en grados)
        angleToDir = atan2 (-normVy) normVx * 180 / pi
        currentAngle = tankAngle tank
        
        -- Calcular rotación más corta hacia el objetivo
        angleDiff = angleToDir - currentAngle
        normalizedDiff = if angleDiff > 180 then angleDiff - 360 
                         else if angleDiff < -180 then angleDiff + 360
                         else angleDiff
        
        -- Rotar gradualmente (velocidad limitada)
        maxRotation = tankRotationSpeed tank * realToFrac dt
        actualRotation = if normalizedDiff > 0 
                        then min normalizedDiff maxRotation
                        else max normalizedDiff (-maxRotation)
        newAngle = currentAngle + actualRotation
        
        -- Calcular nuevo movimiento
        movementVec = scaleVector (60 * realToFrac dt) (vx, vy)
        newPos = addPositions (tankPosition tank) movementVec
        
        -- Verificar colisiones
        collidesArena = positionCollidesWithLine newPos (tankSize tank) arenaLimites
        collidesObstacles = positionCollidesWithLine newPos (tankSize tank) (concatMap id obstaculos)
        finalPos = if collidesArena || collidesObstacles then tankPosition tank else newPos
    in tank { tankPosition = finalPos, tankAngle = newAngle }
  
  -- Rotación de turreta (no se usa actualmente)
  RotateTurret angle ->
    let newAngle = tankAngle tank + angle * realToFrac dt * tankRotationSpeed tank
    in tank { tankAngle = newAngle }
  
  -- Disparo (se maneja en updateGame, no aquí)
  Shoot -> tank
  
  -- Recordar información en memoria del tanque
  -- Limitar memoria: eliminar entradas viejas de la misma clave
  Remember key val ->
    let oldMemory = filter (\(k, _) -> k /= key) (tankMemory tank)
        newMemory = (key, val) : take 4 oldMemory  -- Mantener máximo 5 entradas totales
    in tank { tankMemory = newMemory }
  
  -- No hacer nada
  DoNothing -> tank

-- Crear un proyectil desde un tanque
-- El proyectil sale a 35 píxeles del centro del tanque en dirección de la torreta
createProjectile :: Tank -> Int -> Projectile
createProjectile tank ownerTankId =
  let (dirX, dirY) = turretDirection (tankTurret tank)
      -- Invertir Y para coincidir con sistema de coordenadas de Gloss
      dirY' = -dirY
      -- Velocidad del proyectil: 300 píxeles/segundo
      projSpeed = 300
      projVel = (dirX * projSpeed, dirY' * projSpeed)
      -- Posición: aparecer a 35 píxeles del centro en dirección del cañón
      offsetDistance = 35
      (tx, ty) = tankPosition tank
      projPos = (tx + dirX * offsetDistance, ty - dirY * offsetDistance)
  in Projectile
      { projectileDirection = (dirX, dirY')
      , projectileDamage = 10                      -- Daño: 10 HP por impacto
      , projectilePosition = projPos
      , projectileSize = (8, 8)                   -- Tamaño: pequeño cuadrado
      , projectileVelocity = projVel
      , projectileOwner = ownerTankId             -- Guardar ID del tanque propietario
      }

-- Actualizar proyectil: mover y rebotar en obstáculos
updateProjectile :: Float -> Projectile -> Projectile
updateProjectile dt proj =
  let (vx, vy) = projectileVelocity proj
      (px, py) = projectilePosition proj
      (w, h) = projectileSize proj
      -- Nueva posición después del movimiento
      newPos = (px + vx * realToFrac dt, py + vy * realToFrac dt)
      
      -- Buscar colisión con obstáculos
      allObstacleLines = concatMap id obstaculos
      collidedObs = foldr (\obs acc -> 
        if acc == Nothing && positionCollidesWithLine newPos (w, h) [obs]
        then Just obs
        else acc) Nothing allObstacleLines
  in case collidedObs of
       Just obs -> 
         -- Rebote: reflejar velocidad en el obstáculo
         let newVel = reflectVector (vx, vy) obs
         in proj { projectilePosition = newPos, projectileVelocity = newVel }
       Nothing -> 
         -- Sin rebote: solo actualizar posición
         proj { projectilePosition = newPos }

-- Comprobar si un proyectil está fuera de pantalla
-- Si está muy lejos, se descarta en el siguiente frame
isOffScreen :: Projectile -> Bool
isOffScreen proj =
  let (x, y) = projectilePosition proj
      limit = 600  -- Margen más grande que la ventana (±512)
  in x < -limit || x > limit || y < -limit || y > limit

-- ============================================================================
-- SECCIÓN 8: COLISIONES Y DAÑO
-- ============================================================================

-- Detectar colisión entre proyectil y tanque usando AABB (rectángulos)
projectileCollidesWithTank :: Projectile -> Tank -> Bool
projectileCollidesWithTank proj tank =
  let (px, py) = projectilePosition proj
      (pw, ph) = projectileSize proj
      (tx, ty) = tankPosition tank
      (tw, th) = tankSize tank
      
      -- Bordes del rectángulo del proyectil
      projLeft = px - pw / 2
      projRight = px + pw / 2
      projTop = py - ph / 2
      projBottom = py + ph / 2
      
      -- Bordes del rectángulo del tanque
      tankLeft = tx - tw / 2
      tankRight = tx + tw / 2
      tankTop = ty - th / 2
      tankBottom = ty + th / 2
  -- Colisión AABB: hay superposición en ambos ejes
  in projLeft < tankRight && projRight > tankLeft &&
     projTop < tankBottom && projBottom > tankTop

-- Aplicar daño de proyectiles a tanques
-- Retorna: (tanques actualizados, proyectiles restantes, nuevas explosiones)
applyProjectileDamage :: [Tank] -> [Projectile] -> ([Tank], [Projectile], [(Position, Float)])
applyProjectileDamage tanks projectiles =
  let -- Para cada proyectil, detectar colisión con algún tanque
      (tanksAfterDamage, projectilesAfterCollision, explosionsList) = 
        foldr (\proj (tanksAcc, projsAcc, explAcc) ->
          let -- Buscar tanque que colisiona
              collisionTank = foldr (\tank acc -> 
                if acc == Nothing && projectileCollidesWithTank proj tank
                then Just tank
                else acc) Nothing tanksAcc
          in case collisionTank of
               Just tank ->
                 -- Hay colisión: aplicar daño al tanque
                 let damage = projectileDamage proj
                     newHealth = max 0 (tankHealth tank - damage)
                     damagedTank = tank { tankHealth = newHealth }
                     -- Reemplazar tanque dañado en la lista
                     tanksAfterDmg = map (\t -> if t == tank then damagedTank else t) tanksAcc
                     -- Crear explosión en punto de impacto (0.5s duración)
                     explosion = (projectilePosition proj, 0.5)
                 in (tanksAfterDmg, projsAcc, explosion : explAcc)
               Nothing ->
                 -- Sin colisión: mantener proyectil
                 (tanksAcc, proj : projsAcc, explAcc)
        ) (tanks, [], []) projectiles
  in (tanksAfterDamage, reverse projectilesAfterCollision, explosionsList)

-- Separar tanques vivos de muertos y crear explosiones de muerte
-- Tanques muertos = salud <= 0
separateLivingAndDeadTanks :: [Tank] -> ([Tank], [(Position, Float)])
separateLivingAndDeadTanks tanks =
  let (alive, dead) = partition (\t -> tankHealth t > 0) tanks
      -- Crear explosión grande (duración 1.0s) en la posición de cada tanque muerto
      deathExplosions = [(tankPosition t, 1.0) | t <- dead]
  in (alive, deathExplosions)

-- ============================================================================
-- SECCIÓN 9: ENTRADA Y EVENTOS
-- ============================================================================

-- Manejar eventos de entrada (teclado y ratón)
handleEvent :: Event -> GameState -> IO GameState
handleEvent event gameState = do
  case currentScreen gameState of
    MenuScreen numBots -> handleMenuEvent event numBots gameState
    PlayingScreen -> handleGameEvent event gameState
    GameOverScreen _ -> handleGameOverEvent event gameState

-- Manejar eventos en el menú
handleMenuEvent :: Event -> Int -> GameState -> IO GameState
handleMenuEvent event numBots gameState = do
  case event of
    -- SPACE: Iniciar juego
    EventKey (SpecialKey KeySpace) Down _ _ -> startGame numBots gameState
    
    -- UP: Incrementar número de bots (máximo 5)
    EventKey (SpecialKey KeyUp) Down _ _ -> 
      return $ gameState { currentScreen = MenuScreen (min 5 (numBots + 1)) }
    
    -- DOWN: Decrementar número de bots (mínimo 1)
    EventKey (SpecialKey KeyDown) Down _ _ -> 
      return $ gameState { currentScreen = MenuScreen (max 1 (numBots - 1)) }
    
    _ -> return gameState

-- Manejar eventos durante el juego
handleGameEvent :: Event -> GameState -> IO GameState
handleGameEvent event gameState = do
  case event of
    -- ESC: Volver al menú
    EventKey (SpecialKey KeyEsc) Down _ _ -> 
      return $ gameState { currentScreen = MenuScreen 2, tanks = [], projectiles = [], explosions = [] }
    
    -- Clic izquierdo del ratón: disparar
    EventKey (MouseButton LeftButton) Down _ _ -> do
      let newProjectiles = case tanks gameState of
            (tank:_) -> 
              if turretCooldown (tankTurret tank) <= 0
              then projectiles gameState ++ [createProjectile tank (tankId tank)]
              else projectiles gameState
            [] -> projectiles gameState
          -- Resetear cooldown del jugador si disparó
          updatedTanks = case tanks gameState of
            (tank:rest) -> 
              if turretCooldown (tankTurret tank) <= 0 && length newProjectiles > length (projectiles gameState)
              then let turret = tankTurret tank
                       newTurret = turret { turretCooldown = 0.8 }
                   in (tank { tankTurret = newTurret }) : rest
              else (tank:rest)
            [] -> []
      return $ gameState { projectiles = newProjectiles, tanks = updatedTanks }
    
    -- Tecla de carácter presionada
    EventKey (Char c) Down _ _ -> 
      return $ gameState { keysPressed = c : keysPressed gameState }
    
    -- Tecla de carácter soltada
    EventKey (Char c) Up _ _ -> 
      return $ gameState { keysPressed = filter (/= c) (keysPressed gameState) }
    
    -- Tecla especial presionada
    EventKey (SpecialKey key) Down _ _ ->
      return $ gameState { keysPressed = (specialKeyToChar key) : keysPressed gameState }
    
    -- Tecla especial soltada
    EventKey (SpecialKey key) Up _ _ ->
      return $ gameState { keysPressed = filter (/= specialKeyToChar key) (keysPressed gameState) }
    
    -- Movimiento del ratón
    EventMotion (x, y) -> 
      return $ gameState { mousePos = (realToFrac x, realToFrac y) }
    
    _ -> return gameState

-- Manejar eventos en game over
handleGameOverEvent :: Event -> GameState -> IO GameState
handleGameOverEvent event gameState = do
  case event of
    -- ESC: Volver al menú
    EventKey (SpecialKey KeyEsc) Down _ _ -> 
      return $ gameState { currentScreen = MenuScreen 2, tanks = [], projectiles = [], explosions = [] }
    _ -> return gameState

-- ============================================================================
-- SECCIÓN 10: UTILIDADES DE ENTRADA
-- ============================================================================

-- Calcular rotación del tanque según teclas A/D
-- Retorna: -1 (izquierda), 0 (nada) o 1 (derecha)
calculateRotation :: [Char] -> Double
calculateRotation keys = 
  let a = if 'a' `elem` keys then -1 else 0
      d = if 'd' `elem` keys then 1 else 0
  in a + d

-- Calcular movimiento adelante/atrás según teclas W/S
-- Retorna: -1 (atrás), 0 (nada) o 1 (adelante)
calculateMovementForward :: [Char] -> Double
calculateMovementForward keys = 
  let w = if 'w' `elem` keys then 1 else 0
      s = if 's' `elem` keys then -1 else 0
  in w + s

-- Normalizar un vector a longitud 1
-- Si el vector es cero, retorna (1, 0)
normalizeVector :: Tipos.Vector -> Tipos.Vector
normalizeVector (x, y) =
  let len = sqrt (x ** 2 + y ** 2)
  in if len == 0 then (1, 0) else (x / len, y / len)

-- Convertir teclas especiales a caracteres únicos para procesarlas
specialKeyToChar :: SpecialKey -> Char
specialKeyToChar KeyUp    = '↑'
specialKeyToChar KeyDown  = '↓'
specialKeyToChar KeyLeft  = '←'
specialKeyToChar KeyRight = '→'
specialKeyToChar _ = ' '

-- ============================================================================
-- SECCIÓN 11: FUNCIÓN PRINCIPAL
-- ============================================================================

-- Punto de entrada del programa
main :: IO ()
main = do
  -- Inicializar GLUT antes de usar texto
  progName <- getProgName
  (_progName, _args) <- GLUT.getArgsAndInitialize
  
  gameState <- loadGameResources  -- Cargar recursos (sprites)
  playIO
    windowDisplay          -- Ventana del juego
    backgroundColor        -- Color de fondo
    120                    -- 120 FPS
    gameState              -- Estado inicial (en menú)
    renderGame             -- Función de renderizado
    handleEvent            -- Función de eventos
    updateGame             -- Función de actualización
