import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/http/user.dart';
import 'package:PiliWind/models_new/follow/data.dart';
import 'package:PiliWind/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
