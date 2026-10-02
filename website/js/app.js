const DATA = {
  categories: [
    { id:"install", label:"ISO", name:"Instalación", desc:"Live USB e instalador gráfico" },
    { id:"desktop", label:"UI", name:"Escritorio", desc:"KDE Plasma, login, tema claro y tiling" },
    { id:"terminal", label:"SH", name:"Terminal", desc:"kitty, zsh y Yazi" },
    { id:"devtools", label:"DEV", name:"Herramientas de desarrollo", desc:"Code - OSS y Neovim" },
    { id:"pkg", label:"PKG", name:"Gestor de paquetes", desc:"pacman y Discover" },
    { id:"sec", label:"SEC", name:"Seguridad", desc:"Firewall, snapshots y cifrado" },
    { id:"perf", label:"PERF", name:"Rendimiento", desc:"Barra y memoria" }
  ],
  components: [
    { id:"install", name:"Instalación", flag:"Con video",
      products:[
        { video:"media/instalacion.mp4", poster:"media/instalacion-poster.webp", alt:"Video de la instalación de monOS con Calamares", brand:"Video · Calamares", name:"Instalación completa",
          desc:"Desde el escritorio en vivo: idioma, teclado, particiones, software opcional y usuario, hasta copiar el sistema al disco.",
          specs:{Instalador:"Calamares", Duración:"~5 min"} },
        { img:"images/instalador-paquetes.webp", alt:"Página de software opcional del instalador con 17 grupos", brand:"Captura · Instalador", name:"Software opcional por área",
          desc:"17 grupos que se descargan durante la instalación: IA, móvil, ciencia de datos, embebidos, juegos, DevOps, bases de datos y más.",
          specs:{Grupos:"17", "Por defecto":"IA"} },
        { img:"images/instalador-final.webp", alt:"Pantalla final del instalador: All done", brand:"Captura · Instalador", name:"Listo para reiniciar",
          desc:"Al terminar, el instalador ofrece reiniciar directo al sistema instalado o seguir en la sesión en vivo.",
          specs:{Arranque:"GRUB", Kernels:"linux + lts"} }
      ],
      reco:{title:"Pruébalo antes de instalar", note:"La misma ISO arranca en vivo y se instala desde el escritorio en unos minutos."} },
    { id:"desktop", name:"Escritorio", flag:"Con capturas",
      products:[
        { img:"images/sddm.webp", alt:"Pantalla de inicio de sesión de monOS", brand:"Captura · SDDM", name:"Inicio de sesión",
          desc:"Pantalla de login propia con reloj, sesión Plasma (Wayland), distribución de teclado y botones de energía.",
          specs:{Gestor:"SDDM", Sesión:"Wayland"} },
        { img:"images/tema-claro.webp", alt:"Escritorio de monOS con el tema claro", brand:"Captura · Tema claro", name:"monOS Light",
          desc:"El mismo escritorio en versión clara: colores, íconos e islas de la barra se adaptan al tema.",
          specs:{Tema:"Claro", "Tema global":"monOS Light"} },
        { video:"media/tiling.mp4", poster:"media/tiling-poster.webp", alt:"Video del modo tiling acomodando ventanas", brand:"Video · Krohnkite", name:"Ventanas en mosaico",
          desc:"Con Meta+Shift+T las ventanas se acomodan solas en mosaico; aquí con btop, fastfetch y yazi.",
          specs:{Atajo:"Meta+Shift+T", Script:"Krohnkite"} },
        { img:"images/escritorio.webp", alt:"Escritorio de monOS con barra superior, dock inferior y la mascota al centro", brand:"Captura · KDE Plasma", name:"Escritorio con barra y dock",
          desc:"Barra superior con espacios de trabajo, reloj y estado del sistema (CPU, memoria, sonido, Bluetooth y red), y un dock inferior con lanzador, terminal, archivos, navegador y papelera.",
          specs:{Barra:"Superior", Dock:"Inferior"} },
        { img:"images/launcher.webp", alt:"Lanzador de aplicaciones de monOS sobre el fondo desenfocado", brand:"Captura · KDE Plasma", name:"Lanzador de aplicaciones",
          desc:"Favoritos, buscador, lista alfabética con categorías a la derecha y botones de sesión, sobre el fondo desenfocado.",
          specs:{Favoritos:"4 apps", Sesión:"Salir · Reiniciar · Apagar"} },
        { img:"images/dolphin.webp", alt:"Explorador de archivos Dolphin en la carpeta personal", brand:"Captura · Archivos", name:"Explorador Dolphin",
          desc:"Explorador gráfico de KDE con las carpetas del usuario, vista de detalles y panel de lugares.",
          specs:{App:"Dolphin", Vista:"Detalles"} },
        { img:"images/fondo-espacio.webp", alt:"Fondo de pantalla de monOS: mono programando en el espacio", brand:"Captura · Fondos", name:"Fondo: mono en el espacio",
          desc:"Fondo oscuro con la mascota de monOS programando frente a una terminal.",
          specs:{Tema:"Oscuro", Mascota:"Mono"} },
        { img:"images/fondo-audifonos.webp", alt:"Fondo de pantalla de monOS: mono con audífonos", brand:"Captura · Fondos", name:"Fondo: mono con audífonos",
          desc:"Ilustración azul del mono con audífonos escribiendo en una tablet, con el logo de monOS.",
          specs:{Tema:"Azul", Mascota:"Mono"} },
        { img:"images/fondo-cafe.webp", alt:"Fondo de pantalla de monOS: mono con café", brand:"Captura · Fondos", name:"Fondo: mono con café",
          desc:"Versión clara del fondo, con el mono, una taza de café y circuitos alrededor.",
          specs:{Tema:"Claro", Mascota:"Mono"} }
      ],
      reco:{title:"KDE Plasma", note:"Escritorio con fondos propios de monOS, en versión oscura y clara."} },
    { id:"terminal", name:"Terminal", flag:"Con capturas",
      products:[
        { img:"images/fastfetch.webp", alt:"fastfetch mostrando la información del sistema monOS", brand:"Captura · kitty", name:"Información del sistema (fastfetch)",
          desc:"Muestra el logo de monOS junto con el kernel, los paquetes, la pantalla, la terminal y el entorno de escritorio.",
          specs:{Terminal:"kitty", Paquetes:"1133 (pacman)"} },
        { img:"images/yazi.webp", alt:"Yazi, explorador de archivos en la terminal", brand:"Captura · kitty", name:"Yazi, archivos en la terminal",
          desc:"Navegación por carpetas con el teclado, panel de vista previa y barra de estado.",
          specs:{Modo:"NORMAL", Control:"Teclado"} }
      ],
      reco:{title:"kitty + zsh", note:"Terminal con prompt, colores y atajos ya configurados."} },
    { id:"devtools", name:"Herramientas de desarrollo", flag:"Con capturas",
      products:[
        { img:"images/vscode.webp", alt:"Code - OSS abierto con el archivo .zshrc de monOS", brand:"Captura · Editor", name:"Code - OSS",
          desc:"Editor gráfico incluido, abierto aquí con el archivo ~/.zshrc de monOS.",
          specs:{Editor:"Code - OSS", Lenguaje:"Shell Script"} },
        { img:"images/neovim-zshrc.webp", alt:"Neovim mostrando la configuración modular de zsh", brand:"Captura · Editor", name:"Neovim en la terminal",
          desc:"El mismo archivo en Neovim: documenta cómo se carga la configuración de zsh por módulos.",
          specs:{Editor:"nvim", Archivo:"~/.zshrc"} }
      ],
      reco:{title:"Dos editores, un flujo", note:"Editor gráfico y editor en terminal incluidos en el sistema."} },
    { id:"pkg", name:"Gestor de paquetes", flag:"Con capturas",
      products:[
        { img:"images/pkg-pacman.webp", alt:"fastfetch mostrando kernel arch y 1133 paquetes con pacman", brand:"Captura · fastfetch", name:"pacman sobre Arch",
          desc:"El sistema reporta un kernel arch1 y 1133 paquetes instalados con pacman.",
          specs:{Kernel:"7.2.8-arch1-1", Paquetes:"1133"} },
        { img:"images/pkg-discover-btrfs.webp", alt:"Discover en favoritos y Btrfs Assistant en la lista de aplicaciones", brand:"Captura · Lanzador", name:"Discover y Btrfs Assistant",
          desc:"Discover como tienda gráfica de software en los favoritos, y Btrfs Assistant para administrar el sistema de archivos.",
          specs:{Tienda:"Discover", Sistema:"Btrfs"} }
      ],
      reco:{title:"pacman + Discover", note:"Gestor en terminal y tienda gráfica para instalar software."} },
    { id:"sec", name:"Seguridad", flag:"Capturas pendientes",
      products:[
        { brand:"Captura pendiente · Firewall", name:"Firewall activo desde el inicio",
          desc:"ufw bloquea las conexiones entrantes y permite las salientes; se administra desde la Configuración del sistema. Solo se abren los puertos de KDE Connect.",
          specs:{Firewall:"ufw", Entrante:"Bloqueado"} },
        { brand:"Captura pendiente · Btrfs", name:"Snapshots para volver atrás",
          desc:"Snapper toma un snapshot antes de cada actualización; si algo se rompe, se arranca un snapshot anterior desde GRUB y se restaura con Btrfs Assistant.",
          specs:{Sistema:"Btrfs + Snapper", Arranque:"GRUB"} },
        { img:"images/instalador-particiones.webp", alt:"Página de particiones del instalador con la opción Encrypt system", brand:"Captura · Instalador", name:"Disco cifrado opcional",
          desc:"El instalador permite cifrar todo el disco con LUKS: sin la contraseña, los datos no se pueden leer aunque se saque el disco.",
          specs:{Cifrado:"LUKS", Opcional:"Sí"} }
      ],
      reco:{title:"Seguro por defecto", note:"Firewall activo, snapshots automáticos y cifrado de disco a un clic en el instalador."} },
    { id:"perf", name:"Rendimiento", flag:"Con capturas",
      products:[
        { img:"images/perf-barra.webp", alt:"Barra superior de monOS con indicadores de CPU y memoria", brand:"Captura · Barra superior", name:"Monitor en la barra superior",
          desc:"La barra muestra indicadores de uso de CPU y de memoria junto al resto del estado del sistema.",
          specs:{CPU:"Indicador", Memoria:"Indicador"} },
        { img:"images/perf-memoria.webp", alt:"fastfetch mostrando 2.75 GiB de 30.83 GiB de memoria en uso", brand:"Captura · fastfetch", name:"Memoria en reposo",
          desc:"Con el sistema recién iniciado, fastfetch reporta 2.75 GiB usados de 30.83 GiB (9%).",
          specs:{RAM:"2.75 / 30.83 GiB", Uptime:"8 min"} }
      ],
      reco:{title:"Ligero en reposo", note:"9% de memoria en uso con el escritorio recién iniciado."} }
  ],
  recommendations: [
    { tag:"Estudiantes", title:"Aprender a programar sin pelear con el sistema", note:"Compiladores, editores y terminal configurados desde el primer arranque: C, C++, Python, Java, Go, Rust y JavaScript listos para usar en clase." },
    { tag:"Desarrollo web y backend", title:"De la idea al contenedor", note:"Node.js, Bun, Deno, Python con uv, Docker, Podman y distrobox, más clientes de API y bases de datos opcionales en el instalador." },
    { tag:"Ciencia de datos, IA y más", title:"Un abanico para cada área", note:"Agentes de IA, JupyterLab, PyTorch, Android y Flutter, embebidos con Arduino, juegos con Godot y DevOps con Kubernetes: se eligen al instalar." }
  ],
  featured: [
    { tag:"Destacado", mark:"01", title:"Identidad propia", desc:"Logo, mascota, temas oscuro y claro, y 11 fondos de pantalla; los mismos colores del arranque al editor." },
    { tag:"Destacado", mark:"02", title:"Pruébalo e instálalo", desc:"Live USB con instalador gráfico, snapshots Btrfs para volver atrás y grupos de software opcionales por área." },
    { tag:"Destacado", mark:"03", title:"Listo para programar", desc:"Lenguajes, servidores de lenguaje, contenedores y agentes de IA desde el primer arranque." }
  ],
  software: [
    { tag:"Terminal", title:"kitty + zsh", desc:"Terminal de monOS con Starship, autosugerencias, zellij y tmux." },
    { tag:"Editor", title:"Code - OSS", desc:"Editor gráfico con el tema de monOS." },
    { tag:"Editor", title:"Neovim y Helix", desc:"Editores en terminal, con servidores de lenguaje para Python, Rust, Go, TypeScript y más." },
    { tag:"Lenguajes", title:"C/C++, Python, Java, Go, Rust", desc:"GCC, Clang, CMake, OpenJDK 21, rustup y uv incluidos." },
    { tag:"JavaScript", title:"Node.js, Bun y Deno", desc:"Con npm y pnpm para cualquier proyecto web." },
    { tag:"Contenedores", title:"Docker, Podman, distrobox", desc:"Contenedores listos y otras distros dentro de monOS." },
    { tag:"IA", title:"OpenCode, Gemini CLI, Codex", desc:"Agentes de IA en la terminal; Claude Code y Antigravity como opción." },
    { tag:"Git", title:"Git, GitHub CLI, lazygit", desc:"Control de versiones con interfaz en terminal y diffs con delta." },
    { tag:"Archivos", title:"Dolphin y Yazi", desc:"Explorador gráfico con terminal integrada y explorador en terminal." },
    { tag:"Internet", title:"Firefox", desc:"Navegador web incluido en los favoritos." },
    { tag:"Notas", title:"Obsidian", desc:"Notas en Markdown con el tema de monOS aplicado a cada bóveda." },
    { tag:"Sistema", title:"btop y Btrfs Assistant", desc:"Monitor de recursos y snapshots del sistema de archivos." }
  ]
};

