import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';

class BalanceCubit extends Cubit<int> {
  BalanceCubit({required TransactionsRepository transactionsRepository})
    : _subscription = transactionsRepository.watchBalance().listen(null),
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
