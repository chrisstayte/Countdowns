import 'package:countdowns/models/palette.dart' show autoTextColor;
import 'package:material_ui/material_ui.dart';

/// Patterns, textures and illustrations: backgrounds drawn in code (see
/// lib/widgets/art_painter.dart), so they are sharp at any size, cost no
/// download and every colourway is a line here.
///
/// Stability rules, so saved countdowns never change:
/// - A countdown stores the art's id: never rename or reuse an id.
/// - Keep an entry's motif and colours as they are; add a new entry for a
///   new look. Renaming it or moving it between families is fine.
/// Every entry must pass test/art_catalog_test.dart: its automatic text
/// colour reads at WCAG AA (4.5:1) on its ground and on every colour the
/// art draws, so text stays readable wherever it lands.
enum ArtKind {
  pattern('Patterns'),
  texture('Textures'),
  illustration('Illustrations');

  const ArtKind(this.label);
  final String label;
}

/// One drawn background.
sealed class Art {
  const Art(this.id, this.name, this.ground);

  final String id;
  final String name;

  /// The base colour under everything, also saved as the countdown's
  /// colour so older views fall back to something close.
  final Color ground;

  ArtKind get kind;

  /// Every colour the art paints with, as it lands on the ground.
  List<Color> get paints;

  /// Ink or white by contrast with the ground (the test checks the rest).
  Color get textColor => autoTextColor(ground);
}

/// How translucent the soft fill inside a drawn outline is, as on the
/// event icons.
const artSoftFill = 0.3;

/// [c] as a soft fill lands on [under].
Color softOn(Color c, Color under) =>
    Color.alphaBlend(c.withValues(alpha: artSoftFill), under);

// MARK: Patterns

enum Motif {
  polka,
  pinDots,
  confetti,
  spots,
  stripes,
  candy,
  pinstripe,
  breton,
  gingham,
  checkerboard,
  windowpane,
  plaid,
  waves,
  scallops,
  zigzag,
  squiggle,
  hearts,
  stars,
  triangles,
  crosses,
  diamonds,
  rainbows,
  grid,
  dotGrid,
  lined,
}

class PatternArt extends Art {
  const PatternArt(super.id, super.name, this.motif, super.ground, this.inks);

  final Motif motif;

  /// Motif colours, used in turn.
  final List<Color> inks;

  @override
  ArtKind get kind => ArtKind.pattern;

  @override
  List<Color> get paints => [
    ground,
    ...inks,
    // Gingham and plaid cross translucent bands.
    if (motif == Motif.gingham || motif == Motif.plaid)
      for (final c in inks) ...[
        softOn(c, ground),
        softOn(c, softOn(c, ground)),
      ],
    // Hand-drawn shapes have a soft fill inside the outline.
    if (const {
      Motif.hearts,
      Motif.stars,
      Motif.triangles,
      Motif.diamonds,
      Motif.spots,
    }.contains(motif))
      for (final c in inks) softOn(c, ground),
  ];
}

// MARK: Textures

enum Weave {
  paper,
  kraft,
  linen,
  canvas,
  denim,
  corduroy,
  felt,
  grain,
  terrazzo,
  marble,
  wood,
  watercolour,
  stucco,
  sand,
  cork,
}

class TextureArt extends Art {
  const TextureArt(super.id, super.name, this.weave, super.ground, this.tones);

  final Weave weave;

  /// Close tones of the ground (chips for terrazzo), drawn opaque.
  final List<Color> tones;

  @override
  ArtKind get kind => ArtKind.texture;

  @override
  List<Color> get paints => [ground, ...tones];
}

// MARK: Illustrations

/// The scenery along the bottom.
enum Land {
  none,
  hills,
  waves,
  dunes,
  snow,
  mountains,
  skyline,
  forest,
  meadow,
  beach,
  camp,
}

/// The one big thing in the sky.
enum SkyFeature { none, sun, moon, rainbow }

/// Small things scattered over the sky.
enum Sprite {
  star,
  sparkle,
  snowflake,
  heart,
  balloon,
  confetti,
  leaf,
  flower,
  blossom,
  cloud,
  bird,
  raindrop,
  bubble,
  lantern,
  firework,
  pumpkin,
  bat,
  egg,
  gift,
  clover,
  butterfly,
  gradCap,
  plane,
  hotAirBalloon,
  sailboat,
  diya,
  rings,
  fish,
}

class IllustrationArt extends Art {
  const IllustrationArt(
    super.id,
    super.name,
    super.ground, {
    this.land = Land.none,
    this.landColors = const [],
    this.hero = SkyFeature.none,
    this.heroColors = const [],
    this.sprites = const [],
    this.spriteColors = const [],
    this.density = 1,
  });

  final Land land;

