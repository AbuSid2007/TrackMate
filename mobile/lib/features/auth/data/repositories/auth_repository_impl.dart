import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<Either<Failure, void>> register({
    required String email,
    required String password,
    required String fullName,
    required bool applyAsTrainer,
  }) async {
    try {
      await remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        applyAsTrainer: applyAsTrainer,
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final auth = await remoteDataSource.login(email: email, password: password);
      await tokenStorage.save(auth.tokens);
      return Right(_mapUser(auth.user));
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.verifyEmail(email: email, otp: otp);
      await tokenStorage.save(result.tokens);
      return Right(_mapUser(result.user));
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resendVerification({required String email}) async {
    try {
      await remoteDataSource.resendVerification(email: email);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await tokenStorage.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(_mapUser(user));
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> hasStoredSession() async => false;

  UserEntity _mapUser(UserModel model) => UserEntity(
        id: model.id,
        email: model.email,
        fullName: model.fullName,
        role: roleFromString(model.role),
        isActive: model.isActive,
        isVerified: model.isVerified,
      );
}