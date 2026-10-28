import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game

-- Estado: posición (x, y)
type Estado = (Float, Float)

-- Dibujo del círculo en la posición actual
dibujar :: Estado -> Picture
dibujar (x, y) = Translate x y $ Color blue $ circleSolid 30

-- Manejador de eventos del teclado
manejarEvento :: Event -> Estado -> Estado
manejarEvento (EventKey (SpecialKey KeyLeft)  Down _ _) (x, y) = (x - 10, y)
manejarEvento (EventKey (SpecialKey KeyRight) Down _ _) (x, y) = (x + 10, y)
manejarEvento (EventKey (SpecialKey KeyUp)    Down _ _) (x, y) = (x, y + 10)
manejarEvento (EventKey (SpecialKey KeyDown)  Down _ _) (x, y) = (x, y - 10)
manejarEvento _ estado = estado

-- Actualización (aquí no cambia nada con el tiempo)
actualizar :: Float -> Estado -> Estado
actualizar _ estado = estado

-- Punto de entrada principal
main :: IO ()
main = play
  (InWindow "Mover Círculo" (400, 400) (10, 10)) -- ventana
  white                                           -- fondo
  60                                              -- FPS
  (0, 0)                                          -- estado inicial
  dibujar                                         -- función de dibujo
  manejarEvento                                   -- función de eventos
  actualizar                                      -- función de actualización
