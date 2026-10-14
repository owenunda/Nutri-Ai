// Términos y Política de Privacidad de NutriLife, redactados según la ley
// colombiana (Ley 1581 de 2012, Decreto 1074 de 2015, Ley 1480 de 2011 y
// Ley 527 de 1999). Si cambian, actualizar también kLegalUpdatedAt.

// Datos del responsable: aparecen en ambos documentos.
const kLegalOwnerName = 'Oween Unda';
const kLegalOwnerCity = 'Medellín';
const kLegalContactEmail = 'oweenunda.dev@gmail.com';
const kLegalUpdatedAt = '12 de octubre de 2026';

sealed class LegalBlock {
  const LegalBlock();
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);
  final String text;
}

class LegalBullets extends LegalBlock {
  const LegalBullets(this.items);
  final List<String> items;
}

// Recuadro destacado (avisos de salud, datos del responsable).
class LegalNote extends LegalBlock {
  const LegalNote(this.text);
  final String text;
}

class LegalSection {
  const LegalSection(this.title, this.blocks);
  final String title;
  final List<LegalBlock> blocks;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final List<LegalBlock> intro;
  final List<LegalSection> sections;
}

class LegalDocuments {
  const LegalDocuments._();

  static const terms = LegalDocument(
    title: 'Términos y Condiciones',
    intro: [
      LegalParagraph(
        'Estos Términos y Condiciones regulan el uso de la '
        'aplicación NutriLife, ofrecida por nuestro equipo de trabajo, con '
        'domicilio en $kLegalOwnerCity, Colombia. Al crear una '
        'cuenta y marcar la casilla de '
        'aceptación celebras un acuerdo con nosotros por medios electrónicos, '
        'válido conforme a la Ley 527 de 1999. Si no estás de acuerdo con '
        'estos Términos, no uses la App.',
      ),
      LegalNote(
        'NutriLife es una herramienta de información y seguimiento nutricional '
        'general. No es un servicio médico y no reemplaza el diagnóstico, el '
        'tratamiento ni el consejo de un médico, nutricionista u otro '
        'profesional de la salud.',
      ),
    ],
    sections: [
      LegalSection('1. El servicio', [
        LegalParagraph(
          'NutriLife te permite registrar tus comidas y tu peso, consultar tu '
          'consumo de calorías frente a una meta diaria estimada, administrar '
          'una nevera virtual y conversar con un asistente de inteligencia '
          'artificial que sugiere recetas e ideas de alimentación.',
        ),
        LegalParagraph(
          'Actualmente el servicio es gratuito y con un plan basico o de pago. Podemos agregar, modificar o '
          'retirar funciones para mejorar la App.',
        ),
      ]),
      LegalSection('2. Requisitos para usar la App', [
        LegalBullets([
          'Debes ser mayor de 18 años. Si tienes entre 16 y 17 años, solo '
              'puedes usar la App con la autorización de tu padre, madre o '
              'representante legal, quien acepta estos Términos en tu nombre.',
          'Debes entregar información veraz y mantenerla actualizada.',
          'Eres responsable de la confidencialidad de tu contraseña y de la '
              'actividad de tu cuenta. Avísanos de inmediato si sospechas un '
              'uso no autorizado.',
        ]),
      ]),
      LegalSection('3. Información de salud y contenido generado por IA', [
        LegalBullets([
          'Las metas calóricas, los valores nutricionales y las recetas son '
              'estimaciones y pueden contener errores o no ajustarse a tu caso.',
          'Las respuestas del asistente se generan automáticamente con '
              'inteligencia artificial. Pueden ser inexactas, incompletas o '
              'inapropiadas para ti. Revísalas con criterio antes de seguirlas.',
          'Verifica siempre los ingredientes si tienes alergias, intolerancias '
              'o restricciones alimentarias. La App no garantiza que una receta '
              'esté libre de alérgenos.',
          'Consulta a un profesional de la salud antes de cambiar tu '
              'alimentación, en especial si estás embarazada o lactando, tienes '
              'una enfermedad (como diabetes, enfermedad renal o trastornos de '
              'la conducta alimentaria), tomas medicamentos o buscas cambios de '
              'peso rápidos.',
          'Ante una emergencia médica, comunícate de inmediato con la línea de '
              'emergencias 123.',
        ]),
      ]),
      LegalSection('4. Uso permitido', [
        LegalParagraph(
          'Te comprometes a usar la App de forma lícita y personal. No está '
          'permitido:',
        ),
        LegalBullets([
          'Intentar acceder a cuentas, datos o sistemas que no te pertenecen, '
              'o vulnerar la seguridad de la App.',
          'Usar la App o el asistente para generar contenido ilegal, ofensivo, '
              'que promueva conductas alimentarias peligrosas o que infrinja '
              'derechos de terceros.',
          'Automatizar solicitudes, saturar el servicio o eludir los límites '
              'de uso.',
          'Copiar, modificar, descompilar o revender la App o sus contenidos, '
              'salvo en lo que permita la ley.',
        ]),
        LegalParagraph(
          'Si incumples estos Términos podremos suspender o cerrar tu cuenta, '
          'avisándote previamente cuando sea posible.',
        ),
      ]),
      LegalSection('5. Tus datos', [
        LegalParagraph(
          'El tratamiento de tus datos personales se rige por nuestra Política '
          'de Privacidad y Tratamiento de Datos Personales, que forma parte de '
          'estos Términos.',
        ),
      ]),
      LegalSection('6. Propiedad intelectual', [
        LegalParagraph(
          'La App, su diseño, marca, logotipos, textos y código son de nuestra '
          'propiedad o de sus respectivos licenciantes, y están protegidos por '
          'las normas de derechos de autor y propiedad industrial. Te otorgamos '
          'una licencia personal, gratuita, no exclusiva e intransferible para '
          'usar la App conforme a estos Términos. Algunos componentes de '
          'software de terceros se usan bajo sus propias licencias de código '
          'abierto.',
        ),
        LegalParagraph(
          'Los datos que registras siguen siendo tuyos. Nos autorizas a '
          'almacenarlos y procesarlos solo para prestarte el servicio.',
        ),
      ]),
      LegalSection('7. Pagos y suscripciones futuras', [
        LegalParagraph(
          'Si haras la compra de un plan ya sea mensual o anual, antes de cobrarte te informaremos el precio total, la '
          'periodicidad, las condiciones de renovación y cancelación, y tu '
          'derecho de retracto conforme al artículo 47 de la Ley 1480 de 2011 '
          '(Estatuto del Consumidor). Los pagos hechos a través de Google Play '
          'también se rigen por las condiciones de Google Play.',
        ),
      ]),
      LegalSection('8. Disponibilidad del servicio', [
        LegalParagraph(
          'Hacemos esfuerzos razonables para que la App funcione de forma '
          'continua, pero puede haber interrupciones por mantenimiento, fallas '
          'técnicas o causas ajenas a nosotros, como fallas de los proveedores '
          'de internet o de inteligencia artificial.',
        ),
      ]),
      LegalSection('9. Responsabilidad', [
        LegalParagraph(
          'En la medida permitida por la ley colombiana, no seremos '
          'responsables por daños derivados de decisiones de salud o '
          'alimentación que tomes basándote únicamente en la información de la '
          'App sin consultar a un profesional, ni por interrupciones causadas '
          'por fuerza mayor, caso fortuito o hechos de terceros. Nada en estos '
          'Términos limita los derechos que te reconoce la Ley 1480 de 2011 ni '
          'excluye nuestra responsabilidad en los casos en que la ley no lo '
          'permite.',
        ),
      ]),
      LegalSection('10. Terminación', [
        LegalParagraph(
          'Puedes dejar de usar la App y eliminar tu cuenta cuando quieras, '
          'desde Perfil → Eliminar cuenta. Al eliminarla se borran tus datos '
          'como lo describe la Política de Privacidad.',
        ),
      ]),
      LegalSection('11. Cambios a estos Términos', [
        LegalParagraph(
          'Podemos actualizar estos Términos. Si los cambios son sustanciales, '
          'te avisaremos en la App o por correo con antelación razonable. Si '
          'sigues usando la App después de su entrada en vigencia, se entenderá '
          'que los aceptas; si no estás de acuerdo, puedes eliminar tu cuenta.',
        ),
      ]),
      LegalSection('12. Ley aplicable y solución de controversias', [
        LegalParagraph(
          'Estos Términos se rigen por las leyes de la República de Colombia. '
          'Antes de acudir a otras instancias, te invitamos a escribirnos para '
          'buscar una solución directa. Como consumidor, puedes acudir a la '
          'Superintendencia de Industria y Comercio (SIC) o a los jueces '
          'competentes de Colombia.',
        ),
      ]),
      LegalSection('13. Contacto', [
        LegalParagraph(
          'Para preguntas, quejas o reclamos sobre estos Términos, escríbenos a '
          '$kLegalContactEmail.',
        ),
      ]),
    ],
  );

