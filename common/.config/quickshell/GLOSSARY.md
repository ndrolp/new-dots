# Quickshell

La shell de escritorio sobre Hyprland: la barra, los paneles y lo que se dibuja sobre el fondo, y el panel de ajustes que los configura.

## Language

**Bar profile** (perfil de barra):
Una configuración con nombre de la barra (tamaños, estilo y qué contiene) que se asigna a un monitor. Describe solo la barra; lo que se dibuja en el escritorio y el tema quedan fuera.
_Avoid_: Perfil (a secas), layout, preset

**Bar position** (posición de la barra):
El borde de la pantalla en el que está la barra: arriba, abajo, izquierda o derecha. Forma parte del bar profile. En una barra lateral la zona izquierda es la de arriba y la derecha la de abajo, sea cual sea el lado. Los popups se abren siempre hacia el interior de la pantalla.
_Avoid_: Bar edge (los extremos de la barra son otra cosa), esquina, dock side

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

**App menu** (menú de la app):
El bar element que muestra en negrita el nombre de la app enfocada (el `Name` de su `.desktop`, o su appId si no tiene) y, al pulsarlo, abre como popup el menú de la app: las acciones de su `.desktop` (p. ej. «New Private Window» de Firefox), *New Window* y *Quit <App>*, que pide cerrar todas sus ventanas sin confirmar nada (las apps con trabajo sin guardar preguntan ellas). Si la app exporta su propio menú (GTK3 con `appmenu-gtk-module` y una barra de menús visible, en XWayland o en Wayland nativo; Electron y Java solo en XWayland), sus títulos (*File*, *Edit*, *View*…) van tras el nombre, y los que no caben pasan a un menú «»; si uno de ellos es *Window*, el de la shell pasa a llamarse *Hyprland*. Tras ellos va el título *Window*, cuyo menú actúa sobre la ventana enfocada: *Float*/*Tile*, *Fullscreen*, *Pin*, *Move to Workspace* ▸ 1–10 y *Close Window*. Cada título abre su propio popup. Sigue a la ventana enfocada como *CurrentApp*: solo en la barra del monitor enfocado y con una ventana enfocada en su workspace. Empieza desactivado. Sus menús salen de un único modelo (`components/AppMenuModel.js`). No es *CurrentApp*, que es otro bar element; un bar profile puede llevar uno, otro o los dos.
_Avoid_: Global menu, menubar, CurrentApp (para este elemento)

**App menu popover** (menú de la app en el cursor):
El menú de la app enfocada que SUPER+A abre en el cursor del ratón, en el monitor enfocado, como una sola lista: primero las entradas del menú con el nombre de la app y después cada uno de los demás menús del modelo como submenú, así que un menú que se añade al modelo aparece aquí sin más. Sus entradas hacen lo mismo que en el popup del *App menu*. Se cierra al perder el foco, con Escape o al elegir una entrada. Sin ventana enfocada abre el menú *Desktop*: *Unified Search*, *Settings Panel* y *Change Wallpaper*. No es un popup: no pertenece a ningún bar element.
_Avoid_: Context menu, right-click menu, Popup (para esto)

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
La ventana pequeña que se despliega desde un bar element al pulsarlo (Bluetooth, red, batería, audio, media, control center…). Pertenece a ese bar element y se cierra al pulsarlo otra vez, al pulsar un bar element que no abre ningún popup o al pulsar fuera de él y de su barra; pulsar un hueco de la barra no lo cierra. Solo hay uno abierto a la vez en todos los monitores.
Con la barra opaca o con la docked bar un popup va **anclado** (attached): sale de la barra como si fuera parte de ella. Con cualquier otra barra transparente va **flotante** (floating), separado de la barra.
_Avoid_: Menu, dropdown, status popup

**Docked bar** (barra acoplada):
La barra transparente cuyas zonas cuelgan del borde de la pantalla en el que está la barra, cada una con el contorno, el color y la opacidad de un popup anclado. Mientras un popup anclado está abierto, la zona de la que sale se ensancha para recibirlo. Con el bar border activo, cada zona lo lleva por su contorno.
_Avoid_: Barra inclinada, slanted bar

**Bar border** (borde de la barra):
Un ajuste del perfil de barra que dibuja una línea fina en el color de borde del colorscheme por la propia barra: con la barra opaca, a lo largo del borde que da al escritorio; con la docked bar, por el contorno de cada zona, salvo por el lado pegado al borde de la pantalla. Un popup anclado continúa esa línea por su contorno, sin línea donde se une a la barra. Con cualquier otra barra transparente no dibuja nada; un popup flotante tiene siempre su propio borde.
_Avoid_: Transparent bar border, borde transparente

**Element border** (borde de los elementos):
Un ajuste del perfil de barra que dibuja la misma línea alrededor de la pill de cada bar element que no está en un grupo, con cualquier estilo de barra.
_Avoid_: Pill border

**Group border** (borde de los grupos):
Un ajuste del perfil de barra que dibuja la misma línea alrededor del fondo compartido de cada grupo, con cualquier estilo de barra.

**Icon theme** (tema de iconos):
El conjunto de iconos de aplicaciones y de la bandeja que usa el escritorio (hoy Papirus-Dark). Lo decide GTK y Quickshell lo sigue; es el mismo para todos los temas de color y no cambia al cambiar de tema.
_Avoid_: Tema (a secas), que en este proyecto es el *colorscheme* (ver GLOSSARY-MAP)

**Colorscheme selector** (selector de colorscheme):
El panel a pantalla completa que lista los colorschemes, hace un *colorscheme preview* del que está resaltado y lo aplica al pulsar Enter. Al cerrarlo sin aplicar se vuelve al colorscheme activo.
_Avoid_: Theme selector, theme picker, selector de temas

**Control center** (centro de control):
El popup del bar element *control center* (la campana con el contador de no leídas) que reúne, como la cortina de Android, los tiles y deslizadores y las notificaciones. Tiene dos etapas: **collapsed** y **expanded**. SUPER+N lo abre collapsed y SUPER+C expanded, en la barra del monitor enfocado; si esa barra no tiene el bar element, se abre en el extremo derecho de la barra, que en una barra lateral es el de abajo, donde queda la zona derecha. Con el plugin *Control center* desactivado solo muestra las notificaciones.
_Avoid_: Notification center, notification panel, shade, cortina, control panel, quick settings, panel de control

**Collapsed control center** (control center plegado):
La etapa con la que se abre el control center por defecto: una fila con los seis primeros tiles visibles y, debajo, las notificaciones.
_Avoid_: Modo compacto, mini

**Expanded control center** (control center desplegado):
La etapa en la que todos los tiles visibles, los deslizadores (volumen, brillo, temperatura) y los datos del sistema ocupan el lugar de las notificaciones. Se llega desde el collapsed con el chevron o arrastrando el asa, y plegarlo devuelve las notificaciones.
_Avoid_: Quick settings, página de ajustes

**Tile**:
Un conmutador o acción del control center (Wi-Fi, Bluetooth, no molestar, micrófono, keep-awake, night light, audio output…). Hay una sola lista ordenada de tiles para toda la shell, guardada en `appearance.json` y editada en la sección *Control center* del settings panel: cada tile se puede ocultar y mover, y los seis primeros visibles forman la fila del collapsed control center.
_Avoid_: Toggle, botón rápido, quick setting

**Notification card** (tarjeta de notificación):
Cómo se muestra una notificación en el control center: icono o imagen de la app, título, cuerpo (desplegable con su chevron) y botones de acción. Pulsarla ejecuta su acción por defecto, la quita y cierra el control center; deslizarla de lado la descarta. Las de una misma app se apilan: se ve la más reciente con «+N more», y al pulsar la pila se despliega.
_Avoid_: Entrada, item, toast (que es la notificación que aparece sola en pantalla)

**Ongoing notification** (notificación en curso):
Una notificación con la marca `resident`, o la tarjeta de media mientras algo suena, que va fijada arriba del todo en el control center y que *Clear all* no quita.
_Avoid_: Persistente, sticky, pinned

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

**Monitor setup** (configuración de monitores):
Cómo se colocan los monitores de una combinación concreta de monitores conectados: cuáles están encendidos y, en cada uno, su posición, resolución, frecuencia de refresco, escala, rotación y si replica a otro. Una combinación se reconoce por qué monitores hay, no por el puerto en el que están, y con la tapa cerrada la pantalla del portátil no cuenta. Describe solo los monitores: el bar profile, los workspaces y los desktop widgets siguen siendo de cada monitor. Pertenece a la máquina, no al repo. Solo se recuerda cuando se elige o se cambia algo.
_Avoid_: Perfil (a secas), monitor profile, display profile, layout

**Quick switch** (cambio rápido):
El panel pequeño que abre SUPER+P para elegir entre *Extend*, *Mirror* y *<monitor> only*. Lo que se elige se recuerda como la monitor setup de esa combinación. No es un popup ni el settings panel.
_Avoid_: Display menu, projector menu

**Displays** (pantallas):
La section del settings panel donde se colocan los monitores arrastrándolos, se elige la resolución, la frecuencia, la escala y la rotación de cada uno, se ven sus ajustes de barra y workspaces, y se listan las monitor setups guardadas. Cualquier cambio pasa por *Keep or Revert*.
_Avoid_: Monitors, pantalla (a secas)

**Identify** (identificar):
El botón de *Displays* que muestra un momento en cada monitor su número, el mismo que tiene en la lista.

**Automatic setup** (configuración automática):
Lo que usan los monitores cuando no hay una monitor setup que aplicar: todos encendidos, extendidos hacia la derecha, a su resolución más alta y su frecuencia más alta. También la usa un solo monitor si su modo guardado ya no existe, y toda la combinación si su monitor setup dejaría todas las pantallas apagadas o no se puede leer.
_Avoid_: Modo por defecto, fallback

**Keep or Revert** (mantener o revertir):
La cuenta atrás de 15 segundos tras cualquier cambio de monitores, con una tarjeta en todos los monitores encendidos. *Keep* (`Enter`) lo guarda y *Revert* (`Esc`) lo deshace; sin respuesta se deshace solo. Hyprland también lo deshace por su cuenta poco después si la shell ya no está, así que un cambio de prueba nunca cuenta como guardado.
_Avoid_: Diálogo de confirmación, popup

**Monitor toast** (aviso de monitores):
La tarjeta que aparece en el monitor enfocado y se va sola a los 20 segundos: al conectar una combinación desconocida, con las opciones del *quick switch* y *Arrange…*, o cuando algo falla con los monitores o sus configuraciones guardadas. No es una notification card y no queda en el historial.
_Avoid_: Notificación, popup

**Workspace overview** (vista de workspaces):
La vista a pantalla completa que se abre con SUPER+TAB sobre el monitor enfocado, atenuando el escritorio, y muestra los workspaces de todos los monitores, agrupados por monitor y sin repetir ninguno, cada uno como una miniatura con sus ventanas en su sitio. Arrastrar una ventana a otro workspace la mueve allí sin seguirla y la vista sigue abierta; soltarla en la casilla vacía tras el último workspace de un monitor crea uno nuevo. Pulsar una ventana la enfoca y pulsar un workspace cambia a él, y las dos cosas cierran la vista. No es un popup. No es el *window switcher*.
_Avoid_: Expose, overview (a secas), desktop overview, escritorio (para un workspace), app (para una ventana)

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
