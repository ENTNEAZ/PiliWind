import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/http/video.dart';
import 'package:PiliWind/models/model_hot_video_item.dart';
import 'package:PiliWind/pages/common/common_list_controller.dart';
import 'package:PiliWind/utils/storage_pref.dart';
import 'package:get/get.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  final RxBool showHotRcmd = Pref.showHotRcmd.obs;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