  /// Back layer, front layer, then details (windows, snowcaps, props).
  final List<Color> landColors;
  final SkyFeature hero;
  final List<Color> heroColors;
  final List<Sprite> sprites;
  final List<Color> spriteColors;

  /// More or fewer sprites than usual.
  final double density;

  @override
  ArtKind get kind => ArtKind.illustration;

  @override
  List<Color> get paints => [
    ground,
    ...landColors,
    for (final c in landColors.skip(2)) softOn(c, ground),
    ...heroColors,
    for (final c in heroColors) softOn(c, ground),
    ...spriteColors,
    for (final c in spriteColors) softOn(c, ground),
  ];
}

class ArtCollection {
  const ArtCollection(this.id, this.name, this.items);
  final String id;
  final String name;
  final List<Art> items;
}

// MARK: Colourways

// Light grounds and their motif ink (text is ink).
const _butter = Color(0xFFFFF0C2), _butterInk = Color(0xFFF2C14E);
const _blush = Color(0xFFFFE1E6), _blushInk = Color(0xFFF49AAE);
const _mint = Color(0xFFDDF5EA), _mintInk = Color(0xFF8FD6B8);
const _sky = Color(0xFFDCEBFF), _skyInk = Color(0xFF8DB8F2);
const _lilac = Color(0xFFEDE3FF), _lilacInk = Color(0xFFBFA5F0);
const _peach = Color(0xFFFFE4D3), _peachInk = Color(0xFFF7A983);
const _sage = Color(0xFFE5EDDC), _sageInk = Color(0xFFA9C49A);
const _sand = Color(0xFFF3E8D2), _sandInk = Color(0xFFD8BE8E);

// Dark grounds and their motif ink (text is white).
const _navy = Color(0xFF1F2A52), _navyInk = Color(0xFF34488A);
const _forest = Color(0xFF1E4D3B), _forestInk = Color(0xFF2E6E55);
const _plum = Color(0xFF4A2357), _plumInk = Color(0xFF6A3A7E);
const _berry = Color(0xFF8A1E45), _berryInk = Color(0xFFA8335E);
const _cocoa = Color(0xFF4A3428), _cocoaInk = Color(0xFF6B4C3A);
const _cobalt = Color(0xFF2C4FB8), _cobaltInk = Color(0xFF4166CF);
const _rust = Color(0xFF9C3D2E), _rustInk = Color(0xFFB24E3A);

// Brights that read with ink.
const _red = Color(0xFFF28C8C);
const _gold = Color(0xFFF2C14E);
const _green = Color(0xFF8FD6B8);
const _blue = Color(0xFF8DB8F2);
const _violet = Color(0xFFC4A8F0);
const _orange = Color(0xFFF7A06B);

// Deeps that read with white.
const _deepRed = Color(0xFFA8335E);
const _deepGold = Color(0xFF8C6A1E);
const _deepTeal = Color(0xFF1F6E73);
const _deepBlue = Color(0xFF3E5FB8);
const _deepViolet = Color(0xFF6A4A9E);

