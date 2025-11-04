import 'package:PiliWind/grpc/bilibili/app/viewunite/v1.pb.dart'
    show ViewReq, ViewReply;
import 'package:PiliWind/grpc/grpc_req.dart';
import 'package:PiliWind/grpc/url.dart';
import 'package:PiliWind/http/loading_state.dart';

class ViewGrpc {
  static Future<LoadingState<ViewReply>> view({
    required String bvid,
  }) {
    return GrpcReq.request(
      GrpcUrl.view,
      ViewReq(
        bvid: bvid,
      ),
      ViewReply.fromBuffer,
    );
  }
}
