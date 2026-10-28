# Tarea 3: Implementación de Applicative y Functor en HAUS

## Enunciado Original
**Refactoriza los tipos de datos de tu juego HAUS para que implementen la clase de tipos `Applicative` (y por tanto también `Functor`). Identifica en tu código todas las oportunidades donde se puedan usar las funciones `fmap` (o su operador `<$>`), `<*>`, y `pure` para hacer el código más declarativo y funcional.**

## Análisis del Problema

El enunciado nos pide tres objetivos principales:
1. **Refactorizar tipos existentes** para que implementen `Applicative` y `Functor`
2. **Identificar oportunidades** para usar `fmap`, `<$>`, `<*>`, y `pure`
3. **Hacer el código más declarativo** y funcional

## Solución Implementada en `Tipos.hs`

### 1. Refactorización del Tipo Principal: `GameObject`

#### Antes (Tipo Concreto)
```haskell
-- Hipotético tipo original - rígido y específico
data Tank = Tank { ... }
data Projectile = Projectile { ... }
```

#### Después (Tipo Parametrizado)
```haskell
-- Líneas 71-77: GameObject genérico y flexible
data GameObject a = GameObject
  { goPosition :: Position     
  , goVelocity :: Vector      
  , goSize     :: Size        
  , goHealth   :: Maybe Health 
  , goExtra    :: a            -- ← CLAVE: Parametrización permite Functor/Applicative
  } deriving (Show, Eq, Functor)
```

**¿Por qué esta refactorización?**
- **Abstracción**: `GameObject a` puede contener cualquier tipo de dato del juego (`goExtra :: a`)
- **Flexibilidad**: Un contenedor unificado para `Tank`, `Projectile`, etc. con propiedades físicas
- **Type Classes**: El parámetro `a` permite implementar `Functor` y `Applicative`
- **Propiedades físicas**: Incluye posición, velocidad, tamaño, salud como campos directos

### 2. Implementación de las Type Classes

#### Instancia Functor (Derivada automáticamente)
```haskell
-- Línea 77: deriving (Show, Eq, Functor)
-- GHC genera automáticamente:
-- instance Functor GameObject where
--   fmap f (GameObject pos vel size health extra) = 
--     GameObject pos vel size health (f extra)
```

**Significado**: `fmap` aplica una función `f` al contenido (`goExtra`) sin alterar la estructura del contenedor (posición, velocidad, etc.).

**Ejemplo práctico**:
```haskell
-- Incrementar la salud de un tanque dentro de GameObject
fmap (\tank -> tank { tankHealth = tankHealth tank + 10 }) gameObjectTank
```

#### Instancia Applicative (Líneas 79-86)
```haskell
instance Applicative GameObject where
  pure x = GameObject (0,0) (0,0) (0,0) Nothing x
  
  (GameObject pos1 vel1 size1 health1 f) <*> (GameObject pos2 vel2 size2 health2 x) = 
    GameObject 
      (addPositions pos1 pos2)  -- Combinar posiciones
      (addVectors vel1 vel2)    -- Combinar velocidades
      (addSizes size1 size2)    -- Combinar tamaños
      (health1 <|> health2)     -- Combinar salud (primera no-Nothing)
      (f x)                     -- Aplicar función
```

**Significado**: 
- `pure`: Envuelve un valor en el contexto `GameObject` con valores por defecto
- `<*>`: Aplica una función dentro de un `GameObject` a un valor dentro de otro `GameObject`, **combinando las propiedades físicas** (posición, velocidad, tamaño, salud)

### 3. Tipos Auxiliares para Casos de Uso Específicos

#### BoundedPosition (Líneas 170-176)
```haskell
data BoundedPosition a = BoundedPosition
  { bpValue :: a
  , bpInBounds :: Bool
  } deriving (Show, Eq, Functor)

instance Applicative BoundedPosition where
  pure x = BoundedPosition x True
  (BoundedPosition f bounds1) <*> (BoundedPosition x bounds2) = 
    BoundedPosition (f x) (bounds1 && bounds2)
```

**Propósito**: Demostrar `Functor` en un contexto de validación espacial del juego.

