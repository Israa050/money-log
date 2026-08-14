import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/domain/usecases/watch_balance_usecase.dart';

class BalanceCubit extends Cubit<int> {
  BalanceCubit({required WatchBalanceUseCase watchBalanceUseCase})
    : _subscription = watchBalanceUseCase().listen(null),
      super(0) {
    _subscription.onData(emit);
  }

  final StreamSubscription<int> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