  static const privacy = LegalDocument(
    title: 'Política de Privacidad',
    intro: [
      LegalParagraph(
        'Esta política explica qué datos personales recoge la aplicación '
        'NutriLife, para qué los usamos, con quién los compartimos '
        'y cómo puedes ejercer tus derechos. Se expide en cumplimiento de la '
        'Ley Estatutaria 1581 de 2012, el Decreto 1074 de 2015 (que compila el '
        'Decreto 1377 de 2013) y demás normas colombianas sobre protección de '
        'datos personales (Habeas Data).',
      ),
    ],
    sections: [
      LegalSection('1. Responsable del tratamiento', [
        LegalNote(
          'Responsable: Equipo desarrollador/Aprendices\n'
          'Domicilio: $kLegalOwnerCity, Colombia\n'
          'Correo para peticiones, consultas y reclamos: $kLegalContactEmail',
        ),
      ]),
      LegalSection('2. Datos que recogemos', [
        LegalBullets([
          'Cuenta: nombre, correo electrónico y contraseña (guardada cifrada '
              'con un algoritmo de hash, nunca en texto plano).',
          'Perfil físico y objetivo: edad, altura, historial de peso y '
              'objetivo nutricional (bajar, mantener o subir de peso).',
          'Alimentación: comidas registradas, alimentos personalizados, '
              'alimentos de tu nevera virtual y recetas guardadas.',
          'Conversaciones: mensajes que escribes al asistente de IA y sus '
              'respuestas.',
          'Datos técnicos: dirección IP, fecha y hora de las solicitudes, '
              'acciones realizadas en la App y errores, para seguridad y '
              'diagnóstico.',
        ]),
        LegalParagraph(
          'El sexo que eliges en tu perfil se guarda solo en tu dispositivo y '
          'no se envía a nuestros servidores.',
        ),
        LegalParagraph(
          'NutriLife no accede a tu ubicación, contactos, cámara, micrófono ni '
          'fotos, no muestra publicidad y no usa identificadores publicitarios.',
        ),
      ]),
      LegalSection('3. Datos sensibles', [
        LegalParagraph(
          'Tu peso, altura, objetivo y hábitos alimentarios pueden considerarse '
          'datos relativos a la salud y, por tanto, datos sensibles según el '
          'artículo 5 de la Ley 1581 de 2012. Te informamos que:',
        ),
        LegalBullets([
          'No estás obligado a suministrarlos. Sin ellos, la App no puede '
              'calcular tu meta calórica ni personalizar sus recomendaciones.',
          'Solo los tratamos con tu autorización previa, expresa e informada, '
              'que otorgas al aceptar esta política durante el registro.',
          'Ninguna función de la App está condicionada a que entregues más '
              'datos sensibles de los necesarios para esa función.',
        ]),
      ]),
      LegalSection('4. Finalidades del tratamiento', [
        LegalBullets([
          'Crear y administrar tu cuenta y permitirte iniciar sesión.',
          'Calcular tu meta diaria de calorías y mostrarte tu consumo y '
              'progreso.',
          'Generar respuestas, recetas y sugerencias personalizadas con el '
              'asistente de inteligencia artificial.',
          'Guardar tu historial de comidas, peso, recetas y conversaciones para '
              'que puedas consultarlo.',
          'Proteger la seguridad de la App, prevenir abusos y diagnosticar '
              'fallas.',
          'Atender tus peticiones, consultas y reclamos.',
          'Elaborar estadísticas internas y anónimas para mejorar el servicio.',
          'Enviarte comunicaciones sobre el funcionamiento del servicio (no '
              'publicitarias).',
        ]),
        LegalParagraph(
          'No vendemos ni alquilamos tus datos personales, ni los usamos para '
          'publicidad de terceros.',
        ),
      ]),
      LegalSection('5. Con quién compartimos tus datos', [
        LegalParagraph(
          'Solo compartimos datos con proveedores que nos ayudan a prestar el '
          'servicio y que actúan como encargados del tratamiento, siguiendo '
          'nuestras instrucciones:',
        ),
        LegalBullets([
          'Proveedor de inteligencia artificial (OpenAI, Estados Unidos): '
              'recibe el texto de tus mensajes al asistente, tu nombre y los '
              'alimentos que adjuntes, únicamente para generar la respuesta.',
          'Proveedores de infraestructura en la nube: alojan nuestros '
              'servidores y bases de datos.',
        ]),
        LegalParagraph(
          'Algunos de estos proveedores están fuera de Colombia, por lo que '
          'puede haber transmisión internacional de datos. Al aceptar esta '
          'política autorizas expresamente esa transmisión, en los términos del '
          'artículo 26 de la Ley 1581 de 2012 y del Decreto 1074 de 2015. '
          'Exigimos a estos proveedores niveles adecuados de protección.',
        ),
        LegalParagraph(
          'Si el asistente te sugiere un video de YouTube y lo abres, YouTube '
          '(Google) tratará tus datos según sus propias políticas.',
        ),
        LegalParagraph(
          'También podremos entregar datos cuando lo ordene una autoridad '
          'competente, conforme a la ley.',
        ),
      ]),
      LegalSection('6. Tus derechos como titular', [
        LegalParagraph(
          'De acuerdo con el artículo 8 de la Ley 1581 de 2012, tienes derecho '
          'a:',
        ),
        LegalBullets([
          'Conocer, actualizar y rectificar tus datos personales.',
          'Solicitar prueba de la autorización que nos otorgaste.',
          'Ser informado sobre el uso que les hemos dado a tus datos.',
          'Presentar quejas ante la Superintendencia de Industria y Comercio '
              '(SIC) por infracciones a la ley, una vez agotado el trámite de '
              'consulta o reclamo ante nosotros.',
          'Revocar la autorización y/o solicitar la supresión de tus datos.',
          'Acceder gratuitamente a tus datos personales.',
        ]),
        LegalParagraph(
          'Puedes actualizar tu perfil directamente en la App, en Perfil → '
          'Configuración.',
        ),
      ]),
      LegalSection('7. Cómo eliminar tu cuenta y tus datos', [
        LegalParagraph('Puedes eliminar tu cuenta en cualquier momento:'),
        LegalBullets([
          'Desde la App: Perfil → Eliminar cuenta.',
          'Por correo: escribiendo a $kLegalContactEmail desde el correo '
              'asociado a tu cuenta.',
        ]),
        LegalParagraph(
          'Al eliminar tu cuenta borramos de forma permanente tu perfil, '
          'historial de peso, comidas, nevera, recetas, alimentos '
          'personalizados, conversaciones y registros de actividad asociados. '
          'Solo conservamos un registro anónimo de que ocurrió una eliminación, '
          'que no permite identificarte. Los datos guardados solo en tu '
          'dispositivo se borran al desinstalar la App.',
        ),
      ]),
      LegalSection('8. Consultas y reclamos', [
        LegalParagraph(
          'Para ejercer tus derechos, escribe a $kLegalContactEmail indicando '
          'tu nombre, el correo de tu cuenta, la descripción de tu solicitud y, '
          'si aplica, los documentos que quieras hacer valer.',
        ),
        LegalParagraph(
          'Consultas: se atenderán en un máximo de diez (10) días hábiles desde '
          'su recibo. Si no fuera posible, te informaremos los motivos y la '
          'fecha de respuesta, que no superará cinco (5) días hábiles '
          'adicionales (artículo 14, Ley 1581 de 2012).',
        ),
        LegalParagraph(
          'Reclamos: si consideras que tus datos deben corregirse, actualizarse '
          'o suprimirse, o adviertes un incumplimiento, puedes presentar un '
          'reclamo. Si está incompleto, te pediremos completarlo dentro de los '
          'cinco (5) días siguientes; si pasan dos (2) meses sin que lo '
          'completes, se entenderá que desististe. Responderemos en un máximo '
          'de quince (15) días hábiles desde el día siguiente a su recibo, '
          'prorrogable hasta por ocho (8) días hábiles más, previo aviso '
          '(artículo 15, Ley 1581 de 2012).',
        ),
      ]),
      LegalSection('9. Seguridad', [
        LegalParagraph(
          'Aplicamos medidas técnicas y administrativas razonables para '
          'proteger tus datos: conexiones cifradas (HTTPS), contraseñas '
          'almacenadas con hash, acceso restringido a la base de datos y '
          'autenticación por token en cada solicitud. Ningún sistema es '
          'completamente infalible; si detectamos un incidente que afecte tus '
          'datos, te lo informaremos y lo reportaremos a la SIC cuando la ley '
          'lo exija.',
        ),
      ]),
      LegalSection('10. Conservación de los datos', [
        LegalParagraph(
          'Conservamos tus datos mientras tu cuenta esté activa y sea necesario '
          'para las finalidades descritas. Cuando eliminas tu cuenta, los '
          'suprimimos como se explica en la sección 7, salvo que una obligación '
          'legal exija conservar alguno por más tiempo.',
        ),
      ]),
      LegalSection('11. Menores de edad', [
        LegalParagraph(
          'NutriLife está dirigida a personas mayores de 18 años. Los '
          'adolescentes de 16 y 17 años solo pueden usarla con la autorización '
          'de su padre, madre o representante legal, y siempre respetando su '
          'interés superior, conforme al artículo 7 de la Ley 1581 de 2012. No '
          'está permitido el registro de menores de 16 años. Si eres '
          'representante legal y crees que un menor nos entregó datos sin '
          'autorización, escríbenos para eliminarlos.',
        ),
      ]),
      LegalSection('12. Aviso sobre salud', [
        LegalParagraph(
          'La información que ofrece NutriLife es general y no reemplaza el '
          'consejo de un médico o nutricionista. Consulta los Términos y '
          'Condiciones para más detalle.',
        ),
      ]),
      LegalSection('13. Cambios y vigencia', [
        LegalParagraph(
          'Si hacemos cambios sustanciales a esta política, te avisaremos en la '
          'App o por correo antes de que entren en vigencia y, cuando la ley lo '
          'exija, te pediremos una nueva autorización. Esta política rige desde '
          'el $kLegalUpdatedAt. Las bases de datos de NutriLife estarán '
          'vigentes mientras se preste el servicio.',
        ),
      ]),
    ],
  );
}
