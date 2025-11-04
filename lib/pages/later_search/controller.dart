import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/http/user.dart';
import 'package:PiliWind/models_new/later/data.dart';
import 'package:PiliWind/models_new/later/list.dart';
import 'package:PiliWind/pages/common/multi_select/base.dart';
import 'package:PiliWind/pages/common/search/common_search_controller.dart';
import 'package:PiliWind/pages/later/controller.dart' show BaseLaterController;
import 'package:get/get.dart';

class LaterSearchController
    extends CommonSearchController<LaterData, LaterItemModel>
    with
        CommonMultiSelectMixin<LaterItemModel>,
        DeleteItemMixin,
        BaseLaterController {
  dynamic mid = Get.arguments['mid'];
  dynamic count = Get.arguments['count'];

  @override
  Future<LoadingState<LaterData>> customGetData() => UserHttp.seeYouLater(
    page: page,
    keyword: editController.value.text,
  );

  @override
  List<LaterItemModel>? getDataList(LaterData response) {
    return response.list;
  }
}
