import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:material_ui/material_ui.dart';

/// Every background the editor offers, in titled collections. This is the
/// one place to add colours and gradients: the Look tab, the All
/// backgrounds sheet and the contrast test all read from it.
///
/// Stability rules, so saved countdowns never change:
/// - A colour is saved as its ARGB value: never edit an existing colour's
///   value, add a new entry instead.
/// - A gradient is saved by id: never rename or reuse an id, and keep its
///   stops as they are.
/// - Moving an entry between collections, or renaming it, is fine.
/// Every entry must pass test/background_catalog_test.dart (AA contrast
/// with its automatic text colour, unique values and ids).
class ColourCollection {
  const ColourCollection(this.id, this.name, this.colours);
  final String id;
  final String name;
  final List<PaletteColor> colours;
}

class GradientCollection {
  const GradientCollection(this.id, this.name, this.gradients);
  final String id;
  final String name;
  final List<GradientPreset> gradients;
}

const List<ColourCollection> colourCollections = [
  ColourCollection('warm', 'Warm', [
    PaletteColor('Tomato', tomato),
    PaletteColor('Tangerine', tangerine),
    PaletteColor('Papaya', Color(0xFFFF9A3D)),
    PaletteColor('Sun', sun),
    PaletteColor('Flamingo', Color(0xFFFF8DA8)),
    PaletteColor('Bubblegum', bubblegum),
    PaletteColor('Coral', Color(0xFFFF7A5C)),
    PaletteColor('Persimmon', Color(0xFFF2552C)),
    PaletteColor('Saffron', Color(0xFFF9C80E)),
    PaletteColor('Rose', Color(0xFFF06C8F)),
    PaletteColor('Mango', Color(0xFFFFAE42)),
    PaletteColor('Cherry blossom', Color(0xFFF7A1B8)),
  ]),
  ColourCollection('cool', 'Cool', [
    PaletteColor('Teal', Color(0xFF2BB3A3)),
    PaletteColor('Mint', mint),
    PaletteColor('Aqua', Color(0xFF48D1DE)),
    PaletteColor('Sky', sky),
    PaletteColor('Cornflower', Color(0xFF86A7FA)),
    PaletteColor('Cobalt', cobalt),
    PaletteColor('Periwinkle', Color(0xFFA7A5F7)),
    PaletteColor('Lavender', lavender),
    PaletteColor('Cerulean', Color(0xFF2E9BD6)),
    PaletteColor('Jade', Color(0xFF3DBB8F)),
    PaletteColor('Iris', Color(0xFF8F86F0)),
    PaletteColor('Pool', Color(0xFF5CC9E8)),
    PaletteColor('Celadon', Color(0xFF8CCFB4)),
  ]),
  ColourCollection('pastel', 'Pastel', [
    PaletteColor('Shell', Color(0xFFFFDCCB)),
    PaletteColor('Peach', peach),
    PaletteColor('Apricot', Color(0xFFFFB98A)),
    PaletteColor('Butter', Color(0xFFFFE89E)),
    PaletteColor('Pistachio', Color(0xFFCDE8A4)),
    PaletteColor('Seafoam', Color(0xFFB4EEDB)),
    PaletteColor('Glacier', Color(0xFFA9DDF7)),
    PaletteColor('Powder', Color(0xFFC3D8FA)),
    PaletteColor('Wisteria', Color(0xFFDCCFFA)),
    PaletteColor('Lilac', lilac),
    PaletteColor('Blush', Color(0xFFFFCAD6)),
    PaletteColor('Vanilla', Color(0xFFFFF0D1)),
    PaletteColor('Melon', Color(0xFFFFC2A6)),
    PaletteColor('Petal', Color(0xFFFBD3E9)),
    PaletteColor('Lavender mist', Color(0xFFE6DFFC)),
    PaletteColor('Honeydew', Color(0xFFE3F5C8)),
    PaletteColor('Mint cream', Color(0xFFD6F5E8)),
    PaletteColor('Fairy floss', Color(0xFFF2C6F0)),
    PaletteColor('Sage mist', Color(0xFFD3E2C9)),
  ]),
  ColourCollection('bold', 'Bold', [
    PaletteColor('Crimson', Color(0xFFC3203A)),
    PaletteColor('Fuchsia', Color(0xFFC4247F)),
    PaletteColor('Violet', Color(0xFF6A3AC8)),
    PaletteColor('Ultramarine', Color(0xFF2C5BD6)),
    PaletteColor('Emerald', Color(0xFF14A06E)),
    PaletteColor('Lime', lime),
    PaletteColor('Kelly', Color(0xFF1F9E4A)),
    PaletteColor('Orchid', Color(0xFFA13EC2)),
    PaletteColor('Raspberry', Color(0xFFC21E56)),
    PaletteColor('Plum', Color(0xFF7A2E8C)),
    PaletteColor('Amethyst', Color(0xFF8B4CCF)),
  ]),
  ColourCollection('earthy', 'Earthy', [
    PaletteColor('Terracotta', Color(0xFFA84B2B)),
    PaletteColor('Clay', Color(0xFFD99572)),
    PaletteColor('Sand', Color(0xFFE6D1A8)),
    PaletteColor('Olive', Color(0xFFA3A33A)),
    PaletteColor('Moss', Color(0xFF86A85A)),
    PaletteColor('Forest', Color(0xFF27624B)),
    PaletteColor('Mushroom', Color(0xFFB3A08E)),
    PaletteColor('Cinnamon', Color(0xFFC47A45)),
    PaletteColor('Ochre', Color(0xFFCC9933)),
    PaletteColor('Mustard', Color(0xFFD4A72C)),
    PaletteColor('Sienna', Color(0xFF9E5A3C)),
    PaletteColor('Sage', Color(0xFF9CAF88)),
    PaletteColor('Khaki', Color(0xFFBFB07A)),
    PaletteColor('Caramel', Color(0xFFD49A6A)),
    PaletteColor('Brick', Color(0xFF9C3D2E)),
    PaletteColor('Cocoa', Color(0xFF6B4A3A)),
  ]),
  ColourCollection('neutral', 'Neutral', [
    PaletteColor('Stone', Color(0xFFC2BBAE)),
    PaletteColor('Charcoal', charcoal),
    PaletteColor('Slate', Color(0xFF4E5970)),
    PaletteColor('Graphite', Color(0xFF3A3747)),
    PaletteColor('Midnight', Color(0xFF1F2A52)),
    PaletteColor('Fog', Color(0xFFD9D6CF)),
    PaletteColor('Pebble', Color(0xFFA8A39A)),
    PaletteColor('Steel', Color(0xFF5F6B7A)),
    PaletteColor('Onyx', Color(0xFF26232E)),
  ]),
  ColourCollection('jewel', 'Jewel', [
    PaletteColor('Sapphire', Color(0xFF1F4E9E)),
    PaletteColor('Topaz', Color(0xFFE89A2C)),
    PaletteColor('Peacock', Color(0xFF0F7C8A)),
    PaletteColor('Tanzanite', Color(0xFF4B3BA8)),
    PaletteColor('Malachite', Color(0xFF0E7A57)),
    PaletteColor('Lapis', Color(0xFF28407A)),
    PaletteColor('Opal', Color(0xFF8FD3C9)),
  ]),
  ColourCollection('muted', 'Muted', [
    PaletteColor('Dusty rose', Color(0xFFC98A93)),
    PaletteColor('Heather', Color(0xFFA797B8)),
    PaletteColor('Eucalyptus', Color(0xFF8FAEA0)),
    PaletteColor('Denim wash', Color(0xFF7F98B8)),
    PaletteColor('Rosewood', Color(0xFF8C4A5A)),
    PaletteColor('Seaglass', Color(0xFF9CC4BC)),
    PaletteColor('Mauve', Color(0xFFB48AA8)),
  ]),
  ColourCollection('seasonal', 'Seasonal', [
    PaletteColor('Holly', Color(0xFF1F6B3A)),
    PaletteColor('Cranberry', Color(0xFFA3203F)),
    PaletteColor('Snowberry', Color(0xFFEEF2F5)),
    PaletteColor('Pumpkin spice', Color(0xFFD9732E)),
    PaletteColor('Spring bud', Color(0xFFB8E07A)),
    PaletteColor('Frost blue', Color(0xFFB9D7F0)),
  ]),
];