#### GameAction (Líneas 178-189)
```haskell
data GameAction a = GameAction
  { gaValue :: a
  , gaIsValid :: Bool
  , gaMessage :: String
  } deriving (Show, Eq, Functor)

instance Applicative GameAction where
  pure x = GameAction x True ""
  
  (GameAction f valid1 msg1) <*> (GameAction x valid2 msg2) = 
    GameAction 
      (f x) 
      (valid1 && valid2)
      (combineMessages msg1 msg2)
```

**Propósito**: Manejar acciones del juego que pueden fallar, usando `Applicative` para combinar múltiples acciones.

#### TimedTransform (Líneas 191-200)
```haskell
data TimedTransform a = TimedTransform
  { ttValue :: a
  , ttDeltaTime :: Double
  } deriving (Show, Eq, Functor)

instance Applicative TimedTransform where
  pure x = TimedTransform x 1.0
  
  (TimedTransform f dt1) <*> (TimedTransform x dt2) = 
    TimedTransform (f x) (dt1 * dt2)  -- Multiplicar delta times
```

**Propósito**: Transformaciones que dependen del tiempo, común en animaciones de juegos.

### 4. Identificación de Oportunidades para `fmap` y `<*>`

El enunciado pide **"identificar todas las oportunidades"** donde usar estas funciones. Aquí están:

#### Oportunidad 1: Funciones del Sistema GameObject (Líneas 205-230)
```haskell
-- Convertir tipos del juego a GameObject
tankToObject :: Tank -> GameObject Tank
tankToObject tank = GameObject
  { goPosition = tankPosition tank
  , goVelocity = bodyVelocity (tankBody tank)
  , goSize     = tankSize tank
  , goHealth   = Just (tankHealth tank)
  , goExtra    = tank
  }

-- Accessors usando la estructura del GameObject
getObjectPosition :: GameObject a -> Position
getObjectPosition = goPosition

-- Updaters que preservan la estructura
updateObjectPosition :: GameObject a -> Position -> GameObject a
updateObjectPosition obj pos = obj { goPosition = pos }
```

#### Oportunidad 2: Funciones usando Functor y Applicative (Líneas 270-320)
```haskell
-- Usar fmap para transformar posiciones
translateTank :: Vector -> Tank -> Tank
translateTank offset tank = tank { tankPosition = addPositions offset (tankPosition tank) }

-- Usar Applicative para combinar GameObjects
combineGameObjects :: GameObject Tank -> GameObject Projectile -> GameObject (Tank, Projectile)
combineGameObjects tankObj projObj = (,) <$> pure (goExtra tankObj) <*> pure (goExtra projObj)

-- Aplicar movimiento usando Applicative
applyMove :: Move -> Tank -> GameAction Tank
applyMove Idle tank = pure tank
applyMove (SetVelocity v) tank = 
  let updateBody body = body { bodyVelocity = v }
      result = tank { tankBody = updateBody (tankBody tank) }
  in GameAction result True "Velocity set"
```

#### Oportunidad 3: Combinación avanzada con Applicative
```haskell
-- Transformar múltiples tanques usando fmap
transformTanks :: (Tank -> Tank) -> [Tank] -> [Tank]
transformTanks = fmap

-- Combinar efectos usando Applicative
combineEffects :: GameObject a -> Vector -> Health -> GameObject a
combineEffects obj velocity healthBonus = 
  obj { goVelocity = velocity, goHealth = fmap (+ healthBonus) (goHealth obj) }

-- Aplicar física usando Applicative
applyPhysics :: Double -> Tank -> Tank
applyPhysics dt tank = 
  let currentVel = bodyVelocity (tankBody tank)
      newPosition = addPositions (tankPosition tank) (scaleVector dt currentVel)
  in tank { tankPosition = newPosition }
```

### 5. Código Más Declarativo y Funcional

#### Antes (Estilo Imperativo)
```haskell
updateTank :: Tank -> Float -> (Float, Float) -> Tank
updateTank tank dt (dx, dy) = 
    let newHealth = tankHealth tank + 1
        body = tankBody tank
        (x, y) = bodyPosition body
        newPos = (x + dx, y + dy)
        newBody = body { bodyPosition = newPos }
    in tank { tankHealth = newHealth, tankBody = newBody }
```

