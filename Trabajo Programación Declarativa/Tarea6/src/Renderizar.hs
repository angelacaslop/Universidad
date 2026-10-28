module Renderizar where 

import Graphics.Gloss
import Graphics.Gloss.Data.Color
import Graphics.Gloss.Data.Picture (text)
import Tipos

-- ============================================================================
-- RENDERIZADO DE MENÚ
-- ============================================================================

-- Dibujar menú principal
dibujarMenu :: Int -> Picture
dibujarMenu numBots =
  Pictures
    [ -- Fondo oscuro
      color (makeColor 0.1 0.1 0.15 1) $ rectangleSolid 1000 800
    
    -- Título del juego
    , translate (-200) 250 $ scale 0.5 0.5 $ color white $ text "TANK BATTLE"
    
    -- Botón START
    , translate 0 100 $ Pictures
        [ color (makeColor 0.2 0.5 0.2 1) $ rectangleSolid 300 80  -- Verde oscuro
        , translate (-130) (-10) $ scale 0.3 0.3 $ color yellow $ text "PRESS SPACE"
        ]
    
    -- Selector de número de bots
    , translate 0 (-50) $ Pictures
        [ color (greyN 0.3) $ rectangleSolid 400 100
        , translate (-170) 20 $ scale 0.2 0.2 $ color white $ text "NUMBER OF BOTS:"
        -- Círculos para representar cantidad de bots
        , translate (-120) (-20) $ Pictures (dibujarCirculosBots numBots)
        , translate 140 (-25) $ scale 0.4 0.4 $ color yellow $ text (show numBots)
        ]
    
    -- Controles arriba/abajo
    , translate 0 (-150) $ Pictures
        [ translate (-10) 0 $ color cyan $ polygon [(0, 15), (-10, 0), (10, 0)]  -- Flecha arriba
        , translate (-10) (-30) $ color cyan $ polygon [(0, -15), (-10, 0), (10, 0)]  -- Flecha abajo
        , translate 20 (-5) $ scale 0.15 0.15 $ color white $ text "UP/DOWN"
        ]
    
    -- Instrucciones de juego
    , translate 0 (-250) $ Pictures
        [ color (makeColor 0.2 0.2 0.3 1) $ rectangleSolid 500 140
        , translate (-240) 50 $ scale 0.15 0.15 $ color white $ text "CONTROLS:"
        , translate (-240) 30 $ scale 0.13 0.13 $ color white $ text "WASD: Move"
        , translate (-240) 10 $ scale 0.13 0.13 $ color white $ text "MOUSE: Aim"
        , translate (-240) (-10) $ scale 0.13 0.13 $ color white $ text "CLICK: Shoot"
        , translate (-240) (-30) $ scale 0.13 0.13 $ color white $ text "ESC: Return to menu"
        ]
    ]

-- Dibujar círculos para representar número de bots
dibujarCirculosBots :: Int -> [Picture]
dibujarCirculosBots n = 
  [ translate (fromIntegral i * 50) 0 $ 
    color (if i < n then yellow else greyN 0.5) $ 
    circleSolid 15
  | i <- [0..4]  -- Máximo 5 bots
  ]

-- Dibujar pantalla de game over
dibujarGameOver :: Bool -> Picture
dibujarGameOver isVictory =
  Pictures
    [ -- Fondo semi-transparente
      color (makeColor 0 0 0 0.7) $ rectangleSolid 1000 800
    
    -- Mensaje principal
    , translate (-150) 100 $ scale 0.5 0.5 $ 
      color (if isVictory then green else red) $
      text (if isVictory then "VICTORY!" else "DEFEAT!")
    
    -- Símbolo visual grande
    , translate 0 0 $ 
      if isVictory 
      then color green $ polygon [(-50, 0), (-15, -15), (0, -50), (15, -15), (50, 0), (15, 15), (0, 50), (-15, 15)]  -- Estrella
      else color red $ Pictures  -- X grande
          [ line [(-50, -50), (50, 50)]
          , line [(-50, 50), (50, -50)]
          ]
    
    -- Instrucción para volver
    , translate (-180) (-100) $ scale 0.25 0.25 $ color white $ 
      text "PRESS ESC TO RETURN"
    ]

-- ============================================================================
-- RENDERIZADO DEL JUEGO
-- ============================================================================

-- Dibujar TANQUE COMPLETO usando sprites
dibujarTanque :: Tank -> GameState -> Picture
dibujarTanque tank gameState = 
  let (x, y) = tankPosition tank
      angle = realToFrac (tankAngle tank)
      (w, h) = tankSize tank
      turret = tankTurret tank
      (dirX, dirY) = turretDirection turret
      -- Ángulo en grados para rotación de la torreta
      cannonAngle = atan2 (realToFrac dirY) (realToFrac dirX) * 180 / pi
  in Pictures
      [ -- Base del tanque (rotada con el tanque)
        translate (realToFrac x) (realToFrac y) $
        rotate angle $
        case tankBodySprite gameState of
          Just sprite -> scale 0.2 0.2 sprite
          Nothing -> rectangleSolid (realToFrac w) (realToFrac h)
      
      -- Torreta (rotada según dirección a donde apunta, no con el tanque)
      , translate (realToFrac x) (realToFrac y) $
        rotate cannonAngle $
        case tankTurretSprite gameState of
          Just sprite -> scale 0.15 0.15 sprite
          Nothing -> color (makeColor 0.8 0.8 0.8 1) $ circleSolid (realToFrac h / 2 - 2)
      ]

