import subprocess, sys, html, os
D=os.path.dirname(os.path.abspath(__file__))
CSS='''
*{box-sizing:border-box;margin:0}
body{width:1920px;height:1080px;overflow:hidden;font-family:"Noto Sans",sans-serif;color:#E6E9EF;
background:radial-gradient(1200px 700px at 80% 20%,rgba(124,58,237,.35),transparent 60%),radial-gradient(1000px 700px at 10% 90%,rgba(12,107,250,.35),transparent 60%),#0B0D12}
.wrap{position:absolute;inset:0;padding:110px 150px;display:flex;flex-direction:column;justify-content:center}
.eyebrow{font-family:"Noto Sans Mono",monospace;color:#3D8BFF;letter-spacing:.25em;font-size:26px;text-transform:uppercase;margin-bottom:28px}
h1{font-size:104px;line-height:1.02;font-weight:800;letter-spacing:-2px}
h1 em{font-style:normal;color:#3D8BFF}
p.lead{font-size:38px;color:#A9B1C1;margin-top:34px;max-width:1450px;line-height:1.35}
ul{list-style:none;margin-top:46px;display:grid;grid-template-columns:1fr 1fr;gap:26px 60px;max-width:1600px}
li{font-size:33px;line-height:1.3;padding-left:42px;position:relative;color:#E6E9EF}
li:before{content:"";position:absolute;left:0;top:14px;width:16px;height:16px;border-radius:50%;background:#7C3AED;box-shadow:0 0 18px #7C3AED}
li b{color:#9B6BFF}
.logo{display:flex;align-items:center;gap:40px}
.logo img{width:230px;height:230px}
.big{font-size:150px;font-weight:800;letter-spacing:-3px}
.big span{color:#3D8BFF}
.url{font-family:"Noto Sans Mono",monospace;font-size:46px;color:#FCFCFC;background:rgba(12,107,250,.25);border:2px solid #0C6BFA;border-radius:18px;padding:18px 34px;display:inline-block;margin-top:40px}
.team{margin-top:50px;font-size:26px;color:#A9B1C1;line-height:1.6}
.credit{margin-top:40px;font-size:21px;color:#7D8699;line-height:1.5}
'''
CAP='''
body{background:#0B0D12}
.bar{position:absolute;left:0;right:0;bottom:0;height:96px;display:flex;align-items:center;gap:26px;padding:0 192px;
background:linear-gradient(90deg,rgba(12,107,250,.25),rgba(124,58,237,.25))}
.bar .t{font-size:36px;font-weight:800}
.bar .s{font-size:28px;color:#A9B1C1}
.bar img{width:56px;height:56px}
'''
def page(name, body, extra=''):
    p=f'{D}/{name}.html'
    open(p,'w').write(f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}{extra}</style></head><body>{body}</body></html>')
    subprocess.run(['chromium','--headless=new','--disable-gpu','--hide-scrollbars','--window-size=1920,1080',f'--screenshot={D}/{name}.png',f'file://{p}'],stderr=subprocess.DEVNULL,check=True)