// New colours used in gradients below.
const _flamingo = Color(0xFFFF8DA8);
const _aqua = Color(0xFF48D1DE);
const _cornflower = Color(0xFF86A7FA);
const _teal = Color(0xFF2BB3A3);
const _seafoam = Color(0xFFB4EEDB);
const _glacier = Color(0xFFA9DDF7);
const _powder = Color(0xFFC3D8FA);
const _butter = Color(0xFFFFE89E);
const _blush = Color(0xFFFFCAD6);
const _pistachio = Color(0xFFCDE8A4);
const _crimson = Color(0xFFC3203A);
const _fuchsia = Color(0xFFC4247F);
const _violet = Color(0xFF6A3AC8);
const _forest = Color(0xFF27624B);
const _graphite = Color(0xFF3A3747);
const _midnight = Color(0xFF1F2A52);

const List<GradientCollection> gradientCollections = [
  GradientCollection('sunset', 'Sunset', [
    GradientPreset('sunset', 'Sunset', [tangerine, bubblegum]),
    GradientPreset('peachy', 'Peachy', [peach, sun]),
    GradientPreset('ember', 'Ember', [tomato, tangerine]),
    GradientPreset('golden-hour', 'Golden hour', [sun, _flamingo]),
    GradientPreset('dusk', 'Dusk', [cobalt, lilac, peach]),
    GradientPreset('tropical', 'Tropical', [sun, tangerine, bubblegum]),
    GradientPreset('papaya-rose', 'Papaya rose', [
      Color(0xFFFF9A3D),
      Color(0xFFF06C8F),
    ]),
    GradientPreset('afterglow', 'Afterglow', [
      Color(0xFFF9C80E),
      Color(0xFFFF7A5C),
      Color(0xFFF06C8F),
    ]),
    GradientPreset('marmalade', 'Marmalade', [
      Color(0xFFFFAE42),
      Color(0xFFF2552C),
    ]),
    GradientPreset('flame', 'Flame', [Color(0xFFF7BC33), Color(0xFFF2552C)]),
    GradientPreset('sundown', 'Sundown', [
      Color(0xFFFF7A5C),
      Color(0xFFF7A1B8),
    ]),
    GradientPreset('horizon', 'Horizon', [
      Color(0xFFFFB98A),
      Color(0xFFFF8DA8),
      Color(0xFFDCCFFA),
    ]),
  ]),
  GradientCollection('ocean', 'Ocean', [
    GradientPreset('lagoon', 'Lagoon', [sky, mint]),
    GradientPreset('ocean', 'Ocean', [cobalt, sky]),
    GradientPreset('tide', 'Tide', [_aqua, _cornflower]),
    GradientPreset('frost', 'Frost', [_powder, _glacier]),
    GradientPreset('reef', 'Reef', [_teal, _aqua, _seafoam]),
    GradientPreset('shallows', 'Shallows', [
      Color(0xFF5CC9E8),
      Color(0xFFA9DDF7),
    ]),
    GradientPreset('high-tide', 'High tide', [
      Color(0xFF2E9BD6),
      Color(0xFF2BB3A3),
    ]),
    GradientPreset('mariner', 'Mariner', [
      Color(0xFF597FFE),
      Color(0xFF2E9BD6),
    ]),
    GradientPreset('tidepool', 'Tidepool', [
      Color(0xFF3DBB8F),
      Color(0xFF48D1DE),
    ]),
    GradientPreset('breaker', 'Breaker', [
      Color(0xFF66B6FE),
      Color(0xFF5CC9E8),
      Color(0xFFB4EEDB),
    ]),
    GradientPreset('harbour', 'Harbour', [
      Color(0xFF2C5BD6),
      Color(0xFF0F7C8A),
    ]),
    GradientPreset('bay', 'Bay', [Color(0xFF86A7FA), Color(0xFF48D1DE)]),
  ]),
  GradientCollection('candy', 'Candy', [
    GradientPreset('candy', 'Candy', [lilac, bubblegum]),
    GradientPreset('berry', 'Berry', [bubblegum, lavender]),
    GradientPreset('grape', 'Grape', [lavender, lilac]),
    GradientPreset('cotton-candy', 'Cotton candy', [_blush, _powder]),
    GradientPreset('sherbet', 'Sherbet', [_blush, _butter, _seafoam]),
    GradientPreset('bubblegum-pop', 'Bubblegum pop', [
      Color(0xFFFE607C),
      Color(0xFFFF8DA8),
    ]),
    GradientPreset('jellybean', 'Jellybean', [
      Color(0xFFF06C8F),
      Color(0xFF8F86F0),
    ]),
    GradientPreset('marshmallow', 'Marshmallow', [
      Color(0xFFFBD3E9),
      Color(0xFFE6DFFC),
    ]),
    GradientPreset('gumdrop', 'Gumdrop', [
      Color(0xFFF2C6F0),
      Color(0xFFC9A7F5),
      Color(0xFFC3D8FA),
    ]),
    GradientPreset('lollipop', 'Lollipop', [
      Color(0xFFF7A1B8),
      Color(0xFFDCCFFA),
    ]),
    GradientPreset('parfait', 'Parfait', [
      Color(0xFFFFC2A6),
      Color(0xFFFFCAD6),
      Color(0xFFC9A7F5),
    ]),
  ]),
  GradientCollection('garden', 'Garden', [
    GradientPreset('citrus', 'Citrus', [sun, lime]),
    GradientPreset('mojito', 'Mojito', [lime, mint]),
    GradientPreset('meadow', 'Meadow', [_pistachio, _seafoam]),
    GradientPreset('aurora', 'Aurora', [mint, cobalt, lavender]),
    GradientPreset('fresh-cut', 'Fresh cut', [
      Color(0xFF83C236),
      Color(0xFF3DBB8F),
    ]),
    GradientPreset('greenhouse', 'Greenhouse', [
      Color(0xFF86A85A),
      Color(0xFF8CCFB4),
    ]),
    GradientPreset('orchard', 'Orchard', [
      Color(0xFFB8E07A),
      Color(0xFFF7BC33),
    ]),
    GradientPreset('fern-gully', 'Fern gully', [
      Color(0xFF1F9E4A),
      Color(0xFF2BB3A3),
    ]),
    GradientPreset('lilypad', 'Lilypad', [
      Color(0xFFCDE8A4),
      Color(0xFFD6F5E8),
    ]),
    GradientPreset('wildflower', 'Wildflower', [
      Color(0xFFFFE89E),
      Color(0xFFFBD3E9),
      Color(0xFFC9A7F5),
    ]),
    GradientPreset('herb-garden', 'Herb garden', [
      Color(0xFF9CAF88),
      Color(0xFF8FAEA0),
    ]),
  ]),
  GradientCollection('night', 'Night', [
    GradientPreset('starlight', 'Starlight', [_midnight, _violet]),
    GradientPreset('deep-sea', 'Deep sea', [_midnight, _forest]),
    GradientPreset('nebula', 'Nebula', [_midnight, _violet, _fuchsia]),
    GradientPreset('embers', 'Embers', [_graphite, _crimson]),
    GradientPreset('twilight', 'Twilight', [
      Color(0xFF28407A),
      Color(0xFF7A2E8C),
    ]),
    GradientPreset('moonless', 'Moonless', [
      Color(0xFF26232E),
      Color(0xFF1F2A52),
    ]),
    GradientPreset('northern-sky', 'Northern sky', [
      Color(0xFF1F2A52),
      Color(0xFF0F7C8A),
    ]),
    GradientPreset('velvet', 'Velvet', [Color(0xFF7A2E8C), Color(0xFF8C4A5A)]),
    GradientPreset('galaxy', 'Galaxy', [
      Color(0xFF4B3BA8),
      Color(0xFF6A3AC8),
      Color(0xFFC4247F),
    ]),
    GradientPreset('after-dark', 'After dark', [
      Color(0xFF3A3747),
      Color(0xFF28407A),
      Color(0xFF4B3BA8),
    ]),
  ]),
  GradientCollection('aurora', 'Aurora', [
    GradientPreset('borealis', 'Borealis', [
      Color(0xFF0E7A57),
      Color(0xFF0F7C8A),
      Color(0xFF4B3BA8),
    ]),
    GradientPreset('polar-light', 'Polar light', [
      Color(0xFFB4EEDB),
      Color(0xFFA9DDF7),
      Color(0xFFE6DFFC),
    ]),
    GradientPreset('solar-wind', 'Solar wind', [
      Color(0xFF3DBB8F),
      Color(0xFF2E9BD6),
      Color(0xFF8F86F0),
    ]),
    GradientPreset('northern-lights', 'Northern lights', [
      Color(0xFF0E7A57),
      Color(0xFF1F4E9E),
      Color(0xFF6A3AC8),
    ]),
    GradientPreset('shimmer', 'Shimmer', [
      Color(0xFF5FD3B5),
      Color(0xFFA7A5F7),
    ]),
    GradientPreset('glow', 'Glow', [
      Color(0xFF8CCFB4),
      Color(0xFF5CC9E8),
      Color(0xFFDCCFFA),
    ]),
    GradientPreset('spectrum', 'Spectrum', [
      Color(0xFFF9C80E),
      Color(0xFFFF7A5C),
      Color(0xFF8F86F0),
    ]),
  ]),
  GradientCollection('citrus', 'Citrus', [
    GradientPreset('lemon-lime', 'Lemon lime', [
      Color(0xFFFFE89E),
      Color(0xFFB8E07A),
    ]),
    GradientPreset('orangeade', 'Orangeade', [
      Color(0xFFFFAE42),
      Color(0xFFF9C80E),
    ]),
    GradientPreset('grapefruit', 'Grapefruit', [
      Color(0xFFFF7A5C),
      Color(0xFFFFB98A),
    ]),
    GradientPreset('yuzu', 'Yuzu', [Color(0xFFF7BC33), Color(0xFFCDE8A4)]),
    GradientPreset('tangelo', 'Tangelo', [
      Color(0xFFFE7228),
      Color(0xFFF7BC33),
    ]),
    GradientPreset('key-lime', 'Key lime', [
      Color(0xFFE3F5C8),
      Color(0xFF83C236),
    ]),
    GradientPreset('blood-orange', 'Blood orange', [
      Color(0xFFF2552C),
      Color(0xFFFF7A5C),
    ]),
  ]),
  GradientCollection('berry', 'Berry', [
    GradientPreset('blackberry', 'Blackberry', [
      Color(0xFF7A2E8C),
      Color(0xFF6A3AC8),
    ]),
    GradientPreset('raspberry-ripple', 'Raspberry ripple', [
      Color(0xFFC21E56),
      Color(0xFFC4247F),
    ]),
    GradientPreset('blueberry', 'Blueberry', [
      Color(0xFF4B3BA8),
      Color(0xFF2C5BD6),
    ]),
    GradientPreset('mixed-berry', 'Mixed berry', [
      Color(0xFFC3203A),
      Color(0xFF7A2E8C),
      Color(0xFF28407A),
    ]),
    GradientPreset('strawberry', 'Strawberry', [
      Color(0xFFFF564A),
      Color(0xFFFE607C),
    ]),
    GradientPreset('boysenberry', 'Boysenberry', [
      Color(0xFF8C4A5A),
      Color(0xFFA13EC2),
    ]),
    GradientPreset('acai', 'Açaí', [Color(0xFF8B4CCF), Color(0xFFC21E56)]),
  ]),
  GradientCollection('holiday', 'Holiday', [
    GradientPreset('mistletoe', 'Mistletoe', [
      Color(0xFF1F6B3A),
      Color(0xFF27624B),
    ]),
    GradientPreset('candy-cane-swirl', 'Candy cane swirl', [
      Color(0xFFA3203F),
      Color(0xFFC3203A),
    ]),
    GradientPreset('snowfall', 'Snowfall', [
      Color(0xFFEEF2F5),
      Color(0xFFB9D7F0),
    ]),
    GradientPreset('harvest', 'Harvest', [
      Color(0xFFD9732E),
      Color(0xFFCC9933),
    ]),
    GradientPreset('valentine-hearts', 'Hearts', [
      Color(0xFFF06C8F),
      Color(0xFFF7A1B8),
    ]),
    GradientPreset('easter-egg', 'Easter egg', [
      Color(0xFFFFE89E),
      Color(0xFFDCCFFA),
      Color(0xFFB4EEDB),
    ]),
    GradientPreset('fireworks', 'Fireworks', [
      Color(0xFF2C5BD6),
      Color(0xFFC4247F),
      Color(0xFFC3203A),
    ]),
    GradientPreset('witching-hour', 'Witching hour', [
      Color(0xFF26232E),
      Color(0xFF7A2E8C),
    ]),
    GradientPreset('springtime', 'Springtime', [
      Color(0xFFB8E07A),
      Color(0xFFFBD3E9),
    ]),
  ]),
  GradientCollection('soft', 'Soft blends', [
    GradientPreset('linen', 'Linen', [Color(0xFFFFF0D1), Color(0xFFE6D1A8)]),
    GradientPreset('pearlescent', 'Pearlescent', [
      Color(0xFFE6DFFC),
      Color(0xFFD9D6CF),
      Color(0xFFC3D8FA),
    ]),
    GradientPreset('champagne', 'Champagne', [
      Color(0xFFE6D1A8),
      Color(0xFFFFDCCB),
    ]),
    GradientPreset('dove', 'Dove', [Color(0xFFD9D6CF), Color(0xFFC2BBAE)]),
    GradientPreset('silver-lining', 'Silver lining', [
      Color(0xFFA9DDF7),
      Color(0xFFD9D6CF),
    ]),
    GradientPreset('rose-gold', 'Rose gold', [
      Color(0xFFC98A93),
      Color(0xFFD99572),
    ]),
    GradientPreset('sea-mist', 'Sea mist', [
      Color(0xFF9CC4BC),
      Color(0xFFD3E2C9),
    ]),
    GradientPreset('heathered', 'Heathered', [
      Color(0xFFA797B8),
      Color(0xFFB48AA8),
    ]),
  ]),
  GradientCollection('earth', 'Earthy', [
    GradientPreset('canyon', 'Canyon', [Color(0xFFA84B2B), Color(0xFF9C3D2E)]),
    GradientPreset('desert', 'Desert', [Color(0xFFD49A6A), Color(0xFFE6D1A8)]),
    GradientPreset('forest-floor', 'Forest floor', [
      Color(0xFF27624B),
      Color(0xFF0F7C8A),
    ]),
    GradientPreset('autumn', 'Autumn', [
      Color(0xFFC47A45),
      Color(0xFFCC9933),
      Color(0xFFD4A72C),
    ]),
    GradientPreset('clay-pot', 'Clay pot', [
      Color(0xFFD49A6A),
      Color(0xFFD99572),
    ]),
    GradientPreset('cocoa-bean', 'Cocoa bean', [
      Color(0xFF6B4A3A),
      Color(0xFF9E5A3C),
    ]),
  ]),
];

