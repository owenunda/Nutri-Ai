//
// Constantes portadas de Bloub (https://github.com/jeremy-prt/bloub)
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.

/// PROFILE_SAMPLES en Bloub (profiles.ts).
const int kProfileSamples = 64;

/// La bola en reposo. En Bloub el cuerpo de idle/wink/wide/thinking/sleep sale
/// de `circle(r)`, que rellena los 64 radios con el mismo valor: no es un
/// perfil medido, es un circulo. Los unicos perfiles radiales reales de Bloub
/// (egg, hexagon, triangle) quedan fuera del alcance de esta feature.
final List<double> kSphereProfile = List<double>.unmodifiable(
  List<double>.filled(kProfileSamples, 1.0),
);
