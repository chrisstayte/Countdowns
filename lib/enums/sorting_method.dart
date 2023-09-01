import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SortingMethod {
  alphaAscending,
  alphaDescending,
  dateAscending,
  dateDescending,
}

extension SortingMethodExtension on SortingMethod {
  String get nameReadable {
    switch (this) {
      case SortingMethod.alphaAscending:
        return 'Alphabetical';
      case SortingMethod.alphaDescending:
        return 'Alphabetical Reversed';
      case SortingMethod.dateAscending:
        return 'Soonest First';
      case SortingMethod.dateDescending:
        return 'Latest First';
    }
  }

  IconData get icon {
    switch (this) {
      case SortingMethod.alphaAscending:
        return FontAwesomeIcons.arrowDownAZ;
      case SortingMethod.alphaDescending:
        return FontAwesomeIcons.arrowDownZA;
      case SortingMethod.dateAscending:
        return FontAwesomeIcons.arrowDown19;
      case SortingMethod.dateDescending:
        return FontAwesomeIcons.arrowDown91;
    }
  }
}