/// The colours and gradient ids the app shipped with before the catalogue
/// grew. Saved countdowns use them, so they must always resolve to exactly
/// these values (test/background_catalog_test.dart checks this).
const Map<String, int> originalColours = {
  'Lavender': 0xFF7877E6,
  'Charcoal': 0xFF8A8796,
  'Sun': 0xFFF7BC33,
  'Tomato': 0xFFFF564A,
  'Peach': 0xFFFEA08B,
  'Tangerine': 0xFFFE7228,
  'Lime': 0xFF83C236,
  'Cobalt': 0xFF597FFE,
  'Sky': 0xFF66B6FE,
  'Bubblegum': 0xFFFE607C,
  'Mint': 0xFF5FD3B5,
  'Lilac': 0xFFC9A7F5,
};

const Map<String, List<int>> originalGradients = {
  'sunset': [0xFFFE7228, 0xFFFE607C],
  'lagoon': [0xFF66B6FE, 0xFF5FD3B5],
  'grape': [0xFF7877E6, 0xFFC9A7F5],
  'peachy': [0xFFFEA08B, 0xFFF7BC33],
  'berry': [0xFFFE607C, 0xFF7877E6],
  'ocean': [0xFF597FFE, 0xFF66B6FE],
  'citrus': [0xFFF7BC33, 0xFF83C236],
  'ember': [0xFFFF564A, 0xFFFE7228],
  'mojito': [0xFF83C236, 0xFF5FD3B5],
  'dusk': [0xFF597FFE, 0xFFC9A7F5, 0xFFFEA08B],
  'candy': [0xFFC9A7F5, 0xFFFE607C],
  'aurora': [0xFF5FD3B5, 0xFF597FFE, 0xFF7877E6],
};

