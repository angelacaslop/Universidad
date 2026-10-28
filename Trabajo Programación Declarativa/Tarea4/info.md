# Tarea 1: Revisar Gloss

Familiarízate con la biblioteca Gloss para el desarrollo de gráficos 2D y aplicaciones
interactivas en Haskell. Debes estudiar los conceptos fundamentales incluyendo:

- Tipos básicos: `Picture`, `Color`, `Display`.
- Transformaciones geométricas: `Translate`, `Rotate`, `Scale`.
- Los tres modos de visualización: `display`, `animate`, `play`.
- El sistema de manejo de eventos de teclado y ratón.

Implementa 2–3 ejemplos simples que demuestren dibujo de formas con transformaciones,
una animación básica y alguna interacción con teclado para verificar tu comprensión.


# Tarea 2: Desarrollar un juego simple con monigote

Implementa un juego básico usando Gloss donde aparezca un personaje (monigote) que
se pueda controlar mediante el teclado. El monigote debe poder desplazarse horizontalmente
(izquierda/derecha) usando las teclas A/D o las flechas del teclado, y realizar un salto con
física realista al presionar W o flecha arriba. El juego debe incluir:

- Un tipo de datos para representar el estado del juego (posición, velocidad, dirección).
- Una función de dibujo que represente gráficamente al personaje de forma lateral o frontal.
- Un manejador de eventos que capture las pulsaciones del teclado.
- Una función de actualización que aplique física básica (gravedad, detección de suelo, límites de pantalla).

El personaje debe animarse al caminar y voltear su orientación según la dirección del movimiento.

Ver video de ejemplo en la carpeta de la tarea.


# Tarea 3: Implementar Applicative y usar fmap

Refactoriza los tipos de datos de tu juego HAUS para que implementen la clase de tipos
`Applicative` (y por tanto también `Functor`). Identifica en tu código todas las oportunidades
donde se puedan usar las funciones `fmap` (o su operador `<$>`), `<*>`, y `pure` para hacer
el código más declarativo y funcional. Esta tarea se centra en aplicar los conceptos de functores
aplicativos que se impartirán en la próxima clase. Debes modificar las funciones existentes
para aprovechar estas abstracciones cuando sea posible, por ejemplo al actualizar el estado
del juego, transformar coordenadas, o aplicar funciones a valores dentro de contextos. La
implementación debe respetar las leyes de `Functor` y `Applicative`.


# Nota

Esta tarea requiere comprender los conceptos que se enseñarán en la próxima clase sobre
`Functor`s y `Applicative`s. Se recomienda revisar material previo sobre estas type classes
si deseas adelantar trabajo.
