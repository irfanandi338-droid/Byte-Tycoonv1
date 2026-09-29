import '../config/game_config.dart';

class ResearchState {
  final Set<String> completed;

  ResearchState(this.completed);

  bool isDone(String id) => completed.contains(id);
  bool isUnlocked(ResearchDef def) => def.requires == null || completed.contains(def.requires);

  Map<String, dynamic> toJson() => {'completed': completed.toList()};

  factory ResearchState.fromJson(Map<String, dynamic>? j) {
    final set = <String>{};
    (j?['completed'] as List?)?.forEach((e) => set.add(e.toString()));
    return ResearchState(set);
  }
}
