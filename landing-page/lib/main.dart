import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal/legal_documents.dart';

const _primary = Color(0xFF2EB67D);
const _secondary = Color(0xFF4361EE);
const _tertiary = Color(0xFF00E0FD);
const _neutral = Color(0xFFF8FAFC);
const _contactEmail = 'oweenunda.dev@gmail.com';

void main() => runApp(const NutriLifeSite());

class NutriLifeSite extends StatelessWidget {
  const NutriLifeSite({super.key});

  String get _initialRoute {
    final fragment = Uri.base.fragment;
    return fragment.startsWith('/') ? fragment : '/';
  }

  Widget _pageFor(String route) => switch (route) {
        '/' => const HomePage(),
        '/privacidad' => const LegalDocumentPage(
            document: LegalDocuments.privacy,
            activeRoute: '/privacidad',
          ),
        '/terminos' => const LegalDocumentPage(
            document: LegalDocuments.terms,
            activeRoute: '/terminos',
          ),
        '/eliminacion-de-datos' => const DataDeletionPage(),
        '/soporte' => const SupportPage(),
        _ => const NotFoundPage(),
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          secondary: _secondary,
          tertiary: _tertiary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _neutral,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            color: Color(0xFF14231D),
          ),
          headlineMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF14231D),
          ),
          titleLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF14231D),
          ),
          bodyLarge: TextStyle(height: 1.7, color: Color(0xFF33423B)),
          bodyMedium: TextStyle(height: 1.65, color: Color(0xFF47564F)),
        ),
      ),
      initialRoute: _initialRoute,
      onGenerateRoute: (settings) {
        final path = Uri.tryParse(settings.name ?? '/')?.path ?? '/';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _pageFor(path),
        );
      },
    );
  }
}

class SiteFrame extends StatelessWidget {
  const SiteFrame({required this.activeRoute, required this.child, super.key});

  final String activeRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SiteHeader(activeRoute: activeRoute),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({required this.activeRoute});

  final String activeRoute;

  static const _links = <String, String>{
    'Inicio': '/',
    'Privacidad': '/privacidad',
    'Términos y Condiciones': '/terminos',
    'Eliminar datos': '/eliminacion-de-datos',
    'Soporte': '/soporte',
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6ECE9))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 16,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pushNamed('/'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, color: _primary, size: 28),
                          SizedBox(width: 9),
                          Text(
                            'NutriLife',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14231D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: _links.entries.map((entry) {
                      final selected = activeRoute == entry.value;
                      return TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(entry.value),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              selected ? _primary : const Color(0xFF53615A),
                          textStyle: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        child: Text(entry.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child, const SizedBox(height: 36), const _SiteFooter()],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SiteFrame(
      activeRoute: '/',
      child: _PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7EEE9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NutriLife',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido a nuestra web',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'NutriLife es tu asistente nutricional inteligente. La app reúne el '
                    'registro de comidas, tus objetivos y el seguimiento de tu progreso, '
                    'junto con herramientas para encontrar ideas de alimentación.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nuestro objetivo',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _InfoPanel(
              icon: Icons.track_changes_rounded,
              title: 'Acompañarte a organizar tus hábitos de alimentación',
              body:
                  'NutriLife busca ayudarte a tener una visión más clara de lo que '
                  'comes y de tus metas. Para eso reúne en un mismo lugar el registro '
                  'de alimentos, el seguimiento de calorías y peso, y un asistente '
                  'con IA para explorar opciones de alimentación.',
            ),
            const SizedBox(height: 28),
            const Text(
              '¿Qué encontrarás en la app?',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _InfoPanel(
              icon: Icons.flag_outlined,
              title: 'Perfil y objetivos nutricionales',
              body:
                  'Completa tus datos, como edad, estatura y peso, y elige si tu '
                  'objetivo es bajar, mantener o subir de peso. La app usa esa '
                  'información para mostrarte una meta diaria de calorías.',
            ),
            const SizedBox(height: 12),
            const _InfoPanel(
              icon: Icons.restaurant_menu_rounded,
              title: 'Alimentos, comidas e historial',
              body:
                  'Busca alimentos en el catálogo común o registra los tuyos. '
                  'Añádelos a tus comidas —desayuno, almuerzo, cena o snack— y '
                  'consulta lo que has guardado en el historial.',
            ),
            const SizedBox(height: 12),
            const _InfoPanel(
              icon: Icons.auto_awesome_outlined,
              title: 'Asistente nutricional con IA',
              body:
                  'Pide recetas, consejos de nutrición o planes de alimentación. '
                  'En una consulta puedes incluir alimentos comunes o productos de '
                  'tu nevera; las recetas también se pueden revisar y registrar como comida.',
            ),
            const SizedBox(height: 12),
            const _InfoPanel(
              icon: Icons.show_chart_rounded,
              title: 'Resumen y progreso',
              body:
                  'Revisa las calorías consumidas y tu meta del día, consulta el '
                  'resumen semanal y registra tu peso para ver su historial.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Información del servicio',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _PageLinkCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de privacidad',
              description: 'Conoce el tratamiento de tus datos personales.',
              route: '/privacidad',
            ),
            const _PageLinkCard(
              icon: Icons.description_outlined,
              title: 'Términos y Condiciones',
              description: 'Consulta las condiciones de uso de NutriLife.',
              route: '/terminos',
            ),
            const _PageLinkCard(
              icon: Icons.delete_outline_rounded,
              title: 'Eliminación de cuenta y datos',
              description: 'Revisa cómo solicitar la eliminación.',
              route: '/eliminacion-de-datos',
            ),
            const _PageLinkCard(
              icon: Icons.mail_outline_rounded,
              title: 'Soporte',
              description: 'Escríbenos si necesitas ayuda.',
              route: '/soporte',
            ),
          ],
        ),
      ),
    );
  }
}

