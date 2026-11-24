import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swvertex_camera_projector/features/spaces/space.dart';
import 'package:swvertex_camera_projector/features/spaces/spaces_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aucun Space au départ', () async {
    final service = const SpacesService();
    expect(await service.list(), isEmpty);
  });

  test('créer, renommer puis supprimer un Space', () async {
    final service = const SpacesService();
    final space = await service.create('Salon');
    expect((await service.list()).map((s) => s.name), ['Salon']);

    await service.rename(space.id, 'Bureau');
    expect((await service.list()).single.name, 'Bureau');

    await service.delete(space.id);
    expect(await service.list(), isEmpty);
  });

  test('ajouter un membre puis le retirer', () async {
    final service = const SpacesService();
    final space = await service.create('Salon');
    const member = SpaceMember(name: 'PC du salon', lastAddress: '192.168.1.10', lastPairPort: 54321);

    await service.addMember(space.id, member);
    var reloaded = (await service.list()).single;
    expect(reloaded.members, [member]);

    await service.removeMember(space.id, member.key);
    reloaded = (await service.list()).single;
    expect(reloaded.members, isEmpty);
  });

  test('ajouter le même membre deux fois ne le duplique pas', () async {
    final service = const SpacesService();
    final space = await service.create('Salon');
    const member = SpaceMember(name: 'PC du salon', lastAddress: '192.168.1.10', lastPairPort: 1);
    const sameMemberNewPort = SpaceMember(name: 'PC du salon', lastAddress: '192.168.1.10', lastPairPort: 2);

    await service.addMember(space.id, member);
    await service.addMember(space.id, sameMemberNewPort);

    final reloaded = (await service.list()).single;
    expect(reloaded.members.length, 1);
    expect(reloaded.members.single.lastPairPort, 2);
  });

  test('persiste réellement via SharedPreferences (relecture depuis une nouvelle instance)', () async {
    final service = const SpacesService();
    await service.create('Salon');

    final otherInstance = const SpacesService();
    expect((await otherInstance.list()).map((s) => s.name), ['Salon']);
  });
}
