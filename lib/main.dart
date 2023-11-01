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
        body: TradingViewWidget(),
      ),
    );
  }
}

class TradingViewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              // WebSocket connection is ready
              var socket = new WebSocket("wss://dev-api.hata.io/orderbook/ws/candles?symbol=USDTUSD&resolution=15");

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
                    time: response[i].time,
                    open: response[i].open,
                    high: response[i].high,
                    low: response[i].low,
                    close: response[i].close,
                    volume: response[i].value,
                  });
                }

                callback({
                  "bars": bars,
                });
              };
            },
            "resolveSymbol": function(symbolName, onSymbolResolvedCallback, onResolveErrorCallback) {
              // Symbol resolution logic
            },
          },
        });
      </script>
    </div>
    <!-- TradingView Widget END -->
  ''';

    return Column(
      children: [
        Expanded(
          child: WebView(
            initialUrl: '',
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            onWebViewCreated: (WebViewController webViewController) {
              webViewController.loadUrl(
                Uri.dataFromString(tradingViewHtml, mimeType: 'text/html')
                    .toString(),
              );
            },
          ),
        ),
        WebSocketConnectionWidget(),
      ],
    );
  }
}

class WebSocketConnectionWidget extends StatefulWidget {
  @override
  _WebSocketConnectionWidgetState createState() =>
      _WebSocketConnectionWidgetState();
}

class _WebSocketConnectionWidgetState extends State<WebSocketConnectionWidget> {
  final channel = IOWebSocketChannel.connect(
      'wss://dev-api.hata.io/orderbook/ws/candles?symbol=USDTUSD&resolution=15');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: channel.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('WebSocket response: ${snapshot.data}');
        } else if (snapshot.hasError) {
          return Text('WebSocket error: ${snapshot.error}');
        } else {
          return Text('Connecting to WebSocket...');
        }
      },
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
