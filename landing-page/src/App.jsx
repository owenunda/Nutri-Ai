import { useEffect, useState } from 'react';
import { legalDocuments } from './legalDocuments.js';

const contactEmail = 'oweenunda.dev@gmail.com';

const navigation = [
  { label: 'Inicio', route: '/' },
  { label: 'Privacidad', route: '/privacidad' },
  { label: 'Términos y Condiciones', route: '/terminos' },
  { label: 'Eliminar datos', route: '/eliminacion-de-datos' },
  { label: 'Soporte', route: '/soporte' },
];

function Otter({ name, className = '', alt = '' }) {
  return (
    <img
      className={`otter ${className}`.trim()}
      src={`/nutrias/${name}.webp`}
      alt={alt}
      aria-hidden={alt ? undefined : 'true'}
      loading="lazy"
      decoding="async"
    />
  );
}

function currentRoute() {
  const route = window.location.hash.replace(/^#/, '').split('?')[0];
  return route || '/';
}

function SiteHeader({ activeRoute }) {
  return (
    <header className="site-header">
      <div className="header-inner">
        <a className="brand" href="#/" aria-label="NutriLife, inicio">
          <span className="brand-mark" aria-hidden="true">
            <img src="/nutrias/feliz.webp" alt="" />
          </span>
          <span>NutriLife</span>
        </a>
        <nav className="main-nav" aria-label="Navegación principal">
          {navigation.map(({ label, route }) => (
            <a
              key={route}
              className={activeRoute === route ? 'nav-link is-active' : 'nav-link'}
              href={`#${route}`}
              aria-current={activeRoute === route ? 'page' : undefined}
            >
              {label}
            </a>
          ))}
        </nav>
      </div>
    </header>
  );
}

function SiteFooter() {
  return (
    <footer className="site-footer">
      <span className="footer-brand">
        <Otter name="sentada" className="footer-otter" />
        © 2026 NutriLife
      </span>
      <nav aria-label="Enlaces del pie de página">
        {navigation.slice(1).map(({ label, route }) => (
          <a href={`#${route}`} key={route}>{label}</a>
        ))}
      </nav>
    </footer>
  );
}

function SiteFrame({ activeRoute, children }) {
  return (
    <>
      <SiteHeader activeRoute={activeRoute} />
      <main className="page-content">{children}</main>
      <div className="footer-wrap"><SiteFooter /></div>
    </>
  );
}

function SectionHeading({ children }) {
  return <h2 className="section-heading">{children}</h2>;
}

function FeatureIcon({ kind }) {
  const paths = {
    goal: <><path d="M12 21s8-4 8-11V5l-8-3-8 3v5c0 7 8 11 8 11Z" /><path d="m9 12 2 2 4-4" /></>,
    meals: <><path d="M3 11h18" /><path d="M5 11a7 7 0 0 1 14 0" /><path d="M5 11v8h14v-8" /><path d="M9 15h.01M12 15h.01M15 15h.01" /></>,
    ai: <><path d="m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3Z" /><path d="m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15Z" /></>,
    progress: <><path d="M4 19V5" /><path d="M4 19h16" /><path d="m7 14 4-4 3 2 5-6" /><path d="M16 6h3v3" /></>,
    privacy: <><path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z" /><path d="m9 12 2 2 4-4" /></>,
    terms: <><path d="M7 3h7l5 5v13H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z" /><path d="M14 3v5h5M9 13h6M9 17h6" /></>,
    delete: <><path d="M4 7h16M10 11v6M14 11v6" /><path d="m6 7 1 14h10l1-14M9 7V4h6v3" /></>,
    support: <><path d="M4 13v-2a8 8 0 0 1 16 0v2" /><path d="M4 13h3v6H6a2 2 0 0 1-2-2v-4ZM20 13h-3v6h1a2 2 0 0 0 2-2v-4ZM17 20c-1 1-2.7 1.5-5 1.5" /></>,
  };
  return (
    <span className="feature-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        {paths[kind] || paths.goal}
      </svg>
    </span>
  );
}

function InfoCard({ icon, otter, title, children, action }) {
  return (
    <article className={otter ? 'info-card has-otter' : 'info-card'}>
      {otter && (
        <div className="card-otter-stage" aria-hidden="true">
          <Otter name={otter} />
        </div>
      )}
      <div className="card-heading">
        {!otter && <FeatureIcon kind={icon} />}
        <h3>{title}</h3>
      </div>
      <div className="card-copy">{children}</div>
      {action && <div className="card-action">{action}</div>}
    </article>
  );
}

function LinkCard({ icon, title, description, route }) {
  return (
    <a className="link-card" href={`#${route}`}>
      <FeatureIcon kind={icon} />
      <span className="link-card-copy">
        <strong>{title}</strong>
        <span>{description}</span>
      </span>
      <span className="link-arrow" aria-hidden="true">→</span>
    </a>
  );
}

function HomePage() {
  return (
    <SiteFrame activeRoute="/">
      <section className="hero-card">
        <div className="hero-copy">
          <span className="eyebrow">TU ASISTENTE NUTRICIONAL</span>
          <h1>Bienvenido a nuestra web</h1>
          <p>
            NutriLife reúne el registro de comidas, tus objetivos y el seguimiento
            de tu progreso, junto con herramientas para encontrar ideas de
            alimentación. Queremos ayudarte a conocer mejor tus hábitos y avanzar
            a tu propio ritmo.
          </p>
          <a className="button button-primary" href="#/soporte">Conoce más sobre NutriLife <span aria-hidden="true">→</span></a>
        </div>
        <div className="hero-stage" aria-hidden="true">
          <div className="hero-notes">
            <span className="speech-bubble">¡Hola! Te acompaño en cada comida</span>
            <span className="float-chip chip-goal">
              <span className="chip-label">META DIARIA</span>
              <strong>1.850 kcal</strong>
              <span className="chip-bar"><span /></span>
            </span>
            <span className="float-chip chip-meal">
              <span className="chip-check">✓</span>
              Almuerzo registrado
            </span>
          </div>
          <div className="hero-figure">
            <span className="hero-circle" />
            <span className="hero-shadow" />
            <Otter name="saludando" className="hero-otter" />
          </div>
        </div>
      </section>

      <section className="content-section">
        <SectionHeading>Nuestro objetivo</SectionHeading>
        <article className="mission-card">
          <div className="mission-copy">
            <h3>Acompañarte a organizar tus hábitos de alimentación</h3>
            <p>
              NutriLife busca ayudarte a tener una visión más clara de lo que comes y
              de tus metas. Para eso reúne en un mismo lugar el registro de alimentos,
              el seguimiento de calorías y peso, y un asistente con IA para explorar
              opciones de alimentación.
            </p>
          </div>
          <Otter name="agua" className="mission-otter" />
        </article>
      </section>

      <section className="content-section">
        <SectionHeading>¿Qué encontrarás en la app?</SectionHeading>
        <div className="feature-grid">
          <InfoCard otter="cintametrica" title="Perfil y objetivos nutricionales">
            Completa tus datos, como edad, estatura y peso, y elige si tu objetivo
            es bajar, mantener o subir de peso. La app usa esa información para
            mostrarte una meta diaria de calorías.
          </InfoCard>
          <InfoCard otter="comiendo" title="Alimentos, comidas e historial">
            Busca alimentos en el catálogo común o registra los tuyos. Añádelos a
            tus comidas —desayuno, almuerzo, cena o snack— y consulta lo que has
            guardado en el historial.
          </InfoCard>
          <InfoCard otter="pensando" title="Asistente nutricional con IA">
            Pide recetas, consejos de nutrición o planes de alimentación. En una
            consulta puedes incluir alimentos comunes o productos de tu nevera;
            las recetas también se pueden revisar y registrar como comida.
          </InfoCard>
          <InfoCard otter="pesas" title="Resumen y progreso">
            Revisa las calorías consumidas y tu meta del día, consulta el resumen
            semanal y registra tu peso para ver su historial.
          </InfoCard>
        </div>
      </section>

      <section className="content-section">
        <SectionHeading>Información del servicio</SectionHeading>
        <div className="link-grid">
          <LinkCard icon="privacy" title="Política de privacidad" description="Conoce el tratamiento de tus datos personales." route="/privacidad" />
          <LinkCard icon="terms" title="Términos y Condiciones" description="Consulta las condiciones de uso de NutriLife." route="/terminos" />
          <LinkCard icon="delete" title="Eliminación de cuenta y datos" description="Revisa cómo solicitar la eliminación." route="/eliminacion-de-datos" />
          <LinkCard icon="support" title="Soporte" description="Escríbenos si necesitas ayuda." route="/soporte" />
        </div>
      </section>

      <section className="closing-band">
        <Otter name="celebracion" className="closing-otter" />
        <div>
          <h2>Cada pequeño paso cuenta</h2>
          <p>Registra, aprende y celebra tu progreso con NutriLife.</p>
        </div>
        <a className="button button-light" href="#/soporte">Hablar con nosotros</a>
      </section>
    </SiteFrame>
  );
}

function PageHeading({ eyebrow, title, otter, children }) {
  return (
    <div className="document-heading">
      <div className="document-heading-copy">
        <span className="eyebrow">{eyebrow}</span>
        <h1>{title}</h1>
        {children}
      </div>
      {otter && <Otter name={otter} className="heading-otter" />}
    </div>
  );
}

function LegalBlock({ block }) {
  if (block.type === 'bullets') {
    return <ul className="legal-list">{block.items.map((item, index) => <li key={index}>{item}</li>)}</ul>;
  }
  if (block.type === 'note') return <aside className="legal-note">{block.text}</aside>;
  return <p className="legal-paragraph">{block.text}</p>;
}

function LegalDocumentPage({ document, route }) {
  return (
    <SiteFrame activeRoute={route}>
      <PageHeading eyebrow="INFORMACIÓN LEGAL" title={document.title} otter={route === '/privacidad' ? 'atenta' : 'leyendo'}>
        <p className="updated-at">Última actualización: {legalDocuments.updatedAt}</p>
      </PageHeading>
      {document.intro.map((block, index) => <LegalBlock block={block} key={`intro-${index}`} />)}
      <div className="legal-sections">
        {document.sections.map((section) => (
          <section className="legal-section" key={section.title}>
            <h2>{section.title}</h2>
            {section.blocks.map((block, index) => <LegalBlock block={block} key={`${section.title}-${index}`} />)}
          </section>
        ))}
      </div>
      {route === '/privacidad' && (
        <LinkCard icon="delete" title="¿Quieres eliminar tu cuenta?" description="Consulta la página de eliminación de cuenta y datos." route="/eliminacion-de-datos" />
      )}
      {route === '/terminos' && (
        <LinkCard icon="privacy" title="Política de privacidad" description="Lee cómo tratamos los datos personales." route="/privacidad" />
      )}
    </SiteFrame>
  );
}

function DataDeletionPage() {
  const subject = encodeURIComponent('Solicitud de eliminación de cuenta NutriLife');
  const body = encodeURIComponent('Hola, quiero solicitar la eliminación de mi cuenta NutriLife. El correo asociado a mi cuenta es: ');
  const mailto = `mailto:${contactEmail}?subject=${subject}&body=${body}`;

  return (
    <SiteFrame activeRoute="/eliminacion-de-datos">
      <PageHeading eyebrow="CONTROL DE TUS DATOS" title="Eliminación de cuenta y datos" otter="triste" />
      <p className="page-intro">
        Puedes solicitar la eliminación de tu cuenta de NutriLife y de los datos
        personales asociados. Hay dos formas de hacerlo:
      </p>
      <div className="feature-grid deletion-grid">
        <InfoCard icon="delete" title="Desde la aplicación">
          Abre Perfil → Eliminar cuenta y sigue los pasos de confirmación que
          aparecen en la app.
        </InfoCard>
        <InfoCard icon="support" title="Desde esta página" action={<a className="button button-primary" href={mailto}>Solicitar eliminación por correo</a>}>
          Envía la solicitud desde el correo electrónico asociado a tu cuenta.
          Indica que deseas eliminar tu cuenta de NutriLife. No incluyas tu
          contraseña.
        </InfoCard>
      </div>
      <section className="legal-section deletion-related">
        <h2>Datos asociados</h2>
        <p className="legal-paragraph">
          La Política de Privacidad describe qué información se elimina al cerrar
          la cuenta y qué registro anónimo se conserva. Revísala antes de enviar
          la solicitud.
        </p>
        <LinkCard icon="privacy" title="Leer Política de Privacidad" description="Consulta el detalle de conservación y eliminación." route="/privacidad" />
      </section>
      <p className="contact-hint">Para consultas sobre el proceso, escríbenos a <a href={`mailto:${contactEmail}`}>{contactEmail}</a>.</p>
    </SiteFrame>
  );
}

function SupportPage() {
  return (
    <SiteFrame activeRoute="/soporte">
      <PageHeading eyebrow="ESTAMOS PARA AYUDAR" title="Soporte" otter="saludando" />
      <p className="page-intro">
        Si tienes preguntas sobre NutriLife, tu cuenta o tus datos, puedes
        escribirnos por correo electrónico.
      </p>
      <InfoCard icon="support" title="Correo de contacto" action={<a className="button button-primary" href={`mailto:${contactEmail}`}>Escribir a soporte</a>}>
        <a href={`mailto:${contactEmail}`}>{contactEmail}</a>
      </InfoCard>
    </SiteFrame>
  );
}

function NotFoundPage() {
  return (
    <SiteFrame activeRoute="">
      <PageHeading eyebrow="NUTRILIFE" title="Página no encontrada" otter="enojada" />
      <a className="button button-primary" href="#/">Volver al inicio</a>
    </SiteFrame>
  );
}

export default function App() {
  const [route, setRoute] = useState(currentRoute);

  useEffect(() => {
    const updateRoute = () => {
      setRoute(currentRoute());
      window.scrollTo({ top: 0, behavior: 'instant' });
    };
    window.addEventListener('hashchange', updateRoute);
    return () => window.removeEventListener('hashchange', updateRoute);
  }, []);

  if (route === '/') return <HomePage />;
  if (route === '/privacidad') return <LegalDocumentPage document={legalDocuments.privacy} route={route} />;
  if (route === '/terminos') return <LegalDocumentPage document={legalDocuments.terms} route={route} />;
  if (route === '/eliminacion-de-datos') return <DataDeletionPage />;
  if (route === '/soporte') return <SupportPage />;
  return <NotFoundPage />;
}
