---
status: accepted
---

# El bar profile solo describe la barra

Un bar profile guardaba también el reloj de fondo, los desktop widgets y la posición de las notificaciones, de modo que cambiar de perfil cambiaba cosas que no parecían de la barra. Decidimos que el perfil describa solo la barra (tamaños, estilo y bar elements). Los desktop widgets, incluido el reloj de fondo, se configuran por monitor fuera de los perfiles. La posición de las notificaciones y el tema son globales. Cada monitor tiene siempre un perfil asignado de forma explícita, y no existe un perfil "activo" global.

## Considered Options

- **Un perfil para toda la pantalla** (barra + escritorio): era lo que había. Se descartó porque el nombre y el comportamiento no coincidían y el panel resultaba confuso.
- **Dos perfiles asignables por separado** (de barra y de escritorio): se descartó porque duplica la asignación por monitor sin un caso de uso claro.

## Consequences

- Hace falta una migración del formato de datos: los ajustes de escritorio de cada perfil antiguo pasan a los monitores que lo tenían asignado.
- Que un perfil `presentation` oculte el reloj de fondo en el proyector deja de ser posible a través del perfil; se hace configurando los desktop widgets de ese monitor.
