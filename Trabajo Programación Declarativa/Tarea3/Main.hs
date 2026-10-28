module Main where

import Tipos
import Fisica
import Comportamiento
import Colisiones
import Memoria
import IA

-- ============================================================================
-- FUNCIONES DE DEMOSTRACIÓN
-- ============================================================================

-- Demostrar física con GameObject
demoPhysics :: Tank -> Tank -> Distance
demoPhysics = distanceBetweenTanks

-- Demostrar sistema de memoria
demoMemorySystem :: Tank -> Tank
demoMemorySystem tank = 
  let tank1 = rememberTank tank "enemigoDetectado" (MemBool True)
      tank2 = rememberTank tank1 "disparosRealizados" (MemInt 5)
  in tank2

-- Demostrar sistema de colisiones
demoCollisionSystem :: ([Tank], [Projectile]) -> ([(Tank, Tank)], [(Tank, Projectile)])
demoCollisionSystem (tanks, projectiles) = checkCollisions tanks projectiles

-- Demostrar IA
demoIA :: Tank -> [Tank] -> [Projectile] -> [BotAction]
demoIA = decideActions

-- Demostrar GameObject
demoGameObjectBehavior :: IO ()
demoGameObjectBehavior = do
  let tank = createExampleTank
  let tankObj = tankToObject tank
  let movedObj = moveObject tankObj (5.0, 2.0)
  let updatedObj = updateObjectBehavior movedObj 1.0
  putStrLn $ "GameObject: " ++ show (getObjectPosition tankObj) ++ " → " ++ show (getObjectPosition updatedObj)

-- ============================================================================
-- FUNCIÓN PRINCIPAL PARA DEMOSTRAR LA IMPLEMENTACIÓN COMPLETA
-- ============================================================================

main :: IO ()
main = do
  let tank1 = createExampleTank
  let tank2 = createExampleTank { tankPosition = (3,0), tankSize = (2,1) }
  let projectile = createExampleProjectile
  
  putStrLn "=== APARTADOS IMPLEMENTADOS ==="
  
  let (tankCols, projCols) = demoCollisionSystem ([tank1, tank2], [projectile])
  putStrLn $ "Colisiones: " ++ show (length tankCols) ++ " tanque-tanque, " ++ show (length projCols) ++ " tanque-proyectil"
  
  let tankObj = tankToObject tank1
  putStrLn $ "GameObject - Posición: " ++ show (getObjectPosition tankObj) ++ ", Salud: " ++ show (getObjectHealth tankObj)
  
  let tankWithMem = demoMemorySystem tank1
  putStrLn $ "Memoria: " ++ show (length (tankMemory tankWithMem)) ++ " entradas"
  
  let actions = demoIA tank1 [tank1, tank2] [projectile]
  putStrLn $ "IA: " ++ show (length actions) ++ " acciones generadas"
  
  demoGameObjectBehavior

  