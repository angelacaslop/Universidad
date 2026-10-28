module Memoria
( emptyMemory
, remember
, recall
, forget
, rememberTank
, recallTank
) where


import Tipos(Memory, MemoryValue (..), Tank(..))

-- Crear memoria vacía
emptyMemory :: Memory
emptyMemory = []

-- Guardar o actualizar un valor
remember :: String -> MemoryValue -> Memory -> Memory
remember key val mem =
  (key, val) : filter ((/= key) . fst) mem

-- Recuperar un valor (si existe)
recall :: String -> Memory -> Maybe MemoryValue
recall key mem = lookup key mem

-- Eliminar una clave
forget :: String -> Memory -> Memory
forget key mem = filter ((/= key) . fst) mem

-- Asignar un nuevo valor en la memoria del tanque
rememberTank :: Tank -> String -> MemoryValue -> Tank
rememberTank tank key val =
  tank { tankMemory = remember key val (tankMemory tank) }

-- Consultar un valor de la memoria del tanque
recallTank :: Tank -> String -> Maybe MemoryValue
recallTank tank key = recall key (tankMemory tank)
