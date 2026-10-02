const DATA = {
  categories: [
    { id:"desktop", label:"UI", name:"Escritorio", desc:"KDE Plasma, barra, dock y fondos" },
    { id:"terminal", label:"SH", name:"Terminal", desc:"kitty, zsh y Yazi" },
    { id:"devtools", label:"DEV", name:"Herramientas de desarrollo", desc:"Code - OSS y Neovim" },
    { id:"pkg", label:"PKG", name:"Gestor de paquetes", desc:"pacman y Discover" },
    { id:"sec", label:"SEC", name:"Seguridad", desc:"Pendiente" },
    { id:"perf", label:"PERF", name:"Rendimiento", desc:"Barra y memoria" }
  ],
  components: [
    { id:"desktop", name:"Escritorio", flag:"Con capturas",
      products:[
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
    { id:"sec", name:"Seguridad", flag:"Esperando contenido",
      products:[
        { brand:"Captura pendiente", name:"Nombre de la función", desc:"Breve descripción de la función de seguridad.", specs:{Estado:"Por definir",Prioridad:"Por definir"} },
        { brand:"Captura pendiente", name:"Nombre de la función", desc:"Breve descripción de la función de seguridad.", specs:{Estado:"Por definir",Prioridad:"Por definir"} }
      ],
      compare:[ {label:"Por definir", a:0}, {label:"Por definir", a:0} ],
      reco:{title:"Por definir", note:"Pendiente de agregar el punto clave de este módulo."} },
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
    { tag:"Pendiente", title:"Pendiente", note:"Agregaremos aquí un caso de uso real mañana." },
    { tag:"Pendiente", title:"Pendiente", note:"Agregaremos aquí un caso de uso real mañana." },
    { tag:"Pendiente", title:"Pendiente", note:"Agregaremos aquí un caso de uso real mañana." }
  ],
  featured: [
    { tag:"Destacado", mark:"01", title:"Identidad propia", desc:"Logo, mascota y fondos de pantalla en versión oscura y clara." },
    { tag:"Destacado", mark:"02", title:"Arch + KDE Plasma 6", desc:"Base Arch con pacman y un escritorio KDE Plasma con barra y dock." },
    { tag:"Destacado", mark:"03", title:"Listo para programar", desc:"Terminal kitty con zsh, Code - OSS, Neovim y CMake desde el primer arranque." }
  ],
  software: [
    { tag:"Terminal", title:"kitty", desc:"Terminal de monOS, con colores y prompt propios." },
    { tag:"Editor", title:"Code - OSS", desc:"Editor gráfico para programar." },
    { tag:"Editor", title:"Neovim", desc:"Editor en terminal, visto abriendo el ~/.zshrc de monOS." },
    { tag:"Archivos", title:"Dolphin", desc:"Explorador de archivos gráfico de KDE." },
    { tag:"Archivos", title:"Yazi", desc:"Explorador de archivos en la terminal, controlado con el teclado." },
    { tag:"Internet", title:"Firefox", desc:"Navegador web incluido en los favoritos." },
    { tag:"Desarrollo", title:"CMake", desc:"Herramienta para compilar proyectos en C y C++." },
    { tag:"Sistema", title:"btop++", desc:"Monitor de recursos: CPU, memoria, procesos y red." },
    { tag:"Sistema", title:"Btrfs Assistant", desc:"Administración del sistema de archivos Btrfs." }
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
    const pending = comp.products.filter(p => !p.img).length;
    const products = comp.products.map(p => `
      <article class="product-card${p.img ? ' has-shot' : ''}">
        <div class="product-image">${p.img
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
  const pendingModules = DATA.components.filter(c => c.products.some(p => !p.img)).length;
  const note = document.querySelector('.catalog-status span:last-child');
  if(note) note.textContent = pendingModules ? `${pendingModules} módulos con capturas pendientes` : 'Todas las capturas agregadas';
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
