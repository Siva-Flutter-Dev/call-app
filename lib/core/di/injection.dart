import 'package:get_it/get_it.dart';

import '../../features/call/data/datasource/quickbox_datasource.dart';
import '../../features/call/data/repository/call_repository_impl.dart';

import '../../features/call/domain/repository/call_repository.dart';

import '../../features/call/domain/usecases/login_usecase.dart';
import '../../features/call/domain/usecases/start_call_usecase.dart';
import '../../features/call/domain/usecases/accept_call_usecase.dart';
import '../../features/call/domain/usecases/reject_call_usecase.dart';
import '../../features/call/domain/usecases/hangup_call_usecase.dart';

import '../../features/call/presentation/bloc/auth/auth_bloc.dart';
import '../../features/call/presentation/bloc/call/call_bloc.dart';

import '../../features/call/presentation/bloc/control/call_control_bloc.dart';
import '../../features/chat/data/repository/chat_repository_impl.dart';
import '../../features/chat/domain/repository/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../services/callkit_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

final sl = GetIt.instance;

Future<void> initInjection() async {
  /// Services

  sl.registerLazySingleton(
        () => PermissionService(),
  );

  sl.registerLazySingleton(
        () => CallKitService(),
  );

  sl.registerLazySingleton(
        () => NotificationService(),
  );

  /// Datasource

  sl.registerLazySingleton(
        () => QuickBloxDataSource(
      sl(),
    ),
  );

  /// Repository

  sl.registerLazySingleton<CallRepository>(
        () => CallRepositoryImpl(
      sl(),
    ),
  );

  /// UseCases

  sl.registerLazySingleton(
        () => LoginUseCase(
      sl(),
    ),
  );

  sl.registerLazySingleton(
        () => StartCallUseCase(
      sl(),
    ),
  );

  sl.registerLazySingleton(
        () => AcceptCallUseCase(
      sl(),
    ),
  );

  sl.registerLazySingleton(
        () => RejectCallUseCase(
      sl(),
    ),
  );

  sl.registerLazySingleton(
        () => HangupCallUseCase(
      sl(),
    ),
  );

  /// Bloc

  sl.registerFactory(
        () => AuthBloc(
      loginUseCase: sl(),
      repository: sl(),
    ),
  );

  sl.registerFactory(
        () => CallBloc(
      repository: sl(),
      callKitService: sl(),
    ),
  );

  sl.registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(
      sl(),
    ),
  );

  sl.registerFactory(
        () => ChatBloc(
      repository: sl(),
    ),
  );
}