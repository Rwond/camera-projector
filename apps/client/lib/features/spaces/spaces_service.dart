import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'space.dart';

const _storageKey = 'swvertex.spaces.v1';

/// Persistance locale (SharedPreferences, pas de secret ici) des Spaces de
/// cet appareil. Un Space ne vit sur aucun backend : il n'existe que sur
/// l'appareil qui l'a créé, voir spaces_tab.dart pour l'avertissement affiché
/// à l'utilisateur.
class SpacesService {
  const SpacesService();

  Future<List<Space>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Space.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Space> create(String name) async {
    final spaces = await list();
    final space = Space(id: _newId(), name: name, members: const []);
    await _save([...spaces, space]);
    return space;
  }

  Future<void> rename(String spaceId, String newName) async {
    final spaces = await list();
    await _save([
      for (final s in spaces) if (s.id == spaceId) s.copyWith(name: newName) else s,
    ]);
  }

  Future<void> delete(String spaceId) async {
    final spaces = await list();
    await _save(spaces.where((s) => s.id != spaceId).toList());
  }

  Future<void> addMember(String spaceId, SpaceMember member) async {
    final spaces = await list();
    await _save([
      for (final s in spaces)
        if (s.id == spaceId)
          s.copyWith(
            members: [
              ...s.members.where((m) => m.key != member.key),
              member,
            ],
          )
        else
          s,
    ]);
  }

  Future<void> removeMember(String spaceId, String memberKey) async {
    final spaces = await list();
    await _save([
      for (final s in spaces)
        if (s.id == spaceId)
          s.copyWith(members: s.members.where((m) => m.key != memberKey).toList())
        else
          s,
    ]);
  }

  Future<void> _save(List<Space> spaces) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(spaces.map((s) => s.toJson()).toList()));
  }

  String _newId() {
    final rand = Random();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }
}
