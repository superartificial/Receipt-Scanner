import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../features/receipt_storage/data/datasources/drift_datasource.dart';
import '../../features/receipt_storage/data/models/database.dart';
import '../../features/receipt_storage/data/repositories/receipt_repository_impl.dart';
import '../../features/receipt_storage/domain/repositories/receipt_repository.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

// Manual dependency registration
Future<void> setupDependencies() async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Data sources
  getIt.registerLazySingleton<ReceiptLocalDataSource>(
    () => ReceiptLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // Repositories
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(getIt<ReceiptLocalDataSource>()),
  );

  // Initialize injectable dependencies
  await configureDependencies();
}
