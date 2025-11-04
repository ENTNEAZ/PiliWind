import 'package:PiliWind/models/model_video.dart';
import 'package:hive/hive.dart';

part 'model_owner.g.dart';

@HiveType(typeId: 3)
class Owner implements BaseOwner {
  Owner({
    this.mid,
    this.name,
    this.face,
  });
  @HiveField(0)
  @override
  int? mid;
  @HiveField(1)
  @override
  String? name;
  @HiveField(2)
  String? face;

  Owner.fromJson(Map<String, dynamic> json) {
    final dynamic midValue = json["mid"];
    if (midValue is int) {
      mid = midValue;
    } else if (midValue is String) {
      mid = int.tryParse(midValue);
    } else if (midValue is num) {
      mid = midValue.toInt();
    } else {
      mid = null;
    }
    name = json["name"];
    face = json['face'];
  }
}
