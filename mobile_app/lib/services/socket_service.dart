// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class SocketService {
//   SocketService._internal();
//   static final SocketService _instance = SocketService._internal();
//   factory SocketService() => _instance;

//   IO.Socket? socket;

//   bool get isConnected => socket?.connected ?? false;

//   void connect({required String baseUrl, required String token}) {
//     // kalau udah connect, skip
//     if (socket != null && isConnected) return;

//     // bersihin socket lama kalau ada
//     socket?.disconnect();
//     socket?.dispose();

//     socket = IO.io(
//       baseUrl,
//       IO.OptionBuilder()
//           .setTransports(['websocket', 'polling'])
//           .disableAutoConnect()
//           .setAuth({'token': token})
//           .build(),
//     );

//     socket!.onConnect((_) {
//       print("✅ [socket] connected -> $baseUrl");
//       print("✅ [socket] id: ${socket!.id}");
//     });

//     socket!.onDisconnect((_) => print("🧯 [socket] disconnected"));
//     socket!.onConnectError((err) => print("❌ [socket] connect_error: $err"));
//     socket!.onError((err) => print("❌ [socket] error: $err"));

//     socket!.connect();
//   }

//   void on(String event, Function(dynamic) handler) {
//     socket?.on(event, handler);
//   }

//   void off(String event) {
//     socket?.off(event);
//   }

//   void emit(String event, dynamic data) {
//     socket?.emit(event, data);
//   }

//   void joinCommunity(int communityId) {
//     socket?.emit('community:join', {'communityId': communityId});
//   }

//   void leaveCommunity(int communityId) {
//     socket?.emit('community:leave', {'communityId': communityId});
//   }

//   void disconnect() {
//     socket?.disconnect();
//     socket?.dispose();
//     socket = null;
//   }
// }

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;

  String? _currentBaseUrl;
  String? _currentToken;

  bool get isConnected => socket?.connected ?? false;

  void connect({required String baseUrl, required String token}) {
    final sameConnection =
        _currentBaseUrl == baseUrl &&
        _currentToken == token &&
        socket != null &&
        isConnected;

    // kalau benar-benar koneksi yang sama, baru skip
    if (sameConnection) {
      print("ℹ️ [socket] already connected with same token/baseUrl");
      return;
    }

    // kalau token/baseUrl beda, wajib reconnect
    socket?.disconnect();
    socket?.dispose();
    socket = null;

    _currentBaseUrl = baseUrl;
    _currentToken = token;

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.onConnect((_) {
      print("✅ [socket] connected -> $baseUrl");
      print("✅ [socket] id: ${socket!.id}");
    });

    socket!.onDisconnect((reason) {
      print("🧯 [socket] disconnected: $reason");
    });

    socket!.onConnectError((err) {
      print("❌ [socket] connect_error: $err");
    });

    socket!.onError((err) {
      print("❌ [socket] error: $err");
    });

    socket!.connect();
  }

  void on(String event, Function(dynamic) handler) {
    socket?.off(event); // cegah listener dobel
    socket?.on(event, handler);
  }

  void addListener(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void joinCommunity(int communityId) {
    socket?.emit('community:join', {'communityId': communityId});
  }

  void leaveCommunity(int communityId) {
    socket?.emit('community:leave', {'communityId': communityId});
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _currentBaseUrl = null;
    _currentToken = null;
  }
}
