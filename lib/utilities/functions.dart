int numberOfDaysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

int numberOfSecondsBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day, from.second);
  to = DateTime(to.year, to.month, to.day, to.second);
  return (to.difference(from).inSeconds);
}
