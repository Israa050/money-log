import 'package:mocktail/mocktail.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class FakeTransaction extends Fake implements Transaction {}

class FakeTransactionsCompanion extends Fake implements TransactionsCompanion {}
