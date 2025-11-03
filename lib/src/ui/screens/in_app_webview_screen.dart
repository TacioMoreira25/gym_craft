import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppWebViewScreen extends StatefulWidget {
  final Uri uri;
  final String? title;
  final bool captureImageTap;

  const InAppWebViewScreen({
    super.key,
    required this.uri,
    this.title,
    this.captureImageTap = true,
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _injected = false;

  @override
  void initState() {
    super.initState();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ImageChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          if (!mounted) return;
          final src = message.message;
          if (src.isNotEmpty) {
            Navigator.of(context).pop<String>(src);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _progress = progress / 100.0);
          },
          onPageStarted: (url) {},
          onPageFinished: (url) {
            if (widget.captureImageTap && !_injected) {
              _injected = true;
              const String js = '''(function(){
                function send(src){ try { ImageChannel.postMessage(src); } catch(e) {} }
                document.addEventListener('click', function(e){
                  var t = e.target;
                  if (t && t.tagName && t.tagName.toLowerCase() === 'img' && t.src){
                    e.preventDefault(); e.stopPropagation();
                    var src = t.src || t.getAttribute('data-src') || '';
                    if(!src && t.srcset){
                      var parts = (t.srcset||'').split(',');
                      if(parts.length){ src = parts[0].trim().split(' ')[0]; }
                    }
                    if (src) { send(src); }
                  }
                }, true);
              })();''';
              try {
                _controller.runJavaScript(js);
              } catch (_) {}
            }
          },
          onWebResourceError: (error) {
            // Keep it minimal; user can go back
          },
        ),
      )
      ..loadRequest(widget.uri);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Navegador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = await _controller.currentUrl();
              if (!context.mounted || url == null) return;
              // Optionally: attempt external launch from here if desired.
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 1.0
              ? LinearProgressIndicator(
                  value: _progress,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: Column(
        children: [
          if (widget.captureImageTap)
            Container(
              width: double.infinity,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toque na imagem para selecionar o link (inclui GIFs).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SafeArea(child: WebViewWidget(controller: _controller)),
          ),
        ],
      ),
    );
  }
}
