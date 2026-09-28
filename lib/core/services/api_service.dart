import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  Completer<String?>? _refreshCompleter;
  bool _isForceLoggingOut = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: ApiConstants.headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Token refresh interceptor — retries once with a new access token on 401
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Inject stored Bearer token if not already set
          final storage = _tryGetStorage();
          if (storage != null) {
            final token = storage.getString(StorageKeys.authToken) ?? '';
            if (token.isNotEmpty &&
                !(options.headers['Authorization'] as String? ?? '').startsWith(
                  'Bearer ',
                )) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // Inject Accept-Language header for i18n
            final lang = storage.getString(StorageKeys.selectedLanguage) ?? 'it';
            options.headers['Accept-Language'] = lang;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Skip token refresh for auth endpoints that naturally return 401
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/social-login');

          // A 401 on a request that carried no session is not an expired
          // session, it is an anonymous call to an authenticated endpoint.
          // Refreshing cannot help and force-logging-out is actively harmful:
          // it bounces a user who never signed in -- someone part-way through
          // registration, say -- to sign-in with a "session expired" toast,
          // discarding whatever they had typed.
          final sessionStore = _tryGetStorage();
          final hasSession = sessionStore != null &&
              ((sessionStore.getString(StorageKeys.refreshToken) ?? '')
                      .isNotEmpty ||
                  (sessionStore.getString(StorageKeys.authToken) ?? '')
                      .isNotEmpty);

          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              hasSession &&
              !(error.requestOptions.extra['_retried'] as bool? ?? false)) {
            error.requestOptions.extra['_retried'] = true;

            try {
              // If a refresh is already in progress, wait for it
              String? newToken;
              if (_refreshCompleter != null) {
                newToken = await _refreshCompleter!.future;
              } else {
                _refreshCompleter = Completer<String?>();
                try {
                  final result = await _refreshAccessToken();
                  _refreshCompleter!.complete(result);
                  newToken = result;
                } catch (e) {
                  _refreshCompleter!.complete(null);
                  newToken = null;
                } finally {
                  _refreshCompleter = null;
                }
              }

              if (newToken != null) {
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $newToken',
                  },
                  extra: error.requestOptions.extra,
                );
                final response = await _dio.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: opts,
                );
                return handler.resolve(response);
              } else {
                // Refresh token also expired — force logout
                _forceLogout();
                return handler.next(error);
              }
            } catch (e) {
              // Refresh failed — clear session and redirect to login
              _forceLogout();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: e,
                  type: DioExceptionType.unknown,
                ),
              );
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Pretty logging interceptor — only in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          compact: false,
        ),
      );
    }
  }

  /// Clears stored auth data, shows session-expired message, and redirects to sign-in.
  void _forceLogout() {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    final storage = _tryGetStorage();
    if (storage != null) {
      // Best-effort: deactivate push token on the server
      final fcmToken = storage.getString(StorageKeys.fcmToken) ?? '';
      if (fcmToken.isNotEmpty) {
        _dio.delete(ApiConstants.removePushToken(fcmToken)).ignore();
      }

      // Best-effort: revoke the refresh token on the server before clearing local state
      final refreshToken = storage.getString(StorageKeys.refreshToken) ?? '';
      if (refreshToken.isNotEmpty) {
        _dio.post(
          ApiConstants.authLogout,
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'_retried': true}),
        ).ignore();
      }

      storage.remove(StorageKeys.authToken);
      storage.remove(StorageKeys.refreshToken);
      storage.remove(StorageKeys.userId);
      storage.remove(StorageKeys.userEmail);
      storage.remove(StorageKeys.userName);
      storage.remove(StorageKeys.userRole);
      storage.remove(StorageKeys.fcmToken);
      storage.setBool(StorageKeys.isLoggedIn, false);
    }
    // Navigate to sign-in, clearing the entire back stack
    Get.offAllNamed('/sign_in_screen');
    // Show session expired message after navigation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.snackbar(
        'auth.session_expired.title'.tr,
        'auth.session_expired.message'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        icon: const Icon(Icons.logout, color: Colors.white),
      );
      _isForceLoggingOut = false;
    });
  }

  StorageService? _tryGetStorage() {
    try {
      return Get.find<StorageService>();
    } catch (_) {
      return null;
    }
  }

  /// Calls the refresh-token endpoint and stores + returns the new access token.
  /// Returns null if refresh fails.
  Future<String?> _refreshAccessToken() async {
    final storage = _tryGetStorage();
    if (storage == null) return null;

    final refreshToken = storage.getString(StorageKeys.refreshToken) ?? '';
    if (refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post(
        ApiConstants.authRefreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'_retried': true}), // prevent retry loop
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final accessToken = data?['accessToken'] as String?;
        final newRefresh = data?['refreshToken'] as String?;

        if (accessToken != null) {
          await storage.setString(StorageKeys.authToken, accessToken);
        }
        if (newRefresh != null) {
          await storage.setString(StorageKeys.refreshToken, newRefresh);
        }
        return accessToken;
      }
    } catch (_) {
      // Refresh endpoint itself failed
    }
    return null;
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

 
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

 
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  Future<Response> uploadFile(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({fieldName: file, ...?data});

      return await _dio.post(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  /// ```
  Future<Response> uploadMultipleFiles(
    String path, {
    required List<MultipartFile> files,
    String fieldName = 'files',
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({fieldName: files, ...?data});

      return await _dio.post(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  Future<Response> uploadFileWithProgress(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({fieldName: file, ...?data});

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(error.message);

      case DioExceptionType.connectionError:
        return NoInternetException(error.message);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        // Extract message from API response body first, fall back to HTTP status message
        String message = error.response?.statusMessage ?? 'Server error';
        final responseData = error.response?.data;
        Map<String, dynamic>? responseMap;
        if (responseData is Map<String, dynamic>) {
          responseMap = responseData;
          final apiMsg = responseData['message'];
          if (apiMsg is String && apiMsg.isNotEmpty) {
            message = apiMsg;
          } else if (apiMsg is List && apiMsg.isNotEmpty) {
            message = apiMsg.map((e) => e.toString()).join(', ');
          }
        }
        return ServerException(message, statusCode, error.message, responseMap);

      case DioExceptionType.cancel:
        return UnknownException('Request cancelled');

      case DioExceptionType.badCertificate:
        return ServerException('Bad certificate', null, error.message);

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return NoInternetException(error.message);
        }
        return UnknownException(error.message);
    }
  }

  void dispose() {
    _dio.close();
  }
}