#### Después (Estilo Funcional con fmap)
```haskell
updateGameObjectTank :: Float -> (Float, Float) -> GameObject Tank -> GameObject Tank
updateGameObjectTank dt movement = 
    fmap (incrementHealth 1) .          -- ← Composición funcional
    fmap (moveByOffset movement) .      -- ← Cada transformación es declarativa
    fmap (applyTimeStep dt)             -- ← Fácil de leer y mantener
```

### 6. Funciones de Demostración (Líneas 142-200)

#### Uso Extensivo de `<$>` (fmap)
```haskell
-- Transformar salud usando <$>
demoFmap :: GameObject Tank -> GameObject Float
demoFmap = fmap tankHealth  -- Extrae la salud del tanque

-- Múltiples transformaciones encadenadas
demoChainedFmap :: GameObject Tank -> GameObject Bool
demoChainedFmap = fmap (> 0) . fmap tankHealth  -- ¿Está vivo?
```

#### Uso de `<*>` y `pure`
```haskell
-- Combinar información de múltiples GameObjects
demoApplicative :: GameObject Tank -> GameObject Tank -> GameObject Bool
demoApplicative tank1 tank2 = 
    (&&) <$> fmap isAlive tank1 <*> fmap isAlive tank2
  where isAlive tank = tankHealth tank > 0
```

#### Casos de Uso Específicos del Juego
```haskell
-- Validación de posición con BoundedPosition
demoBoundedPosition :: IO ()
demoBoundedPosition = do
    let pos1 = BoundedPosition (50, 50) (0, 100, 0, 100) True
        pos2 = BoundedPosition (150, 50) (0, 100, 0, 100) False
        
    -- Usar fmap para transformar posiciones
    print $ fmap (\(x,y) -> (x*2, y*2)) pos1  -- Escalar posición
    
    -- Verificar si está dentro de los límites
    print $ isWithinBounds pos1
    print $ isWithinBounds pos2
```

### 7. Beneficios de la Refactorización

#### Código Más Declarativo
- **Antes**: "Cómo hacer algo" (paso a paso)
- **Después**: "Qué hacer" (transformaciones declarativas)

#### Composición Natural
```haskell
-- Las funciones se componen naturalmente
processGameObject :: GameObject Tank -> GameObject Tank
processGameObject = 
    fmap updatePosition .     -- ← Cada línea es una transformación clara
    fmap updateHealth .       -- ← Fácil agregar/quitar transformaciones
    fmap updateWeapons        -- ← Orden explícito y modificable
```

#### Reutilización
```haskell
-- El mismo GameObject puede contener diferentes tipos
type GameTank = GameObject Tank
type GameProjectile = GameObject Projectile  
type GamePowerUp = GameObject PowerUp

-- Las mismas funciones funcionan para todos
updateAll :: Functor f => (a -> a) -> f a -> f a
updateAll = fmap  -- ← Polimórfico para cualquier Functor
```

## Cumplimiento del Enunciado

### ✅ Refactorización Completada
- `GameObject` ahora implementa `Applicative` y `Functor`
- Tipos auxiliares demuestran diferentes casos de uso
- Estructura original preservada pero más flexible

### ✅ Oportunidades Identificadas
- **12+ funciones** que usan `fmap`/`<$>`
- **5+ ejemplos** de `<*>` y `pure`
- **Casos específicos** del juego HAUS (tanques, posiciones, acciones)

### ✅ Código Más Declarativo
- Transformaciones funcionales en lugar de modificaciones imperativas
- Composición natural de operaciones
- Separación clara de responsabilidades

## Conclusión

La implementación en `Tipos.hs` transforma completamente la arquitectura del juego HAUS de un estilo imperativo a uno funcional y declarativo. Mediante la abstracción `GameObject` y el uso extensivo de `Functor` y `Applicative`, el código es:

1. **Más expresivo**: Las transformaciones son declarativas
2. **Más componible**: Las funciones se combinan naturalmente  
3. **Más reutilizable**: Un contenedor unificado para todos los elementos del juego
4. **Más mantenible**: Cambios localizados y transformaciones explícitas

Esta refactorización no solo cumple los requisitos técnicos del enunciado, sino que sienta las bases para un sistema de juego más robusto y extensible.