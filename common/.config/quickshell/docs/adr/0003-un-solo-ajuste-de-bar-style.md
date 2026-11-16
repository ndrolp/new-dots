---
status: accepted
---

# Un solo ajuste de bar style en lugar de interruptores

El estilo de la barra se guardaba en el bar profile como dos interruptores: `barTransparent` y `transparentBarSlanted` (la docked bar, que solo tenía efecto con el primero). Cada sitio que dibujaba la barra volvía a deducir el estilo a partir de los dos, y algunas combinaciones no tenían sentido (docked sobre una barra opaca solo hacía transparentes las pills). Decidimos guardar un solo ajuste, `barStyle`, con los valores `opaque`, `transparent` y `docked`, para que un estilo nuevo como la capsule sea un valor más y no otro interruptor que multiplique combinaciones sin significado.

## Considered Options

- Añadir la capsule como un tercer interruptor que manda sobre los otros dos: evita la migración, pero deja tres claves describiendo una sola cosa y más combinaciones imposibles.
- Un solo `barStyle` (elegida): requiere una migración y tocar cada sitio que deducía el estilo, una sola vez.

## Consequences

- La migración 16 convierte los perfiles guardados conservando su aspecto: un perfil opaco con el interruptor docked pasa a `opaque` con las pills transparentes, que era lo único que ese interruptor cambiaba.
- El panel de ajustes ofrece el estilo como una sola elección (Opaque / Transparent / Docked / Capsule). La capsule es el cuarto valor de `barStyle`, sin interruptor propio ni migración aparte, y solo admite arriba y abajo como Bar position.
- Un `barStyle` desconocido se carga como `opaque`, igual que una Bar position desconocida se carga como arriba.