function renderCategories(){
  const rail = document.getElementById('category-rail');
  rail.innerHTML = DATA.categories.map(c => `
    <button class="category-link" data-filter="${c.id}">
      <span>${c.label}</span><strong>${c.name}</strong><small>${c.desc}</small>
    </button>`).join('');
  rail.querySelectorAll('.category-link').forEach(btn=>{
    btn.addEventListener('click', ()=> applyFilter(btn.dataset.filter));
  });
}

function renderFilters(){
  const row = document.getElementById('filters');
  const all = [{id:'all', label:'Todos'}, ...DATA.categories.map(c=>({id:c.id, label:c.name}))];
  row.innerHTML = all.map(c => `<button class="filter-btn${c.id==='all'?' active':''}" data-filter="${c.id}">${c.label}</button>`).join('');
  row.querySelectorAll('.filter-btn').forEach(btn=>{
    btn.addEventListener('click', ()=> applyFilter(btn.dataset.filter));
  });
}

let activeFilter = 'all';
function applyFilter(id){
  activeFilter = id;
  document.querySelectorAll('.filter-btn').forEach(b=> b.classList.toggle('active', b.dataset.filter===id));
  renderComponents();
  if(id!=='all'){
    const target = document.getElementById('comp-'+id);
    if(target) target.scrollIntoView({behavior:'smooth'});
  }
}

