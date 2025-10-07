import 'dart:async';
import 'package:factory_appflutter_tank/mqtt/mqtt_manager.dart';
import 'package:factory_appflutter_tank/widgets/collapsible_cards.dart';
import 'package:factory_appflutter_tank/widgets/devices/device_kind.dart';
import 'package:factory_appflutter_tank/widgets/devices/oven.dart';
import 'package:factory_appflutter_tank/widgets/glass_card.dart';
import 'package:factory_appflutter_tank/widgets/hint_line.dart';
import 'package:factory_appflutter_tank/widgets/kpi_chip.dart';
import 'package:factory_appflutter_tank/widgets/neon_button.dart';
import 'package:factory_appflutter_tank/widgets/pid_fields.dart';
import 'package:factory_appflutter_tank/widgets/slider.dart';
import 'package:factory_appflutter_tank/widgets/devices/tank.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// >>> adição: importa o modelo Device
import 'package:factory_appflutter_tank/models/device.dart';

class DashboardScreen extends StatefulWidget {
  // >>> adição: recebe o device
  final Device device;

  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _prefsHost = 'mqttHost';
  static const _prefsPort = 'mqttPort';
  static const _prefsWs = 'mqttWs';
  static const _prefsBase = 'baseTopic';
  static const _prefsUser = 'mqttUser';
  static const _prefsPass = 'mqttPass';
  static const _prefsDevice = 'uiDevice';

  // command signals (adjust names if they differ on ESP/PLC)
  static const _cmdFill = 'Q_FillValve';
  static const _cmdDischarge = 'Q_DischargeValve';
  static const _cmdHeater = 'Q_Heater';

  final mqtt = MqttManager();
  StreamSubscription<RxMsg>? sub;
  String status = 'Disconnected';

  final st = TankState();

  // debounce helpers to avoid flooding PLC
  Timer? _debSP;

  // Error (SP - PV) in %  (negative: below SP, positive: above)
  double get _errPct => ((st.sp - st.pv) * 100).clamp(-100, 100);

  // --- OTA (UI only / simulated) ---
  String? _fwName;
  int? _fwBytes;
  double _otaProgress = 0.0;
  Timer? _otaTimer;
  bool _otaReboot = true;
  String _otaStatus = 'Select a firmware (.bin) to upload.';
  final List<String> _otaHistory = [];

  PidAdjustMode _pidMode = PidAdjustMode.custom;
  double _kp = 1.0, _ki = 0.10, _kd = 0.00;

  // Color by band (adjust bands if you want)
  Color _errColor() {
    final e = _errPct.abs();
    if (e <= 1.0) return Colors.greenAccent; // within ±1%
    if (e <= 3.0) return Colors.amberAccent; // slight deviation
    return Colors.redAccent; // high deviation
  }

  DeviceKind _device = DeviceKind.tank;