class _PageLinkCard extends StatelessWidget {
  const _PageLinkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE6ECE9)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9F7F0),
          foregroundColor: _primary,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }
}

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    required this.document,
    required this.activeRoute,
    super.key,
  });

  final LegalDocument document;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return SiteFrame(
      activeRoute: activeRoute,
      child: _PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow(label: 'INFORMACIÓN LEGAL'),
            const SizedBox(height: 10),
            Text(document.title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Última actualización: 12 de octubre de 2026'),
            const SizedBox(height: 24),
            ...document.intro.map(_buildLegalBlock),
            const SizedBox(height: 12),
            ...document.sections.map(
              (section) => _LegalSectionCard(section: section),
            ),
            if (activeRoute == '/privacidad') ...[
              const SizedBox(height: 12),
              const _InlineRouteCard(
                title: '¿Quieres eliminar tu cuenta?',
                description:
                    'Consulta la página de eliminación de cuenta y datos.',
                route: '/eliminacion-de-datos',
              ),
            ],
            if (activeRoute == '/terminos') ...[
              const SizedBox(height: 12),
              const _InlineRouteCard(
                title: 'Política de privacidad',
                description: 'Lee cómo tratamos los datos personales.',
                route: '/privacidad',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildLegalBlock(LegalBlock block) {
  if (block is LegalParagraph) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(block.text, style: const TextStyle(fontSize: 15.5)),
    );
  }
  if (block is LegalBullets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: block.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 12),
                  child: Icon(Icons.circle, size: 7, color: _primary),
                ),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 15.5))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  if (block is LegalNote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC6E9D6)),
      ),
      child: Text(
        block.text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
  return const SizedBox.shrink();
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...section.blocks.map(_buildLegalBlock),
        ],
      ),
    );
  }
}

class DataDeletionPage extends StatelessWidget {
  const DataDeletionPage({super.key});

  Future<void> _requestDeletion(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: const {
        'subject': 'Solicitud de eliminación de cuenta NutriLife',
        'body': 'Hola, quiero solicitar la eliminación de mi cuenta NutriLife. '
            'El correo asociado a mi cuenta es: ',
      },
    );
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe a $_contactEmail desde el correo de tu cuenta.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SiteFrame(
      activeRoute: '/eliminacion-de-datos',
      child: _PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow(label: 'CONTROL DE TUS DATOS'),
            const SizedBox(height: 10),
            Text(
              'Eliminación de cuenta y datos',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Puedes solicitar la eliminación de tu cuenta de NutriLife y de '
              'los datos personales asociados. Hay dos formas de hacerlo:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 22),
            const _InfoPanel(
              icon: Icons.phone_android_rounded,
              title: 'Desde la aplicación',
              body: 'Abre Perfil → Eliminar cuenta y sigue los pasos de '
                  'confirmación que aparecen en la app.',
            ),
            const SizedBox(height: 12),
            _InfoPanel(
              icon: Icons.email_outlined,
              title: 'Desde esta página',
              body: 'Envía la solicitud desde el correo electrónico asociado '
                  'a tu cuenta. Indica que deseas eliminar tu cuenta de '
                  'NutriLife. No incluyas tu contraseña.',
              action: FilledButton.icon(
                onPressed: () => _requestDeletion(context),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Solicitar eliminación por correo'),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6ECE9)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos asociados',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'La Política de Privacidad describe qué información se '
                    'elimina al cerrar la cuenta y qué registro anónimo se '
                    'conserva. Revísala antes de enviar la solicitud.',
                  ),
                  SizedBox(height: 12),
                  _InlineRouteCard(
                    title: 'Leer Política de Privacidad',
                    description: 'Consulta el detalle de conservación y eliminación.',
                    route: '/privacidad',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para consultas sobre el proceso, escríbenos a '
              '$_contactEmail.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SiteFrame(
      activeRoute: '/soporte',
      child: _PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow(label: 'ESTAMOS PARA AYUDAR'),
            const SizedBox(height: 10),
            Text('Soporte', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            const Text(
              'Si tienes preguntas sobre NutriLife, tu cuenta o tus datos, '
              'puedes escribirnos por correo electrónico.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 22),
            _InfoPanel(
              icon: Icons.mail_outline_rounded,
              title: 'Correo de contacto',
              body: _contactEmail,
              action: FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri(scheme: 'mailto', path: _contactEmail),
                ),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Escribir a soporte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SiteFrame(
      activeRoute: '',
      child: _PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Página no encontrada',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE9F7F0),
                foregroundColor: _primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(body),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

class _InlineRouteCard extends StatelessWidget {
  const _InlineRouteCard({
    required this.title,
    required this.description,
    required this.route,
  });

  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: _primary),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _primary,
        letterSpacing: 1.2,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SiteFooter extends StatelessWidget {
  const _SiteFooter();

  @override
  Widget build(BuildContext context) {
    const links = <String, String>{
      'Privacidad': '/privacidad',
      'Términos y Condiciones': '/terminos',
      'Eliminar datos': '/eliminacion-de-datos',
      'Soporte': '/soporte',
    };
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E8E3))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          const Text('© 2026 NutriLife', style: TextStyle(fontSize: 13)),
          Wrap(
            spacing: 4,
            children: links.entries
                .map(
                  (entry) => TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(entry.value),
                    child: Text(entry.key),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