function renderComponents(){
  const term = (document.getElementById('search').value || '').toLowerCase();
  const list = document.getElementById('component-list');
  let shown = 0;
  const html = DATA.components.map((comp, i) => {
    if(activeFilter!=='all' && comp.id!==activeFilter) return '';
    const matches = term==='' || comp.name.toLowerCase().includes(term) ||
      comp.products.some(p => (p.name + ' ' + p.desc).toLowerCase().includes(term));
    if(!matches) return '';
    shown++;
    const pending = comp.products.filter(p => !p.img && !p.video).length;
    const products = comp.products.map(p => `
      <article class="product-card${p.video ? ' has-video' : p.img ? ' has-shot' : ''}">
        <div class="product-image">${p.video
          ? `<video controls preload="none" playsinline poster="${p.poster}" aria-label="${p.alt || p.name}"><source src="${p.video}" type="video/mp4" /></video>`
          : p.img
          ? `<img src="${p.img}" alt="${p.alt || p.name}" loading="lazy" />`
          : '<span>📷</span>'}</div>
        <div class="product-content">
          <p class="product-brand">${p.brand}</p>
          <h4>${p.name}</h4>
          <p class="product-shop">${p.desc}</p>
          <div class="spec-list">${Object.entries(p.specs).map(([k,v])=>`<div>${k}<b>${v}</b></div>`).join('')}</div>
        </div>
      </article>`).join('');
    const hasBars = comp.compare && comp.compare.length;
    const bars = hasBars ? comp.compare.map(b => `
      <div><span class="bar-line">${b.label}</span><div class="bar"><i style="width:${b.a}%"></i></div></div>`).join('') : '';
    const compareBlock = hasBars
      ? `<div class="compare-bars">${bars}</div><div class="compare-bars"></div>`
      : '';
    return `
      <div class="component-section" id="comp-${comp.id}">
        <div class="component-header">
          <div class="component-title"><span class="component-number">0${i+1}</span><div><h3>${comp.name}</h3><p>${comp.products.length} elementos${pending ? ` · ${pending} por documentar` : ''}</p></div></div>
          <span class="component-flag">${comp.flag}</span>
        </div>
        <div class="product-grid">
          ${products}
          <div class="comparison${hasBars ? '' : ' reco-only'}">
            ${compareBlock}
            <div class="reco"><small>Veredicto</small><strong>${comp.reco.title}</strong><p>${comp.reco.note}</p></div>
          </div>
        </div>
      </div>`;
  }).join('');
  list.innerHTML = html || '<p class="empty-state">No encontramos módulos con ese criterio.</p>';
  document.getElementById('count').textContent = `Mostrando ${shown} de ${DATA.components.length} módulos`;
  const pendingModules = DATA.components.filter(c => c.products.some(p => !p.img && !p.video)).length;
  const note = document.querySelector('.catalog-status span:last-child');
  if(note) note.textContent = pendingModules ? `${pendingModules} ${pendingModules === 1 ? "módulo" : "módulos"} con capturas pendientes` : 'Todas las capturas agregadas';
}