const List<ArtCollection> patternCollections = [
  ArtCollection('dots', 'Dots', [
    PatternArt('polka-butter', 'Butter polka', Motif.polka, _butter, [
      _butterInk,
    ]),
    PatternArt('polka-blush', 'Blush polka', Motif.polka, _blush, [_blushInk]),
    PatternArt('polka-navy', 'Navy polka', Motif.polka, _navy, [_navyInk]),
    PatternArt('polka-mint', 'Mint polka', Motif.polka, _mint, [_mintInk]),
    PatternArt('pin-dots-sky', 'Sky pin dots', Motif.pinDots, _sky, [_skyInk]),
    PatternArt('pin-dots-cocoa', 'Cocoa pin dots', Motif.pinDots, _cocoa, [
      _cocoaInk,
    ]),
    PatternArt('confetti', 'Confetti', Motif.confetti, Color(0xFFFFF8EC), [
      _red,
      _gold,
      _green,
      _blue,
      _violet,
    ]),
    PatternArt('confetti-night', 'Night confetti', Motif.confetti, _navy, [
      _deepRed,
      _deepGold,
      _deepTeal,
      _deepBlue,
      _deepViolet,
    ]),
    PatternArt('spots-peach', 'Peach spots', Motif.spots, _peach, [_peachInk]),
    PatternArt('spots-forest', 'Forest spots', Motif.spots, _forest, [
      _forestInk,
    ]),
  ]),
  ArtCollection('stripes', 'Stripes', [
    PatternArt('stripes-mint', 'Mint stripes', Motif.stripes, _mint, [
      _mintInk,
    ]),
    PatternArt('stripes-blush', 'Blush stripes', Motif.stripes, _blush, [
      _blushInk,
    ]),
    PatternArt('stripes-cobalt', 'Cobalt stripes', Motif.stripes, _cobalt, [
      _cobaltInk,
    ]),
    PatternArt('candy-blush', 'Candy stripe', Motif.candy, _blush, [_blushInk]),
    PatternArt('candy-berry', 'Berry candy', Motif.candy, _berry, [_berryInk]),
    PatternArt('pinstripe-navy', 'Navy pinstripe', Motif.pinstripe, _navy, [
      _navyInk,
    ]),
    PatternArt('pinstripe-sand', 'Sand pinstripe', Motif.pinstripe, _sand, [
      _sandInk,
    ]),
    PatternArt('breton-sky', 'Breton', Motif.breton, _sky, [_skyInk]),
    PatternArt('breton-rust', 'Rust breton', Motif.breton, _rust, [_rustInk]),
  ]),
  ArtCollection('checks', 'Checks', [
    PatternArt('gingham-sky', 'Sky gingham', Motif.gingham, _sky, [_skyInk]),
    PatternArt('gingham-blush', 'Blush gingham', Motif.gingham, _blush, [
      _blushInk,
    ]),
    PatternArt('gingham-sage', 'Sage gingham', Motif.gingham, _sage, [
      _sageInk,
    ]),
    PatternArt('gingham-berry', 'Berry gingham', Motif.gingham, _berry, [
      _berryInk,
    ]),
    PatternArt('checks-butter', 'Butter checks', Motif.checkerboard, _butter, [
      _butterInk,
    ]),
    PatternArt('checks-plum', 'Plum checks', Motif.checkerboard, _plum, [
      _plumInk,
    ]),
    PatternArt('windowpane-sand', 'Windowpane', Motif.windowpane, _sand, [
      _sandInk,
    ]),
    PatternArt(
      'windowpane-forest',
      'Forest windowpane',
      Motif.windowpane,
      _forest,
      [_forestInk],
    ),
    PatternArt('plaid-rust', 'Rust plaid', Motif.plaid, _rust, [
      _rustInk,
      Color(0xFF7E2E22),
    ]),
    PatternArt('plaid-sky', 'Picnic plaid', Motif.plaid, _sky, [
      _skyInk,
      _blushInk,
    ]),
  ]),
  ArtCollection('waves', 'Waves', [
    PatternArt('waves-sky', 'Sky waves', Motif.waves, _sky, [_skyInk]),
    PatternArt('waves-navy', 'Night waves', Motif.waves, _navy, [_navyInk]),
    PatternArt('scallops-peach', 'Peach scallops', Motif.scallops, _peach, [
      _peachInk,
    ]),
    PatternArt('scallops-mint', 'Mint scallops', Motif.scallops, _mint, [
      _mintInk,
    ]),
    PatternArt('zigzag-lilac', 'Lilac zigzag', Motif.zigzag, _lilac, [
      _lilacInk,
    ]),
    PatternArt('zigzag-cobalt', 'Cobalt zigzag', Motif.zigzag, _cobalt, [
      _cobaltInk,
    ]),
    PatternArt('squiggle-butter', 'Squiggles', Motif.squiggle, _butter, [
      _butterInk,
      _peachInk,
    ]),
    PatternArt('squiggle-plum', 'Plum squiggles', Motif.squiggle, _plum, [
      _plumInk,
    ]),
  ]),
  ArtCollection('shapes', 'Shapes', [
    PatternArt('hearts-blush', 'Hearts', Motif.hearts, _blush, [_blushInk]),
    PatternArt('hearts-berry', 'Berry hearts', Motif.hearts, _berry, [
      _berryInk,
    ]),
    PatternArt('stars-navy', 'Night stars', Motif.stars, _navy, [_navyInk]),
    PatternArt('stars-butter', 'Gold stars', Motif.stars, _butter, [
      _butterInk,
    ]),
    PatternArt('triangles-sage', 'Sage triangles', Motif.triangles, _sage, [
      _sageInk,
    ]),
    PatternArt('triangles-rust', 'Rust triangles', Motif.triangles, _rust, [
      _rustInk,
    ]),
    PatternArt('crosses-lilac', 'Lilac crosses', Motif.crosses, _lilac, [
      _lilacInk,
    ]),
    PatternArt('crosses-mint', 'Mint crosses', Motif.crosses, _mint, [
      _mintInk,
    ]),
    PatternArt('diamonds-sand', 'Diamonds', Motif.diamonds, _sand, [_sandInk]),
    PatternArt('diamonds-plum', 'Plum diamonds', Motif.diamonds, _plum, [
      _plumInk,
    ]),
    PatternArt('rainbows-peach', 'Rainbows', Motif.rainbows, _peach, [
      _peachInk,
      _butterInk,
      _skyInk,
    ]),
    PatternArt('rainbows-sky', 'Sky rainbows', Motif.rainbows, _sky, [
      _blushInk,
      _lilacInk,
      _skyInk,
    ]),
  ]),
  ArtCollection('stationery', 'Stationery', [
    PatternArt('grid-sky', 'Graph paper', Motif.grid, Color(0xFFF2F7FF), [
      _skyInk,
    ]),
    PatternArt('grid-navy', 'Blueprint', Motif.grid, _cobalt, [_cobaltInk]),
    PatternArt('dot-grid-sand', 'Dot grid', Motif.dotGrid, _sand, [_sandInk]),
    PatternArt('lined-butter', 'Notebook', Motif.lined, Color(0xFFFFF8E1), [
      _skyInk,
      _blushInk,
    ]),
  ]),
];

