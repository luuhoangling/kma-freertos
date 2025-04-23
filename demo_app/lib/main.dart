import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hệ thống phòng cháy chữa cháy hộ gia đình',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref('/account')
              .orderByChild('username')
              .equalTo(_usernameController.text.trim())
              .once();

      if (snapshot.snapshot.exists) {
        final accounts = snapshot.snapshot.value as Map<dynamic, dynamic>;
        bool isAuthenticated = false;

        accounts.forEach((key, value) {
          if (value['password'] == _passwordController.text.trim()) {
            isAuthenticated = true;
          }
        });

        if (isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          setState(() {
            _errorMessage = 'Tên đăng nhập hoặc mật khẩu không đúng';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Tên đăng nhập không tồn tại';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.cyan),
                const SizedBox(height: 24),
                const Text(
                  'Hệ thống phòng cháy chữa cháy hộ gia đình',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isConnected = true;
  DateTime? _lastUpdateTime;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Thay đổi length thành 3
    _checkConnectionStatus();
  }

  void _checkConnectionStatus() {
    _connectionSubscription = FirebaseDatabase.instance
        .ref('/system/lastUpdate')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            try {
              if (event.snapshot.exists) {
                setState(() {
                  _isConnected = true;
                  _lastUpdateTime = DateTime.now();
                });
              } else {
                setState(() {
                  _isConnected = false;
                });
              }
            } catch (e) {
              print('Error in connection listener: $e');
            }
          },
          onError: (e) {
            print('Connection listener error: $e');
            if (mounted) {
              setState(() {
                _isConnected = false;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _signOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          ConnectionStatusIndicator(isConnected: _isConnected),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
            Tab(text: 'Điều khiển', icon: Icon(Icons.touch_app)),
            Tab(
              text: 'Cài đặt',
              icon: Icon(Icons.settings),
            ), // Thêm tab Cài đặt
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardPage(),
          ControlPage(),
          SettingsPage(), // Thêm SettingPage
        ],
      ),
    );
  }
}

class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusIndicator({Key? key, required this.isConnected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 18,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _gasValue = 0;
  int _flameValue = 0;
  bool _gasAlert = false;
  bool _flameAlert = false;
  int _systemState = 0;

  final List<FlSpot> _gasSpots = [];
  final List<FlSpot> _flameSpots = [];
  Timer? _chartUpdateTimer;
  StreamSubscription? _gasValueSubscription;
  StreamSubscription? _flameValueSubscription;
  StreamSubscription? _gasAlertSubscription;
  StreamSubscription? _flameAlertSubscription;
  StreamSubscription? _systemStateSubscription;

  final _stateColors = const {0: Colors.green, 1: Colors.orange, 2: Colors.red};
  final _stateNames = const {
    0: 'Bình thường',
    1: 'Có bất thường',
    2: 'Khẩn cấp',
  };

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();
    _startChartUpdates();
  }

  void _setupFirebaseListeners() {
    _gasValueSubscription = FirebaseDatabase.instance
        .ref('/sensors/gas_value')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _gasValue = (event.snapshot.value as int?) ?? 0;
              });
            }
          } catch (e) {
            print('Error in gas_value listener: $e');
          }
        }, onError: (e) => print('Gas value listener error: $e'));

    _flameValueSubscription = FirebaseDatabase.instance
        .ref('/sensors/flame_value')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _flameValue = (event.snapshot.value as int?) ?? 0;
              });
            }
          } catch (e) {
            print('Error in flame_value listener: $e');
          }
        }, onError: (e) => print('Flame value listener error: $e'));

    _gasAlertSubscription = FirebaseDatabase.instance
        .ref('/sensors/gas')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _gasAlert = (event.snapshot.value as bool?) ?? false;
              });
            }
          } catch (e) {
            print('Error in gas_alert listener: $e');
          }
        }, onError: (e) => print('Gas alert listener error: $e'));

    _flameAlertSubscription = FirebaseDatabase.instance
        .ref('/sensors/flame')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _flameAlert = (event.snapshot.value as bool?) ?? false;
              });
            }
          } catch (e) {
            print('Error in flame_alert listener: $e');
          }
        }, onError: (e) => print('Flame alert listener error: $e'));

    _systemStateSubscription = FirebaseDatabase.instance
        .ref('/system/state')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _systemState = (event.snapshot.value as int?) ?? 0;
              });
            }
          } catch (e) {
            print('Error in system_state listener: $e');
          }
        }, onError: (e) => print('System state listener error: $e'));
  }

  void _startChartUpdates() {
    _chartUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      if (_gasSpots.length > 30) {
        setState(() {
          _gasSpots.removeAt(0);
          _flameSpots.removeAt(0);
          for (int i = 0; i < _gasSpots.length; i++) {
            _gasSpots[i] = FlSpot(i.toDouble(), _gasSpots[i].y);
            _flameSpots[i] = FlSpot(i.toDouble(), _flameSpots[i].y);
          }
        });
      }

      setState(() {
        _gasSpots.add(
          FlSpot(
            _gasSpots.isEmpty ? 0 : _gasSpots.length.toDouble(),
            _gasValue.toDouble(),
          ),
        );
        _flameSpots.add(
          FlSpot(
            _flameSpots.isEmpty ? 0 : _flameSpots.length.toDouble(),
            _flameValue.toDouble(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _chartUpdateTimer?.cancel();
    _gasValueSubscription?.cancel();
    _flameValueSubscription?.cancel();
    _gasAlertSubscription?.cancel();
    _flameAlertSubscription?.cancel();
    _systemStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SystemStateCard(
            systemState: _systemState,
            stateColors: _stateColors,
            stateNames: _stateNames,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SensorCard(
                  title: 'Gas',
                  value: _gasValue,
                  isAlert: _gasAlert,
                  icon: Icons.cloud,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SensorCard(
                  title: 'Lửa',
                  value: _flameValue,
                  isAlert: _flameAlert,
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Biểu đồ dữ liệu cảm biến theo thời gian thực',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _gasSpots,
                    isCurved: true,
                    color: Colors.cyan,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: _flameSpots,
                    isCurved: true,
                    color: Colors.red,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          // Thêm phần chú thích (legend) cho biểu đồ
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chú thích cho gas
              Row(
                children: [
                  Icon(Icons.cloud, color: Colors.cyan, size: 20),
                  const SizedBox(width: 4),
                  const Text('Gas', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(width: 24),
              // Chú thích cho lửa
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  const Text('Lửa', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SystemStateCard extends StatelessWidget {
  final int systemState;
  final Map<int, Color> stateColors;
  final Map<int, String> stateNames;

  const SystemStateCard({
    Key? key,
    required this.systemState,
    required this.stateColors,
    required this.stateNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = stateColors[systemState] ?? Colors.grey;
    final stateName = stateNames[systemState] ?? 'Không xác định';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái hệ thống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stateName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final int value;
  final bool isAlert;
  final IconData icon;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.isAlert,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: isAlert ? const Color(0xFF2C1E1E) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isAlert ? Colors.red : Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '!!!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool _isPumpOn = false;
  bool _isFanOn = false;
  bool _isChangingPump = false;
  bool _isChangingFan = false;
  int _systemState = 0;
  bool _isChangingSystemState = false;
  bool _isLoadingSystemState = true;

  StreamSubscription? _systemStateSubscription;
  StreamSubscription? _pumpSubscription;
  StreamSubscription? _fanSubscription;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();
  }

  void _setupFirebaseListeners() {
    _systemStateSubscription = FirebaseDatabase.instance
        .ref('/system/state')
        .onValue
        .listen(
          (event) {
            try {
              if (event.snapshot.exists && mounted) {
                setState(() {
                  _systemState = (event.snapshot.value as int?) ?? 0;
                  _isLoadingSystemState = false;
                });
              }
            } catch (e) {
              print('Error in system_state listener: $e');
            }
          },
          onError: (e) {
            print('System state listener error: $e');
            if (mounted) {
              setState(() {
                _isLoadingSystemState = false;
              });
            }
          },
        );

    _pumpSubscription = FirebaseDatabase.instance
        .ref('/control/pump')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _isPumpOn = (event.snapshot.value as int?) == 1;
              });
            }
          } catch (e) {
            print('Error in pump listener: $e');
          }
        }, onError: (e) => print('Pump listener error: $e'));

    _fanSubscription = FirebaseDatabase.instance
        .ref('/control/fan')
        .onValue
        .listen((event) {
          try {
            if (event.snapshot.exists && mounted) {
              setState(() {
                _isFanOn = (event.snapshot.value as int?) == 1;
              });
            }
          } catch (e) {
            print('Error in fan listener: $e');
          }
        }, onError: (e) => print('Fan listener error: $e'));
  }

  Future<void> _toggleSystemState(int newValue) async {
    if (_isChangingSystemState) return;

    if (newValue == 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text(
                'Bạn có chắc muốn chuyển hệ thống sang trạng thái KHẨN CẤP?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isChangingSystemState = true;
    });

    try {
      await FirebaseDatabase.instance
          .ref('/control/setState')
          .set(newValue)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thay đổi trạng thái hệ thống: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSystemState = false;
        });
      }
    }
  }

  Future<void> _togglePump() async {
    if (_isChangingPump) return;

    setState(() {
      _isChangingPump = true;
      _isPumpOn = !_isPumpOn;
    });

    try {
      await FirebaseDatabase.instance
          .ref('/control/pump')
          .set(_isPumpOn ? 1 : 0)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPumpOn = !_isPumpOn;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể điều khiển bơm: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPump = false;
        });
      }
    }
  }

  Future<void> _toggleFan() async {
    if (_isChangingFan) return;

    setState(() {
      _isChangingFan = true;
      _isFanOn = !_isFanOn;
    });

    try {
      await FirebaseDatabase.instance
          .ref('/control/fan')
          .set(_isFanOn ? 1 : 0)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFanOn = !_isFanOn;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể điều khiển quạt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingFan = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _systemStateSubscription?.cancel();
    _pumpSubscription?.cancel();
    _fanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateInfo = const {
      0: {
        'name': 'Tự động',
        'color': Colors.green,
        'description':
            'Tự động kiểm tra cảm biến và đưa ra các phản hồi tương ứng.',
      },
      1: {
        'name': 'Tự động',
        'color': Colors.green,
        'description':
            'Tự động kiểm tra cảm biến và đưa ra các phản hồi tương ứng.',
      },
      2: {
        'name': 'Khẩn cấp',
        'color': Colors.red,
        'description':
            'Chế độ khẩn cấp, hệ thống bật bơm, quạt, còi cho đến khi chế độ khẩn cấp được tắt.',
      },
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều khiển hệ thống',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingSystemState
                      ? const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 8),
                            Text('Đang tải trạng thái...'),
                          ],
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái hiện tại: ${stateInfo[_systemState]?['name'] ?? 'Không xác định'}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  stateInfo[_systemState]?['color'] as Color? ??
                                  Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stateInfo[_systemState]?['description']
                                    .toString() ??
                                '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                onTap:
                                    _isChangingSystemState
                                        ? null
                                        : () => _toggleSystemState(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _systemState == 0
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                    border: Border.all(
                                      color:
                                          _systemState == 0
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Tự động',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _systemState == 0
                                              ? Colors.green
                                              : Colors.grey,
                                      fontWeight:
                                          _systemState == 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap:
                                    _isChangingSystemState
                                        ? null
                                        : () => _toggleSystemState(1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _systemState == 2
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                    border: Border.all(
                                      color:
                                          _systemState == 2
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Khẩn cấp',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _systemState == 2
                                              ? Colors.red
                                              : Colors.grey,
                                      fontWeight:
                                          _systemState == 2
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isChangingSystemState)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều khiển thiết bị',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Máy bơm', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _isPumpOn,
                        onChanged:
                            _isChangingPump ? null : (value) => _togglePump(),
                        activeColor: Colors.cyan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quạt', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _isFanOn,
                        onChanged:
                            _isChangingFan ? null : (value) => _toggleFan(),
                        activeColor: Colors.cyan,
                      ),
                    ],
                  ),
                  if (_isChangingPump || _isChangingFan)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _gasThresholdController = TextEditingController();
  final _flameThresholdController = TextEditingController();
  final _alarmCheckDelayController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String _currentGasThreshold = 'Đang tải...';
  String _currentFlameThreshold = 'Đang tải...';
  String _currentAlarmCheckDelay = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  void _loadThresholds() {
    FirebaseDatabase.instance
        .ref('/system/config/thresholds/gas')
        .once()
        .then((event) {
          if (event.snapshot.exists && mounted) {
            setState(() {
              final value = event.snapshot.value.toString();
              _gasThresholdController.text = value;
              _currentGasThreshold = value;
            });
          } else {
            setState(() {
              _currentGasThreshold = 'null';
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _currentGasThreshold = 'Lỗi: $e';
            });
          }
        });

    FirebaseDatabase.instance
        .ref('/system/config/thresholds/flame')
        .once()
        .then((event) {
          if (event.snapshot.exists && mounted) {
            setState(() {
              final value = event.snapshot.value.toString();
              _flameThresholdController.text = value;
              _currentFlameThreshold = value;
            });
          } else {
            setState(() {
              _currentFlameThreshold = 'null';
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _currentFlameThreshold = 'Lỗi: $e';
            });
          }
        });

    FirebaseDatabase.instance
        .ref('/system/config/alarmCheckDelay')
        .once()
        .then((event) {
          if (event.snapshot.exists && mounted) {
            setState(() {
              final value = event.snapshot.value.toString();
              _alarmCheckDelayController.text = value;
              _currentAlarmCheckDelay = '$value ms';
            });
          } else {
            setState(() {
              _currentAlarmCheckDelay = 'null';
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _currentAlarmCheckDelay = 'Lỗi: $e';
            });
          }
        });
  }

  Future<void> _saveSettings() async {
    if (_gasThresholdController.text.isEmpty ||
        _flameThresholdController.text.isEmpty ||
        _alarmCheckDelayController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ các ngưỡng';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final gasThreshold = int.parse(_gasThresholdController.text.trim());
      final flameThreshold = int.parse(_flameThresholdController.text.trim());
      final alarmCheckDelay = int.parse(_alarmCheckDelayController.text.trim());

      await FirebaseDatabase.instance
          .ref('/system/config/thresholds/gas')
          .set(gasThreshold);
      await FirebaseDatabase.instance
          .ref('/system/config/thresholds/flame')
          .set(flameThreshold);
      await FirebaseDatabase.instance
          .ref('/system/config/alarmCheckDelay')
          .set(alarmCheckDelay);

      setState(() {
        _currentGasThreshold = gasThreshold.toString();
        _currentFlameThreshold = flameThreshold.toString();
        _currentAlarmCheckDelay = '$alarmCheckDelay ms';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lưu cài đặt thành công',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Lưu cài đặt thất bại: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gasThresholdController.dispose();
    _flameThresholdController.dispose();
    _alarmCheckDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text('Cài đặt hệ thống'),
      //   centerTitle: true,
      //   backgroundColor: Colors.grey[850],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ ghi chú về ngưỡng cảnh báo
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              color: Colors.amber[700],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Lưu ý: Muốn tăng mức cảnh báo của cảm biến khí GAS phải tăng giá trị ngưỡng. Giá trị càng cao thì độ nhạy càng thấp.\nCảm biến LỬA thì ngược lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card chính chứa các cài đặt
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt ngưỡng cảnh báo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phần cảm biến gas
                    _buildSectionTitle('Cảm biến gas'),
                    _buildCurrentValueRow(
                      'Ngưỡng hiện tại:',
                      _currentGasThreshold,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _gasThresholdController,
                      decoration: InputDecoration(
                        labelText: 'Nhập ngưỡng mới',
                        prefixIcon: const Icon(Icons.cloud),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Giá trị từ 0-1023',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // Phần cảm biến lửa
                    _buildSectionTitle('Cảm biến lửa'),
                    _buildCurrentValueRow(
                      'Ngưỡng hiện tại:',
                      _currentFlameThreshold,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _flameThresholdController,
                      decoration: InputDecoration(
                        labelText: 'Nhập ngưỡng mới',
                        prefixIcon: const Icon(Icons.local_fire_department),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Giá trị từ 0-1023',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // Phần thời gian chữa cháy
                    _buildSectionTitle('Thời gian chữa cháy tự động'),
                    _buildCurrentValueRow(
                      'Thời gian hiện tại:',
                      _currentAlarmCheckDelay,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _alarmCheckDelayController,
                      decoration: InputDecoration(
                        labelText: 'Nhập thời gian mới (ms)',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Đơn vị: mili giây',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    // Hiển thị lỗi nếu có
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Nút lưu cài đặt
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 66,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'LƯU CÀI ĐẶT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildCurrentValueRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: value.startsWith('Lỗi') ? Colors.red : Colors.white,
          ),
        ),
      ],
    );
  }
}
