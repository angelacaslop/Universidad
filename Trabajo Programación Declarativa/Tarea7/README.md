# 🎮 Tank Battle Game

Un juego de batalla de tanques en tiempo real desarrollado en Haskell utilizando la biblioteca Gloss para gráficos 2D.

## 📋 Descripción

Tank Battle Game es un juego arcade donde controlas un tanque y luchas contra bots enemigos en una arena cerrada. El juego cuenta con física de proyectiles, sistema de colisiones, inteligencia artificial para los enemigos, y sprites personalizados.

## ✨ Características

### Jugabilidad
- **Control del jugador**: Mueve tu tanque con WASD y apunta con el ratón
- **Sistema de disparo**: Click izquierdo para disparar proyectiles
- **Bots inteligentes**: 2-4 tanques controlados por IA que te persiguen y disparan
- **Sistema de salud**: Barras de vida coloreadas por tanque
- **Efectos visuales**: Explosiones animadas con 27 frames
- **Física realista**: Proyectiles con rebote en paredes y obstáculos

### Características técnicas
- **60 FPS**: Juego fluido con actualización constante
- **Sprites personalizados**: Gráficos para tanques, torretas, proyectiles y explosiones
- **Sistema de cooldown**: Limitación de disparo para balance del juego
- **Colisiones AABB**: Detección precisa de colisiones
- **Identificación por color**: Cada tanque tiene un color único en su barra de vida

## 🎨 Colores de tanques

- **Verde brillante**: Jugador (tankId 0)
- **Azul**: Bot 1 (tankId 1)
- **Rojo**: Bot 2 (tankId 2)
- **Amarillo**: Bot 3 (tankId 3)
- **Naranja**: Bot 4 (tankId 4)

## 🕹️ Controles

| Tecla | Acción |
|-------|--------|
| `W` | Mover adelante |
| `S` | Mover atrás |
| `A` | Rotar izquierda |
| `D` | Rotar derecha |
| `Mouse` | Apuntar torreta |
| `Click Izq.` | Disparar |

## 🏗️ Arquitectura del proyecto

```
Tarea6/
├── app/
│   └── Main.hs              # Punto de entrada y game loop
├── src/
│   ├── Tipos.hs             # Definiciones de tipos de datos
│   ├── Renderizar.hs        # Sistema de renderizado
│   ├── Colisiones.hs        # Detección de colisiones
│   ├── Fisica.hs            # Cálculos físicos
│   ├── Comportamiento.hs    # Comportamientos físicos
│   ├── IA.hs                # Inteligencia artificial de bots
│   ├── Memoria.hs           # Sistema de memoria de tanques
│   └── Mapas.hs             # Definición de arena y obstáculos
├── sprites/
│   ├── Arena.png            # Fondo del juego
│   ├── tankbody.png         # Sprite del cuerpo del tanque
│   ├── tankturret.png       # Sprite de la torreta
│   ├── tankbullet.png       # Sprite del proyectil
│   └── explotion/           # 27 frames de animación de explosión
│       ├── 1.png
│       ├── 2.png
│       └── ...
└── Tarea5.cabal             # Configuración de Cabal

```

## 🛠️ Requisitos

- **GHC**: 9.6.7 o superior
- **Cabal**: 3.12 o superior
- **Bibliotecas Haskell**:
  - `gloss` (v1.13.x) - Gráficos 2D
  - `gloss-juicy` - Carga de imágenes PNG
  - `base` (v4.18.x)

## 📦 Instalación

1. **Clonar el repositorio**:
```bash
git clone <repository-url>
cd Tarea6
```

2. **Compilar el proyecto**:
```bash
cabal build
```

3. **Ejecutar el juego**:
```bash
cabal run Tarea6
```

## 🎯 Cómo jugar

1. Al iniciar el juego, controlas el tanque **verde**
2. Usa **WASD** para moverte por la arena
3. Apunta con el **ratón** hacia tus enemigos
4. **Click izquierdo** para disparar (cooldown de 0.8s)
5. Evita los proyectiles enemigos y los obstáculos
6. Destruye todos los tanques enemigos para ganar
7. Si tu salud llega a 0, pierdes

## 🧠 Sistema de IA

Los bots enemigos utilizan un árbol de decisiones que evalúa:
- **Distancia al jugador**: Persiguen o huyen según la distancia
- **Obstáculos**: Evitan colisiones con paredes
- **Cooldown de disparo**: Disparan cuando tienen oportunidad
- **Memoria**: Recuerdan posiciones anteriores para tomar mejores decisiones

## 🎨 Sistema de renderizado

El juego utiliza un sistema de capas para renderizar:
1. **Fondo**: Arena (sprite o color sólido)
2. **Tanques**: Cuerpo + torreta (rotación independiente)
3. **Barras de vida**: Coloreadas según el tanque
4. **Proyectiles**: Sprites con rotación según velocidad
5. **Explosiones**: Animación de 27 frames

### Optimizaciones de rendimiento
- **Carga única de sprites**: Todos los sprites se cargan al inicio
- **Caché en GameState**: Las imágenes se mantienen en memoria
- **Sin I/O por frame**: 60 FPS sin drops

## 🔧 Arquitectura técnica

### Flujo del game loop

```haskell
Game Loop (60 FPS):
1. handleEvent    → Procesa input del usuario
2. updateGame     → Actualiza física y lógica
   ├─ Mover tanques
   ├─ Actualizar IA
   ├─ Mover proyectiles
   ├─ Detectar colisiones
   ├─ Aplicar daño
   └─ Actualizar explosiones
3. renderGame     → Dibuja el frame
```

### Gestión de estado

El juego es **completamente funcional**:
- **Inmutabilidad**: Cada frame crea un nuevo `GameState`
- **Sin efectos secundarios**: Funciones puras para lógica
- **IO aislado**: Solo en `main`, `loadGameState` y eventos
- **Garbage Collection**: Estados antiguos se liberan automáticamente

## 📊 Estadísticas del proyecto

- **Líneas de código**: ~2000 LOC
- **Módulos**: 8 módulos principales
- **Sprites**: 30 archivos de imagen
- **Optimizaciones**: ~500 líneas eliminadas en refactoring

## 🐛 Problemas conocidos

- ⚠️ El sistema de colores de sprites usa multiplicación, limitando opciones de colorización
- ⚠️ Los proyectiles no distinguen entre aliados y enemigos

## 🚀 Mejoras futuras

- [ ] Múltiples niveles con diferentes arenas
- [ ] Power-ups (vida, velocidad, daño)
- [ ] Sonidos y música
- [ ] Menú de inicio y game over
- [ ] Sistema de puntuación
- [ ] Más tipos de proyectiles
- [ ] Modos de juego (survival, time attack)

## 📝 Licencia

Este proyecto fue desarrollado como parte de un curso universitario de Programación Declarativa.

## 👥 Autor

Desarrollado por Jose2 - Universidad [Nombre]

## 🙏 Agradecimientos

- Biblioteca **Gloss** por el sistema de gráficos
- Biblioteca **Gloss-Juicy** por la carga de imágenes
- Comunidad de Haskell por la documentación

---

**¡Disfruta del juego! 🎮**
