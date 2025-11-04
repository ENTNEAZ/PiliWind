import 'package:PiliWind/http/dynamics.dart';
import 'package:PiliWind/http/loading_state.dart';
import 'package:PiliWind/models/model_owner.dart';
import 'package:PiliWind/models_new/article/article_list/article.dart';
import 'package:PiliWind/models_new/article/article_list/data.dart';
import 'package:PiliWind/models_new/article/article_list/list.dart';
import 'package:PiliWind/pages/common/common_list_controller.dart';
import 'package:get/get.dart';

class ArticleListController
    extends CommonListController<ArticleListData, ArticleListItemModel> {
  final id = Get.parameters['id'];

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Rx<ArticleListInfo?> list = Rx<ArticleListInfo?>(null);
  Owner? author;

  @override
  List<ArticleListItemModel>? getDataList(ArticleListData response) {
    list.value = response.list;
    author = response.author;
    return response.articles;
  }

  @override
  Future<LoadingState<ArticleListData>> customGetData() =>
      DynamicsHttp.articleList(id: id);
}
