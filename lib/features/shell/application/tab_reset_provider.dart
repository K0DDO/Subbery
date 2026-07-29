import 'package:flutter_riverpod/flutter_riverpod.dart';

final tabResetRevisionProvider = StateProvider.family<int, int>(
  (ref, branchIndex) => 0,
);