const List<ArtCollection> textureCollections = [
  ArtCollection('paper', 'Paper', [
    TextureArt('paper-cotton', 'Cotton paper', Weave.paper, Color(0xFFF8F4EA), [
      Color(0xFFE6DFCF),
      Color(0xFFEFE9DB),
      Color(0xFFFFFFFF),
    ]),
    TextureArt('paper-kraft', 'Kraft', Weave.kraft, Color(0xFFD9B98C), [
      Color(0xFFC7A273),
      Color(0xFFE6CBA3),
      Color(0xFFB8925F),
    ]),
    TextureArt('paper-news', 'Newsprint', Weave.paper, Color(0xFFE9E6DD), [
      Color(0xFFD4D0C5),
      Color(0xFFF3F1EA),
      Color(0xFFC6C1B4),
    ]),
    TextureArt('paper-blush', 'Rose paper', Weave.paper, Color(0xFFFBE3E3), [
      Color(0xFFF2CFCF),
      Color(0xFFFFF1F1),
      Color(0xFFE9C0C2),
    ]),
    TextureArt('paper-midnight', 'Midnight paper', Weave.kraft, _navy, [
      Color(0xFF283462),
      Color(0xFF18224A),
      Color(0xFF303D70),
    ]),
  ]),
  ArtCollection('fabric', 'Fabric', [
    TextureArt('linen-oat', 'Linen', Weave.linen, Color(0xFFEFE6D6), [
      Color(0xFFE0D4BE),
      Color(0xFFF8F2E6),
    ]),
    TextureArt('linen-sage', 'Sage linen', Weave.linen, Color(0xFFDDE6D3), [
      Color(0xFFCBD7BF),
      Color(0xFFEAF0E2),
    ]),
    TextureArt('canvas', 'Canvas', Weave.canvas, Color(0xFFE8DEC8), [
      Color(0xFFDACEB4),
      Color(0xFFF2EBDB),
    ]),
    TextureArt('denim', 'Denim', Weave.denim, Color(0xFF2F4A7A), [
      Color(0xFF3A5890),
      Color(0xFF253D68),
      Color(0xFF46639A),
    ]),
    TextureArt(
      'corduroy-mustard',
      'Corduroy',
      Weave.corduroy,
      Color(0xFFD9A441),
      [Color(0xFFC79231), Color(0xFFE6B65A)],
    ),
    TextureArt('corduroy-rust', 'Rust corduroy', Weave.corduroy, _rust, [
      Color(0xFF8A3426),
      Color(0xFFAD4A38),
    ]),
    TextureArt('felt-forest', 'Felt', Weave.felt, Color(0xFF2F5A45), [
      Color(0xFF3A6A53),
      Color(0xFF264C3A),
    ]),
    TextureArt('felt-red', 'Red felt', Weave.felt, Color(0xFFA3203F), [
      Color(0xFFB22D4C),
      Color(0xFF921A37),
    ]),
  ]),
  ArtCollection('grain', 'Grain', [
    TextureArt('grain-peach', 'Peach grain', Weave.grain, Color(0xFFFFD9C4), [
      Color(0xFFF5C7AE),
      Color(0xFFFFE9DC),
    ]),
    TextureArt('grain-lilac', 'Lilac grain', Weave.grain, Color(0xFFE4D8FA), [
      Color(0xFFD4C4F2),
      Color(0xFFF1EAFF),
    ]),
    TextureArt('grain-sky', 'Sky grain', Weave.grain, Color(0xFFCFE3FA), [
      Color(0xFFBCD5F2),
      Color(0xFFE2EEFD),
    ]),
    TextureArt('grain-mint', 'Mint grain', Weave.grain, Color(0xFFCFEFDF), [
      Color(0xFFBBE3CF),
      Color(0xFFE2F7EC),
    ]),
    TextureArt(
      'grain-charcoal',
      'Charcoal grain',
      Weave.grain,
      Color(0xFF34313F),
      [Color(0xFF2A2734), Color(0xFF423E4F)],
    ),
    TextureArt('grain-ember', 'Ember grain', Weave.grain, Color(0xFF9C3D2E), [
      Color(0xFF8C3426),
      Color(0xFFAB4836),
    ]),
  ]),
  ArtCollection('stone', 'Stone', [
    TextureArt('terrazzo', 'Terrazzo', Weave.terrazzo, Color(0xFFF2EDE4), [
      Color(0xFFF2A68A),
      Color(0xFF9CC9B4),
      Color(0xFFF2CB6B),
      Color(0xFFB9B3C9),
    ]),
    TextureArt(
      'terrazzo-pink',
      'Pink terrazzo',
      Weave.terrazzo,
      Color(0xFFF7DCDC),
      [
        Color(0xFFE59A9A),
        Color(0xFFFFFFFF),
        Color(0xFFD9A8B8),
        Color(0xFFC9B79C),
      ],
    ),
    TextureArt(
      'terrazzo-night',
      'Night terrazzo',
      Weave.terrazzo,
      Color(0xFF2B2838),
      [
        Color(0xFF5A4F7A),
        Color(0xFF7A4A3A),
        Color(0xFF3F6157),
        Color(0xFF4A4658),
      ],
    ),
    TextureArt('marble', 'Marble', Weave.marble, Color(0xFFF4F2EE), [
      Color(0xFFC9C5BE),
      Color(0xFFDDDAD4),
    ]),
    TextureArt(
      'marble-green',
      'Green marble',
      Weave.marble,
      Color(0xFF1F4D3E),
      [Color(0xFF2F6B57), Color(0xFF285E4C)],
    ),
    TextureArt('stucco', 'Plaster', Weave.stucco, Color(0xFFE9E1D3), [
      Color(0xFFDDD3C1),
      Color(0xFFF3EDE3),
    ]),
    TextureArt('sand', 'Sand', Weave.sand, Color(0xFFE8D3AE), [
      Color(0xFFD9C095),
      Color(0xFFF1E1C4),
      Color(0xFFC9AE82),
    ]),
  ]),
  ArtCollection('wood', 'Wood and cork', [
    TextureArt('wood-oak', 'Oak', Weave.wood, Color(0xFFD9B07A), [
      Color(0xFFC89C64),
      Color(0xFFE4C08F),
    ]),
    TextureArt('wood-birch', 'Birch', Weave.wood, Color(0xFFEDE1CC), [
      Color(0xFFDDCDB1),
      Color(0xFFF5ECDC),
    ]),
    TextureArt('wood-walnut', 'Walnut', Weave.wood, Color(0xFF5C3B26), [
      Color(0xFF6E4A32),
      Color(0xFF4E311F),
    ]),
    TextureArt('cork', 'Cork', Weave.cork, Color(0xFFC99A63), [
      Color(0xFFB88852),
      Color(0xFFD9AD78),
      Color(0xFFA97B47),
    ]),
  ]),
  ArtCollection('wash', 'Watercolor', [
    TextureArt('wash-sky', 'Sky wash', Weave.watercolour, Color(0xFFDCEBF8), [
      Color(0xFFC3DBF2),
      Color(0xFFEAF3FC),
      Color(0xFFCFE0F0),
    ]),
    TextureArt('wash-rose', 'Rose wash', Weave.watercolour, Color(0xFFF9E0E4), [
      Color(0xFFF2C6CE),
      Color(0xFFFDEFF1),
      Color(0xFFF5D3DA),
    ]),
    TextureArt('wash-mint', 'Mint wash', Weave.watercolour, Color(0xFFDDF2E6), [
      Color(0xFFC4E7D3),
      Color(0xFFEDF8F2),
      Color(0xFFD0EDDC),
    ]),
    TextureArt('wash-ink', 'Ink wash', Weave.watercolour, Color(0xFF2E3550), [
      Color(0xFF3B4466),
      Color(0xFF242A42),
      Color(0xFF353D5C),
    ]),
  ]),
];

