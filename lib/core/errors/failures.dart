import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// OCR failures
class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

// LLM failures
class LlmFailure extends Failure {
  const LlmFailure(super.message);
}

// Camera failures
class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

// File failures
class FileFailure extends Failure {
  const FileFailure(super.message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
