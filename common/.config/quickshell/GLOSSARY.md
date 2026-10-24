# Quickshell

La shell de escritorio sobre Hyprland: la barra, los paneles y lo que se dibuja sobre el fondo, y el panel de ajustes que los configura.

## Language

**Bar profile** (perfil de barra):
Una configuración con nombre de la barra (tamaños, estilo y qué contiene) que se asigna a un monitor. Describe solo la barra; lo que se dibuja en el escritorio y el tema quedan fuera.
_Avoid_: Perfil (a secas), layout, preset

**Bar element** (elemento de barra):
Cualquier pieza que se coloca en la barra: Arch, workspaces, app actual, audio, batería, reloj, bandeja… Todos son del mismo tipo; no hay elementos "estructurales" frente a "de estado".
_Avoid_: Bar widget, status module, módulo

**Group** (grupo):
Un conjunto de bar elements contiguos de una misma zona que comparten un único fondo. Un grupo que ocupa toda la zona central es lo que antes se llamaba isla.
_Avoid_: Status island, isla, pill group

**Density preset** (preset de densidad):
Un atajo (compact, balanced, spacious) que rellena de una vez los tamaños de un bar profile. No forma parte del perfil: después de aplicarlo no queda rastro de cuál se usó.
_Avoid_: Densidad (como ajuste guardado)

**Desktop widget** (widget de escritorio):
Una pieza informativa dibujada sobre el fondo de un monitor (media, calendario, tiempo, red, sistema, reloj de fondo). Se configura por monitor, fuera de los bar profiles.
_Avoid_: Widget (a secas, para cosas de la barra)

**Wallpaper selector** (selector de fondos):
La vista a pantalla completa que se abre sobre el monitor enfocado para elegir el fondo de ese monitor. La lista de fondos dentro de los ajustes no es un wallpaper selector, sino parte de la sección Wallpapers del panel de ajustes.
_Avoid_: Wallpaper picker, carrusel

**System monitor**:
El bar element que muestra el uso de CPU y memoria. No confundir con el desktop widget *System*.
_Avoid_: System (para el elemento de la barra)

**Popup**:
La ventana pequeña que se despliega desde un bar element al pulsarlo (Bluetooth, red, batería, audio, media…). Pertenece a ese bar element y se cierra al perder el foco.
Con la barra opaca un popup va **anclado** (attached): sale de la barra como si fuera parte de ella. Con la barra transparente va **flotante** (floating), separado de la barra.
_Avoid_: Menu, dropdown, status popup

**Icon theme** (tema de iconos):
El conjunto de iconos de aplicaciones y de la bandeja que usa el escritorio (hoy Papirus-Dark). Lo decide GTK y Quickshell lo sigue; es el mismo para todos los temas de color y no cambia al cambiar de tema.
_Avoid_: Tema (a secas), que en este proyecto es el esquema de colores

**Control center** (centro de control):
El panel con los conmutadores rápidos y los deslizadores (Wi-Fi, Bluetooth, no molestar, volumen, brillo). No es un popup: no pertenece a ningún bar element, aunque igual que un popup va anclado o flotante según la barra.
_Avoid_: Control panel, quick settings, panel de control
