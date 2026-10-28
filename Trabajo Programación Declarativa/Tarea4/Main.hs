import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game

-- | ANCHO Y ALTO DE LA PANTALLA
screenWidth, screenHeight :: Int
screenWidth = 800
screenHeight = 600

-- | Posición del suelo
groundLevel :: Float
groundLevel = -fromIntegral screenHeight / 2 + 50

-- | Constantes de física
gravity :: Float
gravity = -1080.0 -- Aceleración hacia abajo

jumpVelocity :: Float
jumpVelocity = 500.0 -- Impulso inicial del salto

moveSpeed :: Float
moveSpeed = 300.0 -- Velocidad de movimiento horizontal

-- | Altura del personaje (desde el centro hasta los pies)
playerHeight :: Float
playerHeight = 40.0

-- | Tipos de datos para el estado del juego
data Direction = ToLeft | ToRight deriving (Show, Eq)

data GameState = GameState
  { playerPos       :: (Float, Float)   -- (x, y)
  , playerVel       :: (Float, Float)   -- (vx, vy)
  , playerDir       :: Direction        -- Hacia dónde mira
  , onGround        :: Bool             -- ¿Está en el suelo?
  , walkingTime     :: Float            -- Para la animación de caminar
  } deriving (Show)

-- | Estado inicial del juego
initialState :: GameState
initialState = GameState
  { playerPos = (0, groundLevel + 40)  -- +40 para que los pies estén sobre el suelo
  , playerVel = (0, 0)
  , playerDir = ToRight
  , onGround = True
  , walkingTime = 0
  }

-- | DIBUJAR EL JUEGO ------------------------------------------------
-- Dibuja el suelo
drawGround :: Picture
drawGround = Translate 0 (groundLevel - 50) $ Color green $ rectangleSolid (fromIntegral screenWidth) 100

drawPlayer :: GameState -> Picture
drawPlayer state =
  let
    (px, py) = playerPos state
    dir = playerDir state
    time = walkingTime state
    (vx, _) = playerVel state
    walking = abs vx > 1

    -- === Animaciones ===
    legAngle = if onGround state && walking then sin (time * 15) * 12 else 0
    armAngle = if onGround state && walking then sin (time * 15 + pi) * 10 else 0
    headTurn | vx > 20 = -6
             | vx < -20 = 6
             | otherwise = 0
    eyeShift | vx > 20 = 2
             | vx < -20 = -2
             | otherwise = 0

    -- === CABEZA (proporcionada y centrada) ===
    cabezaExterior = Color (makeColorI 0 122 255 255) $ circleSolid 45
    caraBlanca = Color white $ Translate 0 (-5) $ circleSolid 35
    ojoIzq = Translate (-10) 22 $ Color white $ circleSolid 6
    ojoDer = Translate (10) 22 $ Color white $ circleSolid 6
    pupilaIzq = Translate (-10 + eyeShift) 22 $ Color black $ circleSolid 2
    pupilaDer = Translate (10 + eyeShift) 22  $ Color black $ circleSolid 2
    nariz = Translate 0 10 $ Color red $ circleSolid 4
    lineaCentro = Color black $ Line [(0, 5), (0, -15)]
    boca = Color black $ Arc (-180) 0 15
    bigotesIzq = Pictures
      [ Line [(-18, 3), (-30, 7)]
      , Line [(-18, -2), (-30, -2)]
      , Line [(-18, -7), (-30, -11)]
      ]
    bigotesDer = Pictures
      [ Line [(18, 3), (30, 7)]
      , Line [(18, -2), (30, -2)]
      , Line [(18, -7), (30, -11)]
      ]
    campana = Translate 0 (-46) $
      Pictures
        [ Color yellow $ circleSolid 6
        , Color black $ circle 6
        , Color black $ Line [(-3, -2), (3, -2)]
        ]

    cabeza =
      Translate 0 68 $
      Rotate headTurn $
      Pictures
        [ cabezaExterior, caraBlanca, ojoIzq, ojoDer
        , pupilaIzq, pupilaDer, nariz
        , lineaCentro, boca
        , Color black bigotesIzq, Color black bigotesDer
        , campana
        ]

    -- === CUERPO REDONDO ===
    cuerpoExterior = Color (makeColorI 0 122 255 255) $ circleSolid 30
    panzaBlanca = Color white $ Translate 0 (-5) $ circleSolid 20
    bolsillo = Translate 0 (-12) $
      Color (greyN 0.25) $ Arc (-180) 0 12
    cuerpo = Translate 0 25 $ Pictures [cuerpoExterior, panzaBlanca, bolsillo]

    -- === BRAZOS Y PIERNAS CENTRADOS ===
    brazoIzq = Translate (-28) 30 $
      Rotate armAngle $
      Color (makeColorI 0 122 255 255) $ rectangleSolid 8 20
    brazoDer = Translate (28) 30 $
      Rotate (-armAngle) $
      Color (makeColorI 0 122 255 255) $ rectangleSolid 8 20
    piernaIzq = Translate (-10) (-10) $
      Rotate legAngle $
      Color (makeColorI 0 122 255 255) $ rectangleSolid 10 18
    piernaDer = Translate (10) (-10) $
      Rotate (-legAngle) $
      Color (makeColorI 0 122 255 255) $ rectangleSolid 10 18

    -- === Sombra bajo los pies ===
    sombra = Translate 0 (-50) $
      Color (makeColorI 100 100 100 120) $ Scale 2 0.4 $ circleSolid 10

    -- === Composición final ===
    doraemon = Pictures [sombra, cabeza, cuerpo, brazoIzq, brazoDer, piernaIzq, piernaDer]

    escalaX = if dir == ToRight then 1 else -1
    doraemonOrientado = Scale escalaX 1 doraemon
  in
    Translate px py doraemonOrientado

