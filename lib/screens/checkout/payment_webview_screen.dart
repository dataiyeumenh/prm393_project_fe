import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Hosts the VNPay gateway inside the app instead of an external browser.
///
/// The merchant return redirect is intercepted before it loads: the vnp_*
/// result params are forwarded to the backend IPN endpoint so the order
/// status gets updated, then the screen pops with the `vnp_ResponseCode`
/// ('00' = paid successfully).
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            final isGateway = uri.host.endsWith('vnpayment.vn');
            final code = uri.queryParameters['vnp_ResponseCode'];
            // The merchant return redirect carries the payment result.
            if (!isGateway && code != null) {
              _completePayment(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // Fallback for non-SSL load failures (e.g. no network).
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _openExternally();
          },
          // Some Android system images don't yet trust ZeroSSL's ECC root
          // (the CA VNPay's sandbox cert chains to), even though the chain
          // itself is valid — verified independently via `openssl s_client`
          // (Verify return code: 0). Chrome trusts it via its own bundled
          // Chrome Root Store; embedded WebView instead relies on the OS
          // system CA store, which lags behind on some devices, and rejects
          // with CERT_AUTHORITY_INVALID. Keep WebView's own validation
          // intact (never silently proceed past a cert error) and fall back
          // to the external browser instead, which has its own up-to-date
          // trust store.
          onSslAuthError: (error) {
            error.cancel();
            _openExternally();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _openExternally() async {
    if (_finished) return;
    _finished = true;
    await launchUrl(
      Uri.parse(widget.paymentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (mounted) Navigator.of(context).pop(null);
  }

  /// Forwards the VNPay result to the backend IPN endpoint (its own IPN
  /// callback from VNPay can't reach it in this environment), then closes
  /// the screen with the response code.
  Future<void> _completePayment(Uri returnUri) async {
    if (_finished) return;
    _finished = true;
    final code = returnUri.queryParameters['vnp_ResponseCode'];
    try {
      await ApiService.dio.get(
        '/api/v1/payments/vnpay/ipn',
        queryParameters: returnUri.queryParameters,
      );
    } catch (_) {
      // Best-effort: the order status refresh will tell the real state.
    }
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text('VNPay', style: AppTypography.headingLg),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
