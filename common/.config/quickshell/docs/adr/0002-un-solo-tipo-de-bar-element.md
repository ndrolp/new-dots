---
status: accepted
---

# Un solo tipo de bar element, y los groups sustituyen a la status island

La barra tenía dos tipos de pieza con capacidades distintas: elementos "estructurales" (Arch, workspaces, app actual, System monitor), con orden fijo y solo zona, y "módulos de estado" (audio, batería, reloj…), con orden, grupos numerados y zona. Además, la status island era un modo aparte. Decidimos que todas las piezas sean **bar elements** con las mismas capacidades (activado, zona, orden y "unir con el anterior"). Un **group** es un conjunto de elementos contiguos con fondo compartido, y la isla se convierte en un group que ocupa la zona central.

## Consequences

- La barra se dibuja con un único recorrido por zona; desaparecen los dos caminos de renderizado y el cálculo especial de la isla.
- El formato de los perfiles cambia (lista ordenada por zona en lugar de orden fijo, módulos y grupos numerados) y requiere migración.
- No hay órdenes fijos ocultos: cualquier elemento puede ir delante de cualquier otro, por ejemplo la batería delante de Arch.