-- Dibuja la información de controles y posición
drawHUD :: GameState -> Picture
drawHUD state =
  let
    (px, py) = playerPos state
    isOnGround = onGround state

    -- Posición en la esquina superior izquierda
    hudX = -fromIntegral screenWidth / 2 + 20
    hudY = fromIntegral screenHeight / 2 - 30

    -- Texto de controles
    controlsText = Pictures
      [ Translate hudX (hudY - 0)  $ Scale 0.15 0.15 $ Color black $ Text "CONTROLES:"
      , Translate hudX (hudY - 20) $ Scale 0.12 0.12 $ Color black $ Text "W/↑ - Saltar"
      , Translate hudX (hudY - 35) $ Scale 0.12 0.12 $ Color black $ Text "A/← - Izquierda"
      , Translate hudX (hudY - 50) $ Scale 0.12 0.12 $ Color black $ Text "D/→ - Derecha"
      ]

    -- Texto de posición
    positionText = Pictures
      [ Translate hudX (hudY - 80)  $ Scale 0.15 0.15 $ Color red $ Text "POSICION:"
      , Translate hudX (hudY - 100) $ Scale 0.12 0.12 $ Color red $ Text ("X: " ++ show (round px :: Int))
      , Translate hudX (hudY - 115) $ Scale 0.12 0.12 $ Color red $ Text ("Y: " ++ show (if isOnGround then 0 else round (py - (groundLevel + 40)) :: Int))
      ]

    -- Texto de estado (tierra/aire)
    statusText = Pictures
      [ Translate hudX (hudY - 145) $ Scale 0.15 0.15 $ Color blue $ Text "ESTADO:"
      , Translate hudX (hudY - 165) $ Scale 0.12 0.12 $ Color blue $ Text (if isOnGround then "EN TIERRA" else "EN AIRE")
      ]

  in Pictures [controlsText, positionText, statusText]

-- Función principal de renderizado
render :: GameState -> Picture
render state = Pictures [drawGround, drawPlayer state, drawHUD state]

-- | MANEJAR EVENTOS -------------------------------------------------
handleInput :: Event -> GameState -> GameState
handleInput event state = case event of
  -- Mover a la izquierda
  (EventKey (SpecialKey KeyLeft) Down _ _) -> state { playerVel = (-moveSpeed, snd (playerVel state)), playerDir = ToLeft }
  (EventKey (Char 'a') Down _ _)           -> state { playerVel = (-moveSpeed, snd (playerVel state)), playerDir = ToLeft }

  -- Mover a la derecha
  (EventKey (SpecialKey KeyRight) Down _ _) -> state { playerVel = (moveSpeed, snd (playerVel state)), playerDir = ToRight }
  (EventKey (Char 'd') Down _ _)            -> state { playerVel = (moveSpeed, snd (playerVel state)), playerDir = ToRight }

  -- Dejar de moverse
  (EventKey (SpecialKey KeyLeft) Up _ _) | fst (playerVel state) < 0 -> state { playerVel = (0, snd (playerVel state)) }
  (EventKey (Char 'a') Up _ _)           | fst (playerVel state) < 0 -> state { playerVel = (0, snd (playerVel state)) }
  (EventKey (SpecialKey KeyRight) Up _ _) | fst (playerVel state) > 0 -> state { playerVel = (0, snd (playerVel state)) }
  (EventKey (Char 'd') Up _ _)            | fst (playerVel state) > 0 -> state { playerVel = (0, snd (playerVel state)) }

  -- Saltar (solo si está en el suelo)
  (EventKey (SpecialKey KeyUp) Down _ _) | onGround state -> state { playerVel = (fst (playerVel state), jumpVelocity), onGround = False }
  (EventKey (Char 'w') Down _ _)         | onGround state -> state { playerVel = (fst (playerVel state), jumpVelocity), onGround = False }

  -- Ignorar otros eventos
  _ -> state

-- | ACTUALIZAR EL MUNDO (FÍSICA) ------------------------------------
update :: Float -> GameState -> GameState
update dt state =
  let
    (px, py) = playerPos state
    (vx, vy) = playerVel state

    -- Aplicar gravedad si no está en el suelo
    newVy = if onGround state then 0 else vy + gravity * dt

    -- Nueva posición
    newPx = px + vx * dt
    newPy = py + newVy * dt

    -- Límites de la pantalla horizontal
    halfWidth = fromIntegral screenWidth / 2 - 20
    clampedPx = max (-halfWidth) (min halfWidth newPx)

    -- Detección del suelo (considerar que los pies están a -40 del centro del personaje)
    playerBottomY = newPy - 40  -- Posición de los pies del personaje
    (finalPy, finalVy, groundState) =
      if playerBottomY <= groundLevel
        then (groundLevel + 40, 0, True)  -- Posicionar el centro del personaje a groundLevel + 40
        else (newPy, newVy, False)

    -- Actualizar tiempo para animación de caminar
    newWalkingTime = if vx /= 0 && groundState then walkingTime state + dt else 0

  in state
     { playerPos = (clampedPx, finalPy)
     , playerVel = (vx, finalVy)
     , onGround = groundState
     , walkingTime = newWalkingTime
     }

-- | FUNCIÓN PRINCIPAL ----------------------------------------------
main :: IO ()
main = play
  (InWindow "Juego del Monigote" (screenWidth, screenHeight) (10, 10))
  white
  60
  initialState
  render
  handleInput
  update