/// Picks that pad the Look tab's row before there are recents.
const List<String> featuredBackgrounds = [
  'gradient:sunset',
  'gradient:lagoon',
  'gradient:dusk',
  'colour:FFFE7228', // Tangerine
  'colour:FF66B6FE', // Sky
  'colour:FF5FD3B5', // Mint
  'gradient:berry',
  'colour:FFFE607C', // Bubblegum
  'colour:FFF7BC33', // Sun
  'gradient:aurora',
  'colour:FF7877E6', // Lavender
  'colour:FF83C236', // Lime
];

// MARK: Keys

/// A background by a stable key: `colour:AARRGGBB`, `gradient:<id>` or
/// `photo:<path>`. Used for the Look tab row, recents and the sheet.
String colourKey(Color c) =>
    'colour:${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
String gradientKey(String id) => 'gradient:$id';
String photoKey(String path) => 'photo:$path';

/// The key of what [d] shows now.
String backgroundKeyOf(Countdown d) {
  if (d.hasPhoto) return photoKey(d.photoPath!);
  if (d.gradientId != null) return gradientKey(d.gradientId!);
  return colourKey(d.color);
}

enum BackgroundKind { colour, gradient, photo }

/// A parsed key.
typedef BackgroundRef = ({BackgroundKind kind, String value});

