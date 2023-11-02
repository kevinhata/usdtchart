import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('USDT'),
        ),
        body: WebSocketWidget(),
      ),
    );
  }
}

class WebSocketWidget extends StatefulWidget {
  @override
  _WebSocketWidgetState createState() => _WebSocketWidgetState();
}

class _WebSocketWidgetState extends State<WebSocketWidget> {
  final channel = IOWebSocketChannel.connect(
      'wss://dev-api.hata.io/orderbook/ws/candles?symbol=USDTUSD&resolution=15');
  bool isWebSocketConnected = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();

    channel.stream.listen((data) {
      if (!isWebSocketConnected) {
        setState(() {
          isWebSocketConnected = true;
        });
      }

      updateChartWithDataFromWebSocket(data);
    });
  }

  void updateChartWithDataFromWebSocket(dynamic data) {
    if (_webViewController != null) {
      final script = 'updateChartWithWebSocketData($data);';
      _webViewController!.evaluateJavascript(script);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isWebSocketConnected
        ? ChartWebView(
            onWebViewCreated: (WebViewController controller) {
              _webViewController = controller;
            },
          )
        : Center(
            child: Text('Connecting to WebSocket...'),
          );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}

class ChartWebView extends StatelessWidget {
  final Function(WebViewController) onWebViewCreated;

  ChartWebView({required this.onWebViewCreated});
  final String tradingViewHtml = '''
  <!-- TradingView Widget BEGIN -->
    <div class="tradingview-widget-container">
      <div id="tradingview_33ada"></div>
      <div class="tradingview-widget-copyright">
        <a href="https://www.tradingview.com/" rel="noopener nofollow" target="_blank">
          <span class="blue-text">Track all markets on TradingView</span>
        </a>
      </div>
      <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
      <script type="text/javascript">
        var socket;

        new TradingView.widget({
          "width": 980,
          "height": 610,
          "symbol": "GEMINI:USDTUSD",
          "interval": "15",
          "timezone": "Asia/Jakarta",
          "theme": "dark",
          "style": "1",
          "locale": "en",
          "enable_publishing": false,
          "backgroundColor": "rgba(0, 0, 0, 1)",
          "gridColor": "rgba(0, 0, 0, 0.06",
          "allow_symbol_change": true,
          "container_id": "tradingview_33ada",
          "datafeed": {
            "onReady": function(callback) {
              // Connect to WebSocket
              socket = new WebSocket("wss://dev-api.hata.io/orderbook/ws/candles?symbol=USDTUSD&resolution=15");

              socket.onopen = function() {
                callback({
                  "supports_search": true,
                  "supports_group_request": false,
                  "supports_marks": true,
                  "supports_timescale_marks": true,
                  "supported_resolutions": ["15"],
                });
              };

              socket.onmessage = function(event) {
                var response = JSON.parse(event.data);

                var bars = [];

                for (var i = 0; i < response.length; i++) {
                  bars.push({
                    time: response[i].t, 
                    open: response[i].o, 
                    high: response[i].h, 
                    low: response[i].l,  
                    close: response[i].c,  
                    volume: response[i].v  
                  });
                }

              
                updateChartWithBars(bars);
              };
            },
            "resolveSymbol": function(symbolName, onSymbolResolvedCallback, onResolveErrorCallback) {
              // Symbol resolution logic
            },
          },
        });

        
        function updateChartWithBars(bars) {
          if (TradingView && TradingView.onRealtimeCallback) {
            TradingView.onRealtimeCallback(bars);
          }
        }

      </script>
    </div>
    <!-- TradingView Widget END -->
  ''';

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: '',
      javascriptMode: JavascriptMode.unrestricted,
      gestureNavigationEnabled: true,
      onWebViewCreated: (WebViewController webViewController) {
        webViewController.loadUrl(
          Uri.dataFromString(tradingViewHtml, mimeType: 'text/html').toString(),
        );
      },
    );
  }
}