const List<ArtCollection> illustrationCollections = [
  ArtCollection('seasons', 'Seasons', [
    IllustrationArt(
      'spring-blossom',
      'Spring blossom',
      Color(0xFFFFF1EE),
      land: Land.meadow,
      landColors: [Color(0xFFCDE7B0), Color(0xFFA8D58C), Color(0xFF8FC777)],
      sprites: [Sprite.blossom, Sprite.butterfly],
      spriteColors: [Color(0xFFF29BB2), Color(0xFFF7B6C8), Color(0xFFC4A8F0)],
    ),
    IllustrationArt(
      'summer-sun',
      'Summer sun',
      Color(0xFFFFF4D6),
      land: Land.waves,
      landColors: [Color(0xFFA6D9EA), Color(0xFF86C8DF)],
      hero: SkyFeature.sun,
      heroColors: [Color(0xFFF6B53D)],
      sprites: [Sprite.bird, Sprite.cloud],
      spriteColors: [Color(0xFFE9A86B), Color(0xFFF2C98A)],
      density: 0.6,
    ),
    IllustrationArt(
      'autumn-leaves',
      'Autumn leaves',
      Color(0xFFFBEBD9),
      land: Land.hills,
      landColors: [Color(0xFFEBC39A), Color(0xFFE0A877)],
      sprites: [Sprite.leaf],
      spriteColors: [Color(0xFFE88E6A), Color(0xFFE9A23B), Color(0xFFD9A05B)],
      density: 1.2,
    ),
    IllustrationArt(
      'first-snow',
      'First snow',
      Color(0xFFE3EEF8),
      land: Land.snow,
      landColors: [Color(0xFFF4F8FC), Color(0xFFFFFFFF)],
      sprites: [Sprite.snowflake],
      spriteColors: [Color(0xFF9DC2E6), Color(0xFFB4D0EC)],
      density: 1.2,
    ),
    IllustrationArt(
      'rainy-day',
      'Rainy day',
      Color(0xFFDDE7EF),
      land: Land.hills,
      landColors: [Color(0xFFB4CBBE), Color(0xFF9BBBA9)],
      sprites: [Sprite.raindrop, Sprite.cloud],
      spriteColors: [Color(0xFF86ABCC), Color(0xFFA8C0D4)],
      density: 1.2,
    ),
    IllustrationArt(
      'harvest',
      'Harvest',
      Color(0xFFF6E7C8),
      land: Land.meadow,
      landColors: [Color(0xFFE0BE7C), Color(0xFFD0A85E), Color(0xFFC0974A)],
      sprites: [Sprite.pumpkin, Sprite.leaf],
      spriteColors: [Color(0xFFE8914A), Color(0xFFD9A441)],
      density: 0.8,
    ),
  ]),
  ArtCollection('holidays', 'Holidays', [
    IllustrationArt(
      'christmas',
      'Christmas',
      Color(0xFFF4EDE4),
      land: Land.forest,
      landColors: [Color(0xFFA9CDB4), Color(0xFF86BB98), Color(0xFF6FAE86)],
      sprites: [Sprite.star, Sprite.snowflake, Sprite.gift],
      spriteColors: [Color(0xFFE5867A), Color(0xFF86BB98), Color(0xFFE9B949)],
    ),
    IllustrationArt(
      'halloween',
      'Halloween',
      Color(0xFF2A1F45),
      land: Land.hills,
      landColors: [Color(0xFF3A2B5C), Color(0xFF47356E)],
      hero: SkyFeature.moon,
      heroColors: [Color(0xFF6E62A0)],
      sprites: [Sprite.pumpkin, Sprite.bat],
      spriteColors: [Color(0xFFB0561C), Color(0xFF5B4A8A)],
      density: 0.8,
    ),
    IllustrationArt(
      'valentines',
      'Valentine’s',
      Color(0xFFFFE6EC),
      sprites: [Sprite.heart],
      spriteColors: [Color(0xFFF28AA5), Color(0xFFF6A9BD), Color(0xFFEE97B0)],
      density: 1.3,
    ),
    IllustrationArt(
      'easter',
      'Easter',
      Color(0xFFEAF4FF),
      land: Land.meadow,
      landColors: [Color(0xFFC6E5A8), Color(0xFFA9D68A), Color(0xFF93CA74)],
      sprites: [Sprite.egg, Sprite.blossom],
      spriteColors: [
        Color(0xFFF7B6C8),
        Color(0xFFB9A5F0),
        Color(0xFFF2C14E),
        Color(0xFF8FD6C4),
      ],
    ),
    IllustrationArt(
      'new-year',
      'New Year’s Eve',
      Color(0xFF1C2340),
      land: Land.skyline,
      landColors: [Color(0xFF28305A), Color(0xFF323C6E), Color(0xFF5A5A8C)],
      sprites: [Sprite.firework, Sprite.sparkle],
      spriteColors: [Color(0xFF8C5AA8), Color(0xFF3E6FB0), Color(0xFFA0602E)],
    ),
    IllustrationArt(
      'lunar-new-year',
      'Lunar New Year',
      Color(0xFFFFEBD9),
      sprites: [Sprite.lantern, Sprite.cloud],
      spriteColors: [Color(0xFFE8705E), Color(0xFFF2A93B)],
      density: 0.8,
    ),
    IllustrationArt(
      'lights',
      'Festival of lights',
      Color(0xFFFFF0D9),
      sprites: [Sprite.diya, Sprite.sparkle],
      spriteColors: [Color(0xFFE8963A), Color(0xFFE88E6A), Color(0xFFD9A441)],
    ),
    IllustrationArt(
      'fireworks',
      'Fireworks',
      Color(0xFF1B2545),
      sprites: [Sprite.firework, Sprite.star],
      spriteColors: [Color(0xFFA5384A), Color(0xFF3E6FB0), Color(0xFF7A6AA8)],
      density: 1.1,
    ),
    IllustrationArt(
      'lucky-clover',
      'Lucky clover',
      Color(0xFFEAF6E4),
      land: Land.hills,
      landColors: [Color(0xFFBFE0AB), Color(0xFFA5D392)],
      sprites: [Sprite.clover],
      spriteColors: [Color(0xFF86C486), Color(0xFF9FD08F)],
    ),
  ]),
  ArtCollection('celebrations', 'Celebrations', [
    IllustrationArt(
      'birthday',
      'Birthday balloons',
      Color(0xFFFFF4E8),
      sprites: [Sprite.balloon, Sprite.confetti],
      spriteColors: [_red, _blue, _gold, _green, _violet],
    ),
    IllustrationArt(
      'party',
      'Party time',
      Color(0xFFEEE8FF),
      sprites: [Sprite.confetti, Sprite.sparkle, Sprite.star],
      spriteColors: [_red, _gold, _green, _blue, _orange],
      density: 1.3,
    ),
    IllustrationArt(
      'wedding',
      'Wedding',
      Color(0xFFFBF5EE),
      sprites: [Sprite.rings, Sprite.heart, Sprite.sparkle],
      spriteColors: [Color(0xFFE8B4B8), Color(0xFFD9C08A), Color(0xFFC9B6E4)],
      density: 0.9,
    ),
    IllustrationArt(
      'graduation',
      'Graduation',
      Color(0xFFE6EEFA),
      sprites: [Sprite.gradCap, Sprite.star],
      spriteColors: [Color(0xFF8AA6D8), Color(0xFFF2C14E)],
    ),
    IllustrationArt(
      'new-baby',
      'New baby',
      Color(0xFFEAF3FB),
      hero: SkyFeature.moon,
      heroColors: [Color(0xFFF2D27A)],
      sprites: [Sprite.cloud, Sprite.star],
      spriteColors: [Color(0xFFA9CBEA), Color(0xFFF7D58A), Color(0xFFF4B6C8)],
      density: 0.8,
    ),
    IllustrationArt(
      'anniversary',
      'Anniversary',
      Color(0xFF3B1E3F),
      sprites: [Sprite.heart, Sprite.sparkle],
      spriteColors: [Color(0xFF8C2F55), Color(0xFF6E4A7A)],
    ),
    IllustrationArt(
      'gifts',
      'Gifts',
      Color(0xFFF2F7EE),
      sprites: [Sprite.gift, Sprite.confetti],
      spriteColors: [_red, _green, _gold, _blue],
    ),
  ]),
  ArtCollection('nature', 'Nature', [
    IllustrationArt(
      'mountains',
      'Mountains',
      Color(0xFFE3EEF6),
      land: Land.mountains,
      landColors: [Color(0xFFB4C7DA), Color(0xFF9DB8CF), Color(0xFFF7FAFC)],
      hero: SkyFeature.sun,
      heroColors: [Color(0xFFF4C46A)],
      sprites: [Sprite.bird],
      spriteColors: [Color(0xFF8DA4BC)],
      density: 0.5,
    ),
    IllustrationArt(
      'ocean',
      'Ocean',
      Color(0xFFDFF2F7),
      land: Land.waves,
      landColors: [Color(0xFF9AD5E5), Color(0xFF79C3D8)],
      sprites: [Sprite.sailboat, Sprite.bird, Sprite.cloud],
      spriteColors: [Color(0xFF7FB0C9), Color(0xFFE9967A)],
      density: 0.6,
    ),
    IllustrationArt(
      'forest',
      'Forest',
      Color(0xFFE9F2E4),
      land: Land.forest,
      landColors: [Color(0xFFA9CFA7), Color(0xFF86BB86), Color(0xFF74AE76)],
      sprites: [Sprite.bird, Sprite.leaf],
      spriteColors: [Color(0xFF8FB894), Color(0xFFB5CF8E)],
      density: 0.6,
    ),
    IllustrationArt(
      'desert',
      'Desert',
      Color(0xFFFCEBD5),
      land: Land.dunes,
      landColors: [Color(0xFFF0CB98), Color(0xFFE4B67C), Color(0xFF8FC08A)],
      hero: SkyFeature.sun,
      heroColors: [Color(0xFFEFA25A)],
      sprites: [Sprite.bird],
      spriteColors: [Color(0xFFD9A56E)],
      density: 0.4,
    ),
    IllustrationArt(
      'starry-night',
      'Starry night',
      Color(0xFF1B2140),
      land: Land.hills,
      landColors: [Color(0xFF242C52), Color(0xFF2C3561)],
      hero: SkyFeature.moon,
      heroColors: [Color(0xFF5E6A9E)],
      sprites: [Sprite.star, Sprite.sparkle],
      spriteColors: [Color(0xFF57609A), Color(0xFF6A5F95), Color(0xFF7A6A3A)],
      density: 1.3,
    ),
    IllustrationArt(
      'garden',
      'Garden',
      Color(0xFFF3F8EC),
      land: Land.meadow,
      landColors: [Color(0xFFC9E3AE), Color(0xFFAED793), Color(0xFF96CA7A)],
      sprites: [Sprite.flower, Sprite.butterfly],
      spriteColors: [Color(0xFFF29BB2), Color(0xFFF2C14E), Color(0xFFB9A5F0)],
    ),
    IllustrationArt(
      'under-the-sea',
      'Under the sea',
      Color(0xFFCFEBF0),
      land: Land.dunes,
      landColors: [Color(0xFFE6D6B0), Color(0xFFDBC79C), Color(0xFF8CCBB0)],
      sprites: [Sprite.fish, Sprite.bubble],
      spriteColors: [Color(0xFFF2A06B), Color(0xFF8CB8E0), Color(0xFFA6D9E0)],
    ),
    IllustrationArt(
      'rainbow',
      'Rainbow',
      Color(0xFFF1F6FF),
      land: Land.hills,
      landColors: [Color(0xFFC6E5B0), Color(0xFFADD898)],
      hero: SkyFeature.rainbow,
      heroColors: [_red, _gold, _blue],
      sprites: [Sprite.cloud],
      spriteColors: [Color(0xFFC3D6EE)],
      density: 0.5,
    ),
  ]),
  ArtCollection('travel', 'Travel', [
    IllustrationArt(
      'beach-day',
      'Beach day',
      Color(0xFFE2F4F8),
      land: Land.beach,
      landColors: [Color(0xFF8ED0E0), Color(0xFFF1D9A8), Color(0xFF8FC08A)],
      hero: SkyFeature.sun,
      heroColors: [Color(0xFFF2C14E)],
      sprites: [Sprite.bird, Sprite.cloud],
      spriteColors: [Color(0xFF8CB4C9), Color(0xFFC8E1EC)],
      density: 0.5,
    ),
    IllustrationArt(
      'city-lights',
      'City lights',
      Color(0xFF1E2140),
      land: Land.skyline,
      landColors: [Color(0xFF2B2F5A), Color(0xFF353A6B), Color(0xFF7A6A3A)],
      hero: SkyFeature.moon,
      heroColors: [Color(0xFF5E6A9E)],
      sprites: [Sprite.star],
      spriteColors: [Color(0xFF4F578A)],
      density: 0.8,
    ),
    IllustrationArt(
      'take-off',
      'Take off',
      Color(0xFFDCEBFA),
      sprites: [Sprite.cloud, Sprite.plane],
      spriteColors: [Color(0xFFB9D2EC), Color(0xFF8DA6D6), Color(0xFFF2A06B)],
      density: 0.8,
    ),
    IllustrationArt(
      'camping',
      'Camping',
      Color(0xFF1F2B3E),
      land: Land.camp,
      landColors: [Color(0xFF26364A), Color(0xFF2C4236), Color(0xFFA0602E)],
      hero: SkyFeature.moon,
      heroColors: [Color(0xFF5E6A9E)],
      sprites: [Sprite.star],
      spriteColors: [Color(0xFF4E5A7E), Color(0xFF6A5F95)],
      density: 1.1,
    ),
    IllustrationArt(
      'up-and-away',
      'Up and away',
      Color(0xFFFDEEDF),
      land: Land.hills,
      landColors: [Color(0xFFCBE0B4), Color(0xFFB3D39A)],
      sprites: [Sprite.hotAirBalloon, Sprite.cloud],
      spriteColors: [Color(0xFFF28C8C), Color(0xFFF2C14E), Color(0xFF8DB8F2)],
      density: 0.6,
    ),
  ]),
];

List<ArtCollection> artCollectionsFor(ArtKind kind) => switch (kind) {
  ArtKind.pattern => patternCollections,
  ArtKind.texture => textureCollections,
  ArtKind.illustration => illustrationCollections,
};

/// Every art piece, in collection order.
final List<Art> artLibrary = [
  for (final k in ArtKind.values)
    for (final c in artCollectionsFor(k)) ...c.items,
];

final Map<String, Art> _byId = {for (final a in artLibrary) a.id: a};

Art? artById(String? id) => id == null ? null : _byId[id];