cards={
'01-intro':'<div class="wrap"><div class="logo"><img src="monos-icon.svg"><div class="big">mon<span>OS</span></div></div><p class="lead">El sistema para programar. Basado en Arch Linux y KDE Plasma.</p></div>',
'02-problema':'<div class="wrap"><div class="eyebrow">El problema</div><h1>Programar empieza<br>por <em>configurar</em>.</h1><p class="lead">Instalar compiladores, editores, contenedores y la terminal puede llevar horas antes de escribir la primera línea de código. Y cada estudiante termina con un entorno distinto.</p></div>',
'03-solucion':'<div class="wrap"><div class="eyebrow">La solución</div><h1>monOS: listo para<br>programar <em>desde el primer arranque</em>.</h1><p class="lead">Una distribución Linux pensada para estudiantes de informática y desarrolladores: se prueba desde una USB, se instala en minutos y trae todo configurado.</p></div>',
'04-valor':'<div class="wrap"><div class="eyebrow">Propuesta de valor · Novedades</div><h1>Lo nuevo en <em>monOS</em></h1><ul><li><b>Live USB</b> con instalador gráfico</li><li><b>Snapshots Btrfs</b> para volver atrás</li><li><b>Instalación inteligente</b> según el hardware</li><li><b>17 grupos</b> de software opcional</li><li><b>Agentes de IA</b> en la terminal</li><li><b>Tiling</b> opcional con Meta+Shift+T</li></ul></div>',
'05-visual':'<div class="wrap"><div class="eyebrow">Propuesta de valor · Personalización visual</div><h1>Una identidad,<br>del arranque <em>al editor</em>.</h1><p class="lead">Una sola paleta de marca colorea GRUB, la pantalla de carga, el login, el escritorio, la terminal y los editores. Tema oscuro y claro, y 11 fondos propios.</p></div>',
'06-catalogo':'<div class="wrap"><div class="eyebrow">Propuesta de valor · Catálogo</div><h1>Herramientas <em>preinstaladas</em></h1><ul><li><b>Lenguajes:</b> C/C++, Python, Java, Go, Rust, Node.js, Bun, Deno</li><li><b>Editores:</b> Code - OSS, Neovim, Helix</li><li><b>Contenedores:</b> Docker, Podman, distrobox</li><li><b>Git:</b> Git, GitHub CLI, lazygit</li><li><b>Terminal:</b> kitty, zsh, zellij, yazi, btop</li><li><b>IA:</b> OpenCode, Gemini CLI, Codex, Claude Code</li></ul></div>',
'07-demo':'<div class="wrap"><div class="eyebrow">Demostración práctica</div><h1>monOS, <em>en acción</em>.</h1><p class="lead">Escritorio, aplicaciones, terminal y ventanas en mosaico, grabados en una instalación real.</p></div>',
'08-instalacion':'<div class="wrap"><div class="eyebrow">Demostración práctica</div><h1>Instalarlo toma<br><em>unos minutos</em>.</h1><p class="lead">Desde el escritorio en vivo: idioma, disco, software opcional y usuario.</p></div>',
'09-disponibilidad':'<div class="wrap"><div class="eyebrow">Disponibilidad</div><h1>Disponible <em>hoy</em>.</h1><p class="lead">Sitio oficial con capturas, requisitos y descarga directa de la ISO desde Google Drive.</p><div class="url">monos-os.vercel.app</div></div>',
'10-descarga':'<div class="wrap"><div class="eyebrow">Cómo conseguirlo</div><h1>Descarga en <em>3 pasos</em></h1><ul style="grid-template-columns:1fr"><li><b>1.</b> Entra a monos-os.vercel.app y toca <b>Descargar ISO</b></li><li><b>2.</b> Graba la ISO en una USB con Ventoy o balenaEtcher</li><li><b>3.</b> Arranca desde la USB: pruébalo en vivo e instálalo</li></ul></div>',
'11-outro':'<div class="wrap" style="align-items:center;text-align:center"><div class="logo"><img src="monos-icon.svg"><div class="big">mon<span>OS</span></div></div><div class="url">monos-os.vercel.app</div><div class="team">Cristian Antonio Mendoza Mendoza · Walter Emanuel Figueroa Vásquez<br>Freidh Yannel Morales Gonzalez · Francisco David Diego Noriega<br>Sistemas Operativos · 2026</div><div class="credit">Música: “Path Of The Fireflies” by AERØHEAD · breakingcopyright.com/song/aerohead-path-of-the-fireflies<br>Creative Commons BY-NC 3.0 · creativecommons.org/licenses/by-nc/3.0</div></div>',
}
for n,b in cards.items(): page(n,b)
caps={
'c-escritorio':('Escritorio','Barra en islas, dock y lanzador de aplicaciones'),
'c-editores':('Editores','Code - OSS y Neovim con el tema de monOS'),
'c-yazi':('Terminal','Yazi: archivos con vista previa, desde el teclado'),
'c-btop':('Rendimiento','btop: CPU, memoria, discos y procesos'),
'c-dolphin':('Archivos','Dolphin con terminal integrada'),
'c-obsidian':('Notas','Obsidian con el tema de monOS'),
'c-temas':('Personalización','Tema claro y fondos propios en un clic'),
'c-tiling':('Tiling','Meta+Shift+T: las ventanas se acomodan solas'),
'c-instalacion':('Instalación','Calamares: del live USB al disco (acelerado)'),
'c-sitio':('Sitio oficial','monos-os.vercel.app'),
'c-login':('Inicio de sesión','Pantalla de login propia'),
'c-paquetes':('Software opcional','17 grupos que se descargan al instalar'),
}
for n,(t,s) in caps.items():
    page(n,f'<div class="bar"><img src="monos-icon.svg"><span class="t">{html.escape(t)}</span><span class="s">{html.escape(s)}</span></div>',CAP)
print('ok')