BackgroundRef? parseBackgroundKey(String key) {
  final i = key.indexOf(':');
  if (i < 0) return null;
  final value = key.substring(i + 1);
  return switch (key.substring(0, i)) {
    'colour' when int.tryParse(value, radix: 16) != null => (
      kind: BackgroundKind.colour,
      value: value,
    ),
    'gradient' when value.isNotEmpty => (
      kind: BackgroundKind.gradient,
      value: value,
    ),
    'photo' when value.isNotEmpty => (kind: BackgroundKind.photo, value: value),
    _ => null,
  };
}

Color colourFromKey(String value) => Color(int.parse(value, radix: 16));

/// The catalogue name for a colour, or null for a custom one.
String? colourName(Color c) =>
    palette.where((p) => p.color.toARGB32() == c.toARGB32()).firstOrNull?.name;

/// [d] with the background [key] applied. A colour or gradient clears any
/// photo; a gradient keeps the direction already chosen (or diagonal);
/// choosing a different photo starts its crops afresh. Unknown keys and
/// unknown gradient ids leave [d] as it is.
Countdown applyBackground(Countdown d, String key) {
  final ref = parseBackgroundKey(key);
  if (ref == null) return d;
  switch (ref.kind) {
    case BackgroundKind.colour:
      return d.copyWith(
        colorArgb: colourFromKey(ref.value).toARGB32(),
        gradientId: null,
        gradientDirection: null,
        photoPath: null,
      );
    case BackgroundKind.gradient:
      if (ref.value == legacyGradientId) {
        return d.copyWith(gradientId: legacyGradientId, photoPath: null);
      }
      final g = gradientById(ref.value);
      if (g == null) return d;
      return d.copyWith(
        colorArgb: g.colors.first.toARGB32(),
        gradientId: g.id,
        gradientDirection:
            d.gradientDirection ?? GradientDirection.diagonalDown,
        photoPath: null,
      );
    case BackgroundKind.photo:
      return d.copyWith(
        photoPath: ref.value,
        photoCrops: d.photoPath == ref.value
            ? d.photoCrops
            : const PhotoCrops(),
      );
  }
}

