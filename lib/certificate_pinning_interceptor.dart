import 'dart:async';

import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class CertificatePinningInterceptor extends Interceptor {
  final List<String> _allowedSHAFingerprints;

  CertificatePinningInterceptor(this._allowedSHAFingerprints);

  Future isWorking = Completer().future;
  bool isInProgress = false;

  @override
  Future onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    synchronized(options, handler);
  }

  Future synchronized(RequestOptions options, RequestInterceptorHandler handler) async {
    if (isInProgress) {
      await isWorking; // wait for future complete
      return synchronized(options, handler);
    }
    isInProgress = true;
    var completer = Completer();
    isWorking = completer.future;
    
    var secure;
    try {
      secure = await HttpCertificatePinning.check(
          serverURL: options.baseUrl,
          headerHttp: options.headers.map((a, b) => MapEntry(a, b.toString())),
          sha: SHA.SHA256,
          allowedSHAFingerprints: _allowedSHAFingerprints,
          timeout: 50);
    } catch (e, s) {
      print(e);
      secure = "CONNECTION_SECURE";
    }
    // unlock
    completer.complete();
    isInProgress = false;

    if (secure.contains("CONNECTION_SECURE")) {
      return super.onRequest(options, handler);
    } else {
      throw Exception("CONNECTION_NOT_SECURE");
    }
  }
}
