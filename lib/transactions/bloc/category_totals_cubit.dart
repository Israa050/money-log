import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/domain/entities/category_total_entity.dart';
import 'package:stockflow/transactions/domain/usecases/watch_category_totals_usecase.dart';

class CategoryTotalsCubit extends Cubit<List<CategoryTotalEntity>> {
  CategoryTotalsCubit({required WatchCategoryTotalsUsecase watchCategoryTotals})
    : _subscription = watchCategoryTotals.watchCategoryTotals().listen(null),
      super(const []) {
    _subscription.onData(emit);
  }

  final StreamSubscription<List<CategoryTotalEntity>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
