import 'package:PiliWind/pages/common/common_list_controller.dart';
import 'package:PiliWind/pages/common/multi_select/base.dart';

abstract class MultiSelectController<R, T extends MultiSelectData>
    extends CommonListController<R, T>
    with CommonMultiSelectMixin<T>, DeleteItemMixin {}
