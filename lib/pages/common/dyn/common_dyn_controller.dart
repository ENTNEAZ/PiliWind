import 'package:PiliWind/grpc/bilibili/main/community/reply/v1.pb.dart';
import 'package:PiliWind/grpc/reply.dart';
import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/pages/common/reply_controller.dart';
import 'package:PiliWind/utils/storage_pref.dart';
import 'package:get/get.dart';

abstract class CommonDynController extends ReplyController<MainListReply> {
  int get oid;
  int get replyType;

  late final RxBool showTitle = false.obs;

  late final horizontalPreview = Pref.horizontalPreview;
  late final List<double> ratio = Pref.dynamicDetailRatio;

  @override
  Future<LoadingState<MainListReply>> customGetData() => ReplyGrpc.mainList(
    type: replyType,
    oid: oid,
    mode: mode.value,
    cursorNext: cursorNext,
    offset: paginationReply?.nextOffset,
  );

  @override
  List<ReplyInfo>? getDataList(MainListReply response) {
    return response.replies;
  }
}
