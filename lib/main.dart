import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/app_bloc_observer.dart';
import 'package:stockflow/core/service_locator.dart';
import 'package:stockflow/core/theme/app_theme.dart';
import 'package:stockflow/features/transactions/bloc/balance_cubit.dart';
import 'package:stockflow/features/categories/bloc/category_totals_cubit.dart';
import 'package:stockflow/features/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockFlow',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<TransactionsBloc>()),
          BlocProvider(create: (_) => getIt<BalanceCubit>()),
          BlocProvider(create: (_) => getIt<CategoryTotalsCubit>()),
        ],
        child: const TransactionsScreen(),
      ),
    );
  }
}