function renderRecommendations(){
  document.getElementById('recommendation-grid').innerHTML = DATA.recommendations.map(r => `
    <div class="recommendation-card reveal"><div class="reco"><small>${r.tag}</small><strong>${r.title}</strong><p>${r.note}</p></div></div>`).join('');
}

function renderFeatured(){
  document.getElementById('featured-grid').innerHTML = DATA.featured.map(f => `
    <article class="featured-card reveal"><span>${f.tag}</span><b>${f.mark}</b><h3>${f.title}</h3><p>${f.desc}</p></article>`).join('');
}

function renderSoftware(){
  document.getElementById('software-grid').innerHTML = DATA.software.map(s => `
    <article class="software-card reveal"><span>${s.tag}</span><h4>${s.title}</h4><p>${s.desc}</p></article>`).join('');
}

/* Visor ampliado: clic en una captura para verla en grande */
function openLightbox(src, alt){
  const box = document.createElement('div');
  box.className = 'lightbox';
  box.setAttribute('role', 'dialog');
  box.setAttribute('aria-label', alt || 'Captura ampliada');
  box.innerHTML = `<button class="lightbox-close" aria-label="Cerrar">✕</button><img src="${src}" alt="${alt || ''}" />`;
  const close = () => { box.remove(); document.removeEventListener('keydown', onKey); };
  const onKey = e => { if(e.key === 'Escape') close(); };
  box.addEventListener('click', close);
  document.addEventListener('keydown', onKey);
  document.body.appendChild(box);
}
document.getElementById('component-list').addEventListener('click', e => {
  const img = e.target.closest('.has-shot .product-image img');
  if(img) openLightbox(img.src, img.alt);
});