  int _toP100(double v) => (v.clamp(0.0, 1.0) * 10000).round();

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _connect());
  }

  @override
  void dispose() {
    _otaTimer?.cancel();
    sub?.cancel();
    mqtt.disconnect(disposeControllers: true); // fecha controllers só aqui
    _debSP?.cancel();
    super.dispose();
  }

  void _pickFirmwareMock() {
    // Simulates picking a .bin. If you want, change to randomize names/versions.
    setState(() {
      _fwName = 'firmware_v1.2.3.bin';
      _fwBytes = 356784; // ~348 KB (fake)
      _otaStatus = 'File selected. Ready to upload.';
      _otaProgress = 0.0;
    });
  }

  void _startFakeOta() {
    if (_fwName == null || _otaTimer != null) return;
    setState(() {
      _otaStatus = 'Uploading firmware...';
      _otaProgress = 0.02;
    });

    // Simulate upload: 120ms per “tick”
    _otaTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      setState(() {
        _otaProgress += 0.04; // ~3s — adjust if you want
        if (_otaProgress >= 1.0) {
          _otaProgress = 1.0;
          t.cancel();
          _otaTimer = null;
          final when = TimeOfDay.now();
          _otaStatus = _otaReboot
              ? 'Update finished. Rebooting...'
              : 'Update finished.';
          _otaHistory.insert(
            0,
            '${when.format(context)} • ${_fwName ?? 'firmware.bin'} • ${_formatBytes(_fwBytes ?? 0)}',
          );
        }
      });
    });
  }

  void _cancelFakeOta() {
    _otaTimer?.cancel();
    _otaTimer = null;
    setState(() {
      _otaStatus = 'Upload cancelled.';
      _otaProgress = 0.0;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    mqtt.host = p.getString(_prefsHost) ?? mqtt.host;
    mqtt.port = p.getInt(_prefsPort) ?? (kIsWeb ? 9001 : 1883);
    mqtt.useWebSocket = p.getBool(_prefsWs) ?? mqtt.useWebSocket;
    mqtt.baseTopic = p.getString(_prefsBase) ?? mqtt.baseTopic;
    mqtt.username = p.getString(_prefsUser) ?? '';
    mqtt.password = p.getString(_prefsPass) ?? '';

    final idx = p.getInt(_prefsDevice);
    if (idx != null && idx >= 0 && idx < DeviceKind.values.length) {
      _device = DeviceKind.values[idx];
    }
    setState(() {});
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsHost, mqtt.host);
    await p.setInt(_prefsPort, mqtt.port);
    await p.setBool(_prefsWs, mqtt.useWebSocket);
    await p.setString(_prefsBase, mqtt.baseTopic);
    await p.setString(_prefsUser, mqtt.username);
    await p.setString(_prefsPass, mqtt.password);
  }

  Future<void> _connect() async {
    setState(() => status = 'Connecting…');
    try {
      await mqtt.connect();
      sub?.cancel();
      sub = mqtt.messages.listen(_onMqttMsg);

      // Subscribe to everything (includes status/esp)
      mqtt.subscribeAll();

      // Try initial snapshot (if retained already comes, this just reinforces)
      final ok = await mqtt.requestInitialSnapshot();
      setState(() {
        status = ok ? 'Connected' : 'Connected (waiting for ESP…)';
      });
    } catch (e) {
      setState(() => status = 'Failed to connect');
    }
  }

  void _onMqttMsg(RxMsg m) {
    st.applyTele(m.topic, m.payload, mqtt);

    // Update local PID fields when ESP publishes
    if (m.topic == mqtt.tTeleKp) {
      final v = double.tryParse(m.payload);
      if (v != null) _kp = v;
    } else if (m.topic == mqtt.tTeleKi) {
      final v = double.tryParse(m.payload);
      if (v != null) _ki = v;
    } else if (m.topic == mqtt.tTeleKd) {
      final v = double.tryParse(m.payload);
      if (v != null) _kd = v;
    }

    if (mounted) setState(() {});
  }

  void _pubSP(double v) {
    st.sp = v;
    _debSP?.cancel();
    _debSP = Timer(const Duration(milliseconds: 150), () {
      mqtt.publishString(mqtt.tCmdSP, _toP100(st.sp).toString());
    });
    setState(() {});
  }

  void _pubMode(bool auto) {
    st.auto = auto;
    mqtt.publishString(mqtt.tCmdMode, auto ? '1' : '0');
    setState(() {});
  }

  void _cmd(String signal, bool on) {
    mqtt.publishString('${mqtt.baseTopic}/cmd/$signal', on ? '1' : '0');
  }

  void _openSettings() {
    final hostCtrl = TextEditingController(text: mqtt.host);
    final portCtrl = TextEditingController(text: mqtt.port.toString());
    final baseCtrl = TextEditingController(text: mqtt.baseTopic);
    final userCtrl = TextEditingController(text: mqtt.username);
    final passCtrl = TextEditingController(text: mqtt.password);
    bool ws = mqtt.useWebSocket;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(89, 0, 0, 0),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MQTT Settings',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Host (e.g., 192.168.0.10)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: portCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: baseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Base topic (e.g., cell1)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SwitchListTile(
                      value: ws,
                      onChanged: (v) => ws = v,
                      title: const Text('WebSocket'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'User (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              neonButton(
                context: context,
                label: 'SAVE & CONNECT',
                icon: Icons.cloud_done_rounded,
                onPressed: () async {
                  mqtt.host = hostCtrl.text.trim();
                  mqtt.port = int.tryParse(portCtrl.text.trim()) ?? mqtt.port;
                  mqtt.useWebSocket = ws;
                  mqtt.baseTopic = baseCtrl.text.trim().isEmpty
                      ? mqtt.baseTopic
                      : baseCtrl.text.trim();
                  mqtt.username = userCtrl.text.trim();
                  mqtt.password = passCtrl.text;
                  await _savePrefs();
                  if (mounted) Navigator.pop(context);
                  await _connect();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDeviceKind(DeviceKind d) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsDevice, d.index);
  }

  Future<void> _applyPidPublish() async {
    await mqtt.publishString(
      mqtt.tCmdKp,
      _kp.toStringAsFixed(4),
      retained: true,
    );
    await mqtt.publishString(
      mqtt.tCmdKi,
      _ki.toStringAsFixed(4),
      retained: true,
    );
    await mqtt.publishString(
      mqtt.tCmdKd,
      _kd.toStringAsFixed(4),
      retained: true,
    );
  }

  void _openDeviceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA0B0F14),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Switch device view',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                children: DeviceKind.values.map((d) {
                  final selected = d == _device;
                  return InkWell(
                    onTap: () {
                      setState(() => _device = d);
                      _saveDeviceKind(d);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.cyanAccent : Colors.white24,
                          width: selected ? 2.2 : 1.2,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF141A1F), Color(0xFF0F1317)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black54,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(d.icon, color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.cyanAccent,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          status,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Reconnect',
            onPressed: () async {
              setState(() => status = 'Reconnecting…');
              await mqtt.reconnect(); // <- em vez de disconnect()+connect()
              mqtt.subscribeAll();

              final ok = await mqtt.requestInitialSnapshot();
              if (!mounted) return;
              setState(() {
                status = ok
                    ? 'Synchronized'
                    : mqtt.isConnected
                    ? 'No response from ESP'
                    : 'No connection to broker';
              });
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0F14), Color(0xFF141A1F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 126, 16, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOP: Tank visualization
                      CollapsibleCard(
                        title: _device.label,
                        storageKey: 'visual_${_device.name}',
                        child: Column(
                          children: [
                            SwitcherPill(
                              icon: _device.icon,
                              label: 'Change device',
                              onTap: _openDeviceSelector,
                            ),
                            const SizedBox(height: 18),

                            SizedBox(height: 250, child: _buildVisualization()),

                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                // Generic KPIs — rename according to type
                                if (_device == DeviceKind.tank) ...[
                                  KpiChip(
                                    'PV',
                                    '${(st.pv * 100).toStringAsFixed(1)}%',
                                  ),
                                  KpiChip(
                                    'SP',
                                    '${(st.sp * 100).toStringAsFixed(1)}%',
                                  ),
                                ] else ...[
                                  KpiChip(
                                    'Temp',
                                    '${(st.pv * 300).toStringAsFixed(0)} °C',
                                  ),
                                  KpiChip(
                                    'SP',
                                    '${(st.sp * 300).toStringAsFixed(0)} °C',
                                  ),
                                ],
                                KpiChip(
                                  'Error',
                                  '${_errPct >= 0 ? '+' : ''}${_errPct.toStringAsFixed(1)}%',
                                  tint: _errColor(),
                                ),
                                KpiChip('Mode', st.auto ? 'AUTO' : 'MAN'),
                                if (st.auto)
                                  KpiChip(
                                    'Preset',
                                    const ['Cons', 'Std', 'Agr'][st.preset],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // MIDDLE: Controls (Mode, Preset, SP/Manual Out + Manual Shortcuts)
                      CollapsibleCard(
                        title: 'Control',
                        storageKey: 'controle',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LayoutBuilder(
                              builder: (context, c) {
                                final narrow = c.maxWidth < 720;

                                final modo = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mode'),
                                    const SizedBox(height: 8),
                                    // give a minimum width to avoid breaking "Auto / Manual"
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 220,
                                      ),
                                      child: SegmentedButton<bool>(
                                        showSelectedIcon: false,
                                        segments: const [
                                          ButtonSegment(
                                            value: true,
                                            label: Text('Auto'),
                                          ),
                                          ButtonSegment(
                                            value: false,
                                            label: Text('Manual'),
                                          ),
                                        ],
                                        selected: {st.auto},
                                        onSelectionChanged: (s) =>
                                            _pubMode(s.first),
                                      ),
                                    ),
                                  ],
                                );

                                final ajuste = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    const Text('PID Adjustment'),
                                    const SizedBox(height: 16),
                                    if (_pidMode == PidAdjustMode.custom)
                                      PidFields(
                                        kp: _kp,
                                        ki: _ki,
                                        kd: _kd,
                                        onApply: (kp, ki, kd) async {
                                          setState(() {
                                            _kp = kp;
                                            _ki = ki;
                                            _kd = kd;
                                          });
                                          await _applyPidPublish(); // <<< publicação real
                                        },
                                      ),
                                  ],
                                );

                                if (narrow) {
                                  // stack everything
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      modo,
                                      const SizedBox(height: 12),
                                      ajuste,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: modo),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: ajuste),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Main control: AUTO => SP, MANUAL => Output
                            if (st.auto)
                              ValueSlider(
                                title: 'Setpoint',
                                value: st.sp,
                                min: 0,
                                max: 1,
                                onChanged: (v) => _pubSP(v),
                              ),

                            // === shortcuts appear only in MANUAL ===
                            if (!st.auto) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: _buildManualShortcuts(),
                              ),
                            ],

                            const SizedBox(height: 8),

                            HintLine(
                              text: st.auto
                                  ? (_device == DeviceKind.tank
                                        ? 'AUTO: the PID adjusts the valve to keep the level at the setpoint.'
                                        : 'AUTO: the PID controls the heater to keep the temperature at the setpoint.')
                                  : (_device == DeviceKind.tank
                                        ? 'MANUAL: adjust the output (%) or use Fill/Empty.'
                                        : 'MANUAL: adjust the output (%) or use On/Off.'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildOtaCard(),

                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        children: [
                          KpiChip(
                            'Broker',
                            mqtt.isConnected ? 'ONLINE' : 'OFF',
                            tint: mqtt.isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          KpiChip(
                            'ESP',
                            mqtt.espOnline ? 'ONLINE' : 'OFF',
                            tint: mqtt.espOnline
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Broker: ${mqtt.host}:${mqtt.port}  •  ${mqtt.useWebSocket ? "WS" : "TCP"}  •  Base: ${mqtt.baseTopic}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtaCard() {
    final hasFile = _fwName != null;
    final uploading = _otaTimer != null;

    return CollapsibleCard(
      title: 'Update (OTA)',
      storageKey: 'ota',
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 420; // stack rows
          final btnRowWrap = c.maxWidth < 360; // wrap buttons

          // file selection row: becomes a column when narrow
          Widget _filePickerLine() {
            final infoText = Text(
              hasFile
                  ? '${_fwName!} • ${_formatBytes(_fwBytes ?? 0)}'
                  : 'No file selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: uploading ? null : _pickFirmwareMock,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select firmware (.bin)'),
                  ),
                  const SizedBox(height: 8),
                  infoText,
                ],
              );
            }
            return Row(
              children: [
                ElevatedButton.icon(
                  onPressed: uploading ? null : _pickFirmwareMock,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select firmware (.bin)'),
                ),
                const SizedBox(width: 12),
                Expanded(child: infoText),
              ],
            );
          }

          // options: switch + dropdown; on narrow screens becomes a column
          Widget _options() {
            final drop = DropdownButtonFormField<String>(
              value: 'Auto',
              items: const [
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                DropdownMenuItem(value: 'Slot A', child: Text('Slot A')),
                DropdownMenuItem(value: 'Slot B', child: Text('Slot B')),
              ],
              onChanged: uploading ? null : (_) {},
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                // use hint instead of floating label to avoid clipping
                hintText: 'Partition',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            );

            final sw = SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _otaReboot,
              onChanged: uploading
                  ? null
                  : (v) => setState(() => _otaReboot = v),
              title: const Text('Force reboot after update'),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sw,
                  const SizedBox(height: 8),
                  drop, // full width when narrow
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sw),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: drop),
              ],
            );
          }

          // actions: auto-wrap when space is tight
          Widget _actions() {
            final children = <Widget>[
              ElevatedButton.icon(
                onPressed: (hasFile && !uploading) ? _startFakeOta : null,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload'),
              ),
              OutlinedButton.icon(
                onPressed: uploading ? _cancelFakeOta : null,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
              TextButton.icon(
                onPressed: (!uploading && hasFile)
                    ? () => setState(
                        () => _otaStatus =
                            'Validation OK: signature and size match (simulated).',
                      )
                    : null,
                icon: const Icon(Icons.verified),
                label: const Text('Validate'),
              ),
            ];

            if (btnRowWrap) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: children,
              );
            }
            return Row(
              children: [
                children[0],
                const SizedBox(width: 8),
                children[1],
                const Spacer(),
                children[2],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filePickerLine(),
              const SizedBox(height: 12),
              _options(),
              const SizedBox(height: 12),

              if (_otaProgress > 0) ...[
                LinearProgressIndicator(value: _otaProgress),
                const SizedBox(height: 8),
              ],
              Text(_otaStatus, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),

              _actions(),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Update history',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (_otaHistory.isEmpty)
                const Text(
                  'No records yet.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                Column(
                  children: _otaHistory.take(5).map((e) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.history,
                        size: 18,
                        color: Colors.white54,
                      ),
                      title: Text(e),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildManualShortcuts() {
    switch (_device) {
      case DeviceKind.tank:
        return [
          ElevatedButton.icon(
            onPressed: () => _cmd(_cmdFill, !st.filling),
            icon: const Icon(Icons.water_drop),
            label: Text(st.filling ? 'Stop Filling' : 'Fill'),
          ),
          ElevatedButton.icon(
            onPressed: () => _cmd(_cmdDischarge, !st.discharging),
            icon: const Icon(Icons.water),
            label: Text(st.discharging ? 'Stop Emptying' : 'Empty'),
          ),
        ];

      case DeviceKind.forno:
        return [
          ElevatedButton.icon(
            onPressed: () => _cmd(_cmdHeater, true),
            icon: const Icon(Icons.power_settings_new),
            label: Text('Turn Off'),
          ),
        ];
    }
  }

  Widget _buildVisualization() {
    switch (_device) {
      case DeviceKind.tank:
        return FancyTank(
          level: st.pv,
          filling: st.filling,
          discharging: st.discharging,
        );
      case DeviceKind.forno:
        const tempMax = 300.0;
        final temp = (st.pv.clamp(0.0, 1.0) * tempMax);
        final setp = (st.sp.clamp(0.0, 1.0) * tempMax);
        return FancyOven(temperature: temp, setpoint: setp, heating: true);
    }
  }
}
