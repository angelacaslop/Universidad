import Graphics.Gloss

main :: IO ()
main = display ventana fondo imagen
 where
   ventana =
     InWindow
       "Mi Primera Ventana"
       (800, 600)
       (100, 100)
   fondo = white
   imagen = Circle 80