window.addEventListener('scroll', ()=>{
  const h = document.documentElement;
  const pct = (h.scrollTop) / (h.scrollHeight - h.clientHeight) * 100;
  document.getElementById('reading-progress').style.width = pct + '%';
  document.getElementById('to-top').classList.toggle('visible', h.scrollTop > 500);
});

const menuToggle = document.getElementById('menu-toggle');
const mobileNav = document.getElementById('mobile-nav');
menuToggle.addEventListener('click', ()=>{
  const open = mobileNav.classList.toggle('open');
  menuToggle.setAttribute('aria-expanded', open);
});
mobileNav.querySelectorAll('a').forEach(a => a.addEventListener('click', ()=>{
  mobileNav.classList.remove('open'); menuToggle.setAttribute('aria-expanded','false');
}));

const themeBtn = document.getElementById('theme-switch');
function setTheme(light){
  document.documentElement.setAttribute('data-theme', light ? 'light' : 'dark');
  themeBtn.setAttribute('aria-pressed', light);
  themeBtn.querySelector('.switch-label').textContent = light ? 'Tema claro' : 'Tema oscuro';
  try{ localStorage.setItem('monos-theme', light ? 'light':'dark'); }catch(e){}
}
themeBtn.addEventListener('click', ()=> setTheme(document.documentElement.getAttribute('data-theme')!=='light'));
try{ setTheme(localStorage.getItem('monos-theme')==='light'); }catch(e){}

document.getElementById('to-top').addEventListener('click', ()=> window.scrollTo({top:0, behavior:'smooth'}));
document.getElementById('search').addEventListener('input', renderComponents);

const io = new IntersectionObserver(entries=>{
  entries.forEach(e=>{ if(e.isIntersecting) e.target.classList.add('is-visible'); });
},{threshold:.15});

function init(){
  renderCategories();
  renderFilters();
  renderComponents();
  renderRecommendations();
  renderFeatured();
  renderSoftware();
  document.querySelectorAll('.reveal').forEach(el=> io.observe(el));
}
init();
