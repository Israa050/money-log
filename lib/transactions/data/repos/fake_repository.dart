class FakeRepository {
  final List<String> _transactions = [];

  Future<List<String>> addTransaction(String item) async {
    return await Future.delayed(Duration(seconds: 2), () {
      _transactions.add(item);
      return _transactions;
    });
  }

  Future<List<String>> deleteTransaction(int id) {
    return Future.delayed(Duration(seconds: 6), () {
      _transactions.removeAt(id);
      return _transactions;
    });
  }

  Future<List<String>> getTransactions() {
    return Future.delayed(Duration(seconds: 2), () {
      return _transactions;
    });
  }
}
