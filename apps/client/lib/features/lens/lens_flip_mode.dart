/// Retournement à appliquer à l'image affichée : une lentille convexe simple
/// inverse généralement l'image sur ses deux axes (180°), mais le montage
/// optique final (nombre de lentilles, miroir éventuel) n'est pas encore
/// spécifié — voir docs/decisions-a-valider.md. Les quatre options couvrent
/// les montages courants en attendant cette décision.
enum LensFlipMode {
  none('Aucun'),
  horizontal('Horizontal'),
  vertical('Vertical'),
  both('180° (horizontal + vertical)');

  const LensFlipMode(this.label);

  final String label;

  double get scaleX => this == horizontal || this == both ? -1 : 1;

  double get scaleY => this == vertical || this == both ? -1 : 1;
}
