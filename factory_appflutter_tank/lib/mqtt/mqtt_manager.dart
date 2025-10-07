import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum ConnEvent { connecting, connected, disconnected, reconnecting, espSeen }

class MqttManager {
  MqttServerClient? _client;
  StreamSubscription? _sub;
  final _msgCtrl = StreamController<RxMsg>.broadcast();
  bool _connecting = false;
  String host = '192.168.1.23';
  int port = 1883;
  bool useWebSocket = kIsWeb;
  String baseTopic = 'cell1';
  String username = '';
  String password = '';
  int keepAliveSec = 30;

  // topic helpers (all under baseTopic)
  String get tStateFill => '$baseTopic/state/Q_FillValve';
  String get tStateDischarge => '$baseTopic/state/Q_DischargeValve';
  String get tStateDisplay => '$baseTopic/state/Q_Display'; // (0..32767)

  // New PID/tank telemetry topics (PLC → HMI)
  String get tTelePV => '$baseTopic/tele/PV'; // 0..10000 (% * 100)
  String get tTeleSP => '$baseTopic/tele/SP'; // 0..10000
  String get tTeleMode => '$baseTopic/tele/Mode'; // 0=Manual,1=Auto

  // New command topics (HMI → PLC)
  String get tCmdSP => '$baseTopic/cmd/SP';
  String get tCmdMode => '$baseTopic/cmd/Mode'; // 0/1

  // --- PID telemetry (ESP → App)
  String get tTeleKp => '$baseTopic/tele/PID/Kp'; // ex.: "1.0000"
  String get tTeleKi => '$baseTopic/tele/PID/Ki';
  String get tTeleKd => '$baseTopic/tele/PID/Kd';

  // --- PID commands (App → ESP)
  String get tCmdKp => '$baseTopic/cmd/PID/Kp';
  String get tCmdKi => '$baseTopic/cmd/PID/Ki';
  String get tCmdKd => '$baseTopic/cmd/PID/Kd';

  String get tEspStatus =>
      '$baseTopic/status/esp'; // 'online'/'offline' (retido)
  String get tEspUptime => '$baseTopic/tele/uptime'; // opcional heartbeat
  String get tCmdSync => '$baseTopic/cmd/Sync';

  DateTime? _espLastSeen;
  Duration get espStaleAfter => Duration(seconds: keepAliveSec * 2);

  bool get espOnline =>
      _espLastSeen != null &&
      DateTime.now().difference(_espLastSeen!) < espStaleAfter;

  Stream<RxMsg> get messages => _msgCtrl.stream;
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  final _connCtrl = StreamController<ConnEvent>.broadcast();
  Stream<ConnEvent> get connectionEvents => _connCtrl.stream;

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;
    try {
      _client?.disconnect();
    } catch (_) {}

    _client = MqttServerClient(
      host,
      'hmi_${DateTime.now().millisecondsSinceEpoch}',
    );
    final c = _client!;
    c.port = port;
    c.keepAlivePeriod = keepAliveSec;
    c.logging(on: false);
    c.useWebSocket = useWebSocket;
    c.secure = false;
    c.autoReconnect = true;
    c.resubscribeOnAutoReconnect = true;

    c.onConnected = () => _connCtrl.add(ConnEvent.connected);
    c.onDisconnected = () => _connCtrl.add(ConnEvent.disconnected);
    c.onAutoReconnect = () => _connCtrl.add(ConnEvent.reconnecting);
    c.onAutoReconnected = () => _connCtrl.add(ConnEvent.connected);
    c.pongCallback = () {}; // só p/ saber que o keepAlive tá ok

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(c.clientIdentifier)
        .keepAliveFor(keepAliveSec)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    c.connectionMessage = connMsg;

    _connCtrl.add(ConnEvent.connecting);

    try {
      await c.connect(
        username.isEmpty ? null : username,
        password.isEmpty ? null : password,
      );

      // listener único para todas as mensagens
      _sub = c.updates!.listen((events) {
        for (final e in events) {
          final rec = e.payload as MqttPublishMessage;
          final topic = e.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            rec.payload.message,
          );

          // presença do ESP (status/esp ou heartbeat)
          if (topic == tEspStatus || topic == tEspUptime) {
            _espLastSeen = DateTime.now();
            _connCtrl.add(ConnEvent.espSeen);
          }

          _msgCtrl.add(RxMsg(topic, payload));
        }
      });
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect({bool disposeControllers = false}) async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;

    // só feche controllers se for encerrar de vez (ex.: no dispose da tela)
    if (disposeControllers) {
      try {
        await _msgCtrl.close();
      } catch (_) {}
      try {
        await _connCtrl.close();
      } catch (_) {}
    }
  }

  Future<void> reconnect() async {
    await disconnect(); // mantém controllers abertos
    await connect();
  }

  void subscribe(String topic) {
    if (!isConnected) return;
    _client?.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unsubscribe(String topic) {
    if (!isConnected) return;
    _client?.unsubscribe(topic);
  }

  Future<void> publishString(
    String topic,
    String payload, {
    bool retained = false,
  }) async {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    print('enviando $payload para $topic');
    _client?.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retained,
    );
  }

  void subscribeAll() {
    if (!isConnected) return;
    // legacy
    subscribe(tStateFill);
    subscribe(tStateDischarge);
    subscribe(tStateDisplay);
    // tele
    subscribe(tTelePV);
    subscribe(tTeleSP);
    subscribe(tTeleMode);
    // PID gains
    subscribe(tTeleKp);
    subscribe(tTeleKi);
    subscribe(tTeleKd);
    // presença do ESP
    subscribe(tEspStatus);
    subscribe(tEspUptime);
  }

  Future<bool> requestInitialSnapshot({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return false;

    final needed = <String>{tTeleMode, tTeleSP, tTeleKp, tTeleKi, tTeleKd};

    final completer = Completer<bool>();
    late final StreamSubscription subLocal;

    subLocal = messages.listen((m) {
      if (needed.remove(m.topic) && needed.isEmpty && !completer.isCompleted) {
        completer.complete(true);
        subLocal.cancel();
      }
    });

    await publishString(
      tCmdSync,
      '1',
    ); // seu ESP deve publicar todos os tele/...

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        subLocal.cancel();
        return false;
      },
    );
  }
}

class RxMsg {
  RxMsg(this.topic, this.payload);
  final String topic;
  final String payload;
}
