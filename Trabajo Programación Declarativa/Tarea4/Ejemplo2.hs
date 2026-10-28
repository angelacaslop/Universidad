import Graphics.Gloss

animacion :: Float -> Picture
animacion tiempo =
  let angulo = 50 * tiempo -- La figura rota con el tiempo
  in Rotate angulo (Color green (rectangleSolid 100 100))

main :: IO ()
main = animate
  (InWindow "Animacion" (400, 400) (10, 10))
  white
  animacion