-- Dibujar PROYECTIL usando sprite
dibujarProyectil :: Projectile -> GameState -> Picture
dibujarProyectil proj gameState =
  let (x, y) = projectilePosition proj
      (w, _) = projectileSize proj
      (vx, vy) = projectileVelocity proj
      angle = atan2 (realToFrac vy) (realToFrac vx) * 180 / pi
  in translate (realToFrac x) (realToFrac y) $
     rotate angle $
     case bulletSprite gameState of
       Just sprite -> scale (realToFrac w / 10) (realToFrac w / 10) sprite
       Nothing -> color red $ circleSolid (realToFrac w / 2)

-- Obtener color del tanque basado en su ID
obtenerColorTanque :: Int -> Color
obtenerColorTanque tankId
  | tankId == 0 = makeColor 0.2 1.0 0.2 1.0  -- Verde brillante para jugador
  | tankId == 1 = makeColor 0.2 0.5 1.0 1.0  -- Azul para bot 1
  | tankId == 2 = makeColor 1.0 0.2 0.2 1.0  -- Rojo para bot 2
  | tankId == 3 = makeColor 1.0 1.0 0.2 1.0  -- Amarillo para bot 3
  | tankId == 4 = makeColor 1.0 0.5 0.0 1.0  -- Naranja para bot 4
  | tankId == 5 = makeColor 0.8 0.2 1.0 1.0  -- Morado para bot 5
  | otherwise = makeColor 0.5 0.5 0.5 1.0    -- Gris para otros

-- Dibujar EXPLOSIÓN usando frames de animación
dibujarExplosion :: (Position, Float) -> GameState -> Picture
dibujarExplosion ((x, y), age) gameState =
  let frames = explosionFrames gameState
      numFrames = length frames
      frameIndex = if numFrames == 0 then 0 else min (numFrames - 1) (round ((1.0 - age) * fromIntegral numFrames / 1.0))
  in translate (realToFrac x) (realToFrac y) $
     if numFrames == 0 || frameIndex >= numFrames
     then Pictures 
            [ color (makeColor 1 0.6 0 0.8) (circleSolid 20)
            , color (makeColor 1 0.3 0 0.6) (circleSolid 12)
            , color (makeColor 1 1 0 0.4)   (circleSolid 6)
            ]
     else scale 0.5 0.5 (frames !! frameIndex)

-- Dibujar BARRA DE VIDA de un tanque
dibujarBarraVida :: Tank -> Picture
dibujarBarraVida tank =
  let (x, y) = tankPosition tank
      (w, h) = tankSize tank
      vida = tankHealth tank
      vidaMaxima = 100  -- Vida máxima
      porcentaje = min 1.0 (vida / vidaMaxima)
      barWidth = realToFrac w
      barHeight = 3
      -- Posicionar la barra encima del tanque
      barY = realToFrac y + (realToFrac h / 2) + 15
      barColor = obtenerColorTanque (tankId tank)
  in translate (realToFrac x) barY $
     Pictures
       [ color (greyN 0.3) $ rectangleSolid barWidth barHeight  -- Fondo gris
       , color barColor $ 
         rectangleSolid (barWidth * realToFrac porcentaje) barHeight  -- Vida en color del tanque
       ]

-- Dibujar HUD con información del juego
dibujarHUD :: GameState -> Picture
dibujarHUD gameState =
  let tiempo = gameTime gameState
      minutos = floor tiempo `div` 60
      segundos = floor tiempo `mod` 60
      tiempoStr = (if minutos < 10 then "0" else "") ++ show minutos ++ ":" ++ 
                  (if segundos < 10 then "0" else "") ++ show segundos
      
      robotsVivos = length (tanks gameState)
      
      -- Posición en la esquina superior izquierda
      hudX = -320  -- Esquina superior izquierda
      hudY = 360   -- Margen desde arriba
      
  in Pictures
      [ -- Panel semi-transparente de fondo (más ancho)
        translate hudX hudY $ color (makeColor 0 0 0 0.5) $ rectangleSolid 200 100
        
        -- Tiempo de juego
      , translate (hudX - 90) (hudY + 25) $ scale 0.15 0.15 $ color white $ text "TIME:"
      , translate (hudX - 90) (hudY + 5) $ scale 0.2 0.2 $ color yellow $ text tiempoStr
        
        -- Robots vivos
      , translate (hudX - 90) (hudY - 25) $ scale 0.15 0.15 $ color white $ text "ROBOTS:"
      , translate (hudX - 90) (hudY - 45) $ scale 0.2 0.2 $ color yellow $ text (show robotsVivos)
      ]

-- Dibujar JUEGO COMPLETO
dibujarJuego :: GameState -> Picture
dibujarJuego gameState =
  Pictures
    [ -- Fondo
      case backgroundImage gameState of
        Just bgImg -> bgImg
        Nothing -> color (makeColor 0.2 0.2 0.2 1) $ rectangleSolid 1000 800
    
    -- Tanques
    , Pictures [dibujarTanque tank gameState | tank <- tanks gameState]
    
    -- Barras de vida
    , Pictures [dibujarBarraVida tank | tank <- tanks gameState]
    
    -- Proyectiles
    , Pictures [dibujarProyectil proj gameState | proj <- projectiles gameState]
    
    -- Explosiones
    , Pictures [dibujarExplosion exp gameState | exp <- explosions gameState]
    
    -- HUD (tiempo y robots vivos)
    , dibujarHUD gameState
    ]

-- ============================================================================
-- FUNCIÓN PRINCIPAL DE RENDERIZADO
-- ============================================================================

-- Renderizar según la pantalla actual
render :: GameState -> Picture
render gameState =
  case currentScreen gameState of
    MenuScreen numBots -> dibujarMenu numBots
    PlayingScreen -> dibujarJuego gameState
    GameOverScreen isVictory -> Pictures [dibujarJuego gameState, dibujarGameOver isVictory]
