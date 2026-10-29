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

**Cava**:
El bar element que dibuja lo que suena por la audio output actual como barras de frecuencia que se mueven con lo que suena. Se oculta mientras no suena nada y vuelve a aparecer en cuanto hay sonido. No confundir con el bar element *audio*, que muestra y cambia el volumen.
_Avoid_: Visualizer, waveform, espectro

**Recording indicator** (indicador de grabación):
El bar element que aparece solo mientras se graba la pantalla y muestra cuánto tiempo lleva la grabación. Cuenta tanto la grabación de la propia shell (la que se inicia desde la captura de pantalla con `wf-recorder`) como cada *screen share*. Al pulsarlo se para la grabación de la propia shell, igual que la tecla para pararla; si solo comparten otras apps, dice cuáles son.
_Avoid_: REC, botón de grabación, screen recording (para el elemento de la barra)

**Screen share** (pantalla compartida):
Una pantalla que otra app (un navegador en una llamada, OBS…) lee por PipeWire a través del portal. Las cámaras no cuentan. No se puede parar desde la shell.
_Avoid_: screencast, stream (para esto)

**Keep-awake** (mantener despierto):
Mientras está activo, la sesión no pasa a inactiva: no se atenúa ni se apaga la pantalla ni se suspende. Se activa y desactiva desde el control center, desde el popup del bar element keep-awake o con el atajo ALT+SHIFT+I; solo el atajo muestra el OSD («Keep-awake on · 1 h», «Keep-awake on» o «Keep-awake off»). Ese bar element se muestra siempre: una taza llena en verde mientras está activo y una taza vacía en el color de subtexto mientras no; al pulsarlo se abre su popup, con un interruptor para activarlo o desactivarlo y la elección de duración: *Until turned off* (hasta desactivarlo), 30 min, 1 h o 2 h. Hay una sola duración elegida, y activarlo desde cualquier sitio la usa; elegir otra mientras está activo reinicia la cuenta atrás desde ella, y elegir *Until turned off* la quita y lo deja activo. Mientras corre la cuenta atrás, el popup muestra el tiempo que queda (el bar element no). Al llegar a cero se desactiva solo y envía una notificación «Keep-awake ended»; desactivarlo a mano no envía ninguna. Siempre empieza desactivado y con *Until turned off* al arrancar la shell; la duración no se guarda.
_Avoid_: Caffeine, idle inhibitor (para la función), no dormir

**Night light** (luz nocturna):
Mientras está activa, los colores de la pantalla se vuelven más cálidos (los aplica `hyprsunset`). Se activa y desactiva desde el control center, donde un deslizador elige la temperatura (de 2500 K, la más cálida, a 6000 K, neutra), que cambia al momento si está activa. La temperatura se guarda en `appearance.json`; si está activa o no, no: solo cambia al pulsarla, nunca por horario, y empieza desactivada al arrancar la shell. Si falta `hyprsunset`, el control center dice por qué no se puede activar.
_Avoid_: Blue light filter, filtro de luz azul, modo noche, hyprsunset (para la función)

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

**Keybind cheatsheet** (chuleta de atajos):
El panel que lista todos los atajos de teclado de Hyprland con su descripción, agrupados por modificadores (`SUPER + SHIFT`, `ALT`…) y filtrables por tecla o descripción. Los lee de `hyprctl binds -j` cada vez que se abre, así que nunca se queda desfasado. Se abre por IPC (`keybinds toggle`) o desde la búsqueda unificada.
_Avoid_: Keymap, lista de atajos, ayuda de teclado

**Audio output** (salida de audio):
Un destino al que se puede enviar el sonido del sistema: auriculares, altavoces, un monitor por HDMI/DisplayPort, unos cascos inalámbricos… Se nombra por su apodo corto (el monitor conectado, el modelo de los cascos), no por la descripción larga de la tarjeta de sonido; el puerto (HDMI / DisplayPort 1, Analog Stereo) es información secundaria.
_Avoid_: Sink, dispositivo, device

**Settings panel** (panel de ajustes):
La ventana que se abre desde la shell para editar toda su configuración, dividida en secciones. No es un popup: no pertenece a ningún bar element ni se despliega desde la barra.
_Avoid_: Config panel, settings window, preferencias

**Section** (sección):
Cada una de las áreas del settings panel (Bar, Notifications, Displays, Wallpapers…), elegida en su barra lateral. Muestra los ajustes de una sola área.
_Avoid_: Página, pestaña, tab

**Lock screen** (pantalla de bloqueo):
Lo que cubre todos los monitores mientras la sesión está bloqueada: el tema, el reloj y la fecha sobre el fondo de pantalla del monitor, desenfocado, en cada monitor, y el campo de contraseña solo en el monitor enfocado. Al bloquear, el fondo se desenfoca y el reloj sube a su sitio; con la contraseña correcta hace lo mismo al revés antes de desbloquear, y una contraseña incorrecta sacude el campo. La dibuja la shell; `hyprlock` queda solo como bloqueo de emergencia (`SUPER+CTRL+ALT+L`) por si la shell falla.
_Avoid_: Lockscreen, hyprlock (para la de la shell), pantalla de login

**Unified search** (búsqueda unificada):
El panel a pantalla completa con un solo campo de texto que busca a la vez en aplicaciones, marcadores, portapapeles y ventanas, y ofrece acciones (buscar en la web, ejecutar en Kitty, ir a un workspace). No es un popup: no pertenece a ningún bar element.
_Avoid_: Launcher, quick search (que es otro panel)

**Query mode** (modo de búsqueda):
Lo que pide el carácter con el que empieza la búsqueda en la unified search: `>` comandos, `?` web, `@` ventanas, `=` calculadora, `:` emoji. Sin prefijo se busca en todo.
_Avoid_: Prefijo (para el modo en sí), filtro

**Calculator** (calculadora):
El resultado de la unified search que da la respuesta de `qalc`. Sale el primero cuando la búsqueda parece una cuenta o una conversión de unidades (`2*(3+4)`, `5 km to mi`, `20% of 80`), y siempre tras `=`. Enter copia la respuesta.
_Avoid_: Calc, qalc (para el resultado)

**Emoji picker** (selector de emoji):
El modo de la unified search que empieza con `:`: lista los emoji cuyo nombre o shortcode empieza por lo escrito (`:fire`), y `:` solo lista los más usados. Enter copia el emoji. La lista de emoji va con la shell; nunca se descarga. `unified-search emoji` abre la búsqueda con `:` ya escrito.
_Avoid_: Emoji search, emoji panel (no es un panel aparte)

**Reduce motion** (reducir movimiento):
El ajuste global de la sección Motion del settings panel que hace instantáneas las animaciones de la shell: los cambios ocurren igual, pero sin transición. No forma parte de ningún bar profile y se aplica en cuanto se activa.
_Avoid_: Disable animations, sin animaciones, modo rápido
