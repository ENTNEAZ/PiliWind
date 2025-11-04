import 'package:PiliWind/http/api.dart';
import 'package:PiliWind/http/init.dart';
import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/models_new/blacklist/data.dart';
import 'package:PiliWind/utils/accounts.dart';

class BlackHttp {
  static Future<LoadingState<BlackListData>> blackList({
    required int pn,
    int ps = 50,
  }) async {
    var res = await Request().get(
      Api.blackLst,
      queryParameters: {
        'pn': pn,
        'ps': ps,
        're_version': 0,
        'jsonp': 'jsonp',
        'csrf': Accounts.main.csrf,
      },
    );
    if (res.data['code'] == 0) {
      return Success(BlackListData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }
}