/// The Look tab's short row: up to [size] tiles, the first being "Add
/// photo" (not a key, so the keys returned number [size] - 1). In order:
/// photos (the current one first), the current colour or gradient, the
/// saved off-catalogue colour if any, recently used backgrounds, then
/// featured picks. No duplicates.
List<String> lookRowKeys({
  required Countdown draft,
  List<String> recentPhotos = const [],
  List<String> recentBackgrounds = const [],
  int? originalColor,
  int size = 12,
  int maxPhotos = 3,
}) {
  final keys = <String>[];
  void add(String key) {
    if (keys.length < size - 1 && !keys.contains(key)) keys.add(key);
  }

  for (final p in {?draft.photoPath, ...recentPhotos}.take(maxPhotos)) {
    add(photoKey(p));
  }
  if (!draft.hasPhoto) add(backgroundKeyOf(draft));
  if (originalColor != null && !isPaletteColor(originalColor)) {
    add(colourKey(Color(originalColor)));
  }
  for (final k in recentBackgrounds) {
    final ref = parseBackgroundKey(k);
    if (ref == null || ref.kind == BackgroundKind.photo) continue;
    if (ref.kind == BackgroundKind.gradient &&
        gradientById(ref.value) == null) {
      continue;
    }
    add(k);
  }
  for (final k in featuredBackgrounds) {
    add(k);
  }
  return keys;
}
