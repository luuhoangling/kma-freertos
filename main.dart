import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống Giám sát An toàn',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Không dùng FirebaseAuth, chuyển thẳng sang LoginPage
    return LoginPage();
  }
}

class LoginPage extends StatefulWidget {
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
      // Truy vấn nhánh /account từ Firebase Realtime Database
      final snapshot =
          await FirebaseDatabase.instance
              .ref('/account')
              .orderByChild('username')
              .equalTo(_usernameController.text.trim())
              .once();

      if (snapshot.snapshot.exists) {
        final accounts = snapshot.snapshot.value as Map<dynamic, dynamic>;
        bool isAuthenticated = false;

        // Kiểm tra từng tài khoản
        accounts.forEach((key, value) {
          if (value['password'] == _passwordController.text.trim()) {
            isAuthenticated = true;
          }
        });

        if (isAuthenticated) {
          // Chuyển sang HomePage nếu xác thực thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
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
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 24),
                Text(
                  'Hệ thống Giám sát An toàn',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 8),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
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
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isConnected = true;
  DateTime? _lastUpdateTime;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkConnectionStatus();
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnectionStatus();
    });
  }

  void _checkConnectionStatus() {
    FirebaseDatabase.instance.ref('/system/lastUpdate').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _isConnected = true;
          _lastUpdateTime = DateTime.now();
        });
      }
    });

    if (_lastUpdateTime != null) {
      final difference = DateTime.now().difference(_lastUpdateTime!);
      if (difference.inSeconds > 10) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  void _signOut() {
    // Thay vì gọi FirebaseAuth.signOut(), chỉ điều hướng về LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hệ thống Giám sát An toàn'),
        actions: [
          ConnectionStatusIndicator(isConnected: _isConnected),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
            Tab(text: 'Điều khiển', icon: Icon(Icons.touch_app)),
            Tab(text: 'Cài đặt', icon: Icon(Icons.settings)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [DashboardPage(), ControlPage(), SettingsPage(), LogsPage()],
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
          SizedBox(width: 4),
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
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _gasValue = 0;
  int _flameValue = 0;
  bool _gasAlert = false;
  bool _flameAlert = false;
  int _systemState = 0;

  List<FlSpot> _gasSpots = [];
  List<FlSpot> _flameSpots = [];
  double _xValue = 0;
  Timer? _chartUpdateTimer;

  final _stateColors = {0: Colors.green, 1: Colors.orange, 2: Colors.red};

  final _stateNames = {0: 'Bình thường', 1: 'Báo động tạm thời', 2: 'Khẩn cấp'};

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();

    _chartUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  void _setupFirebaseListeners() {
    FirebaseDatabase.instance.ref('/sensors/gas_value').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _gasValue = (event.snapshot.value as int?) ?? 0;
        });
      }
    });

    FirebaseDatabase.instance.ref('/sensors/flame_value').onValue.listen((
      event,
    ) {
      if (event.snapshot.exists) {
        setState(() {
          _flameValue = (event.snapshot.value as int?) ?? 0;
        });
      }
    });

    FirebaseDatabase.instance.ref('/sensors/gas').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _gasAlert = (event.snapshot.value as bool?) ?? false;
        });
      }
    });

    FirebaseDatabase.instance.ref('/sensors/flame').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _flameAlert = (event.snapshot.value as bool?) ?? false;
        });
      }
    });

    FirebaseDatabase.instance.ref('/system/state').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _systemState = (event.snapshot.value as int?) ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _chartUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SystemStateCard(
            systemState: _systemState,
            stateColors: _stateColors,
            stateNames: _stateNames,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SensorCard(
                  title: 'Cảm biến khí gas',
                  value: _gasValue,
                  isAlert: _gasAlert,
                  icon: Icons.cloud,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SensorCard(
                  title: 'Cảm biến lửa',
                  value: _flameValue,
                  isAlert: _flameAlert,
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ dữ liệu theo thời gian thực',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _gasSpots,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue,
                              ], // Màu xanh đồng nhất
                            ),
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: _flameSpots,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange,
                                Colors.orange,
                              ], // Màu cam đồng nhất
                            ),
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Khí gas'),
                        ],
                      ),
                      SizedBox(width: 24),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text('Lửa'),
                        ],
                      ),
                    ],
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái hệ thống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
                SizedBox(width: 8),
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
      color: isAlert ? Color(0xFF2C1E1E) : null,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isAlert ? Colors.red : Colors.white),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (isAlert)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cảnh báo',
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
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool _isPumpOn = false;
  bool _isFanOn = false;
  bool _isChangingPump = false;
  bool _isChangingFan = false;
  int _currentSystemState = 0;
  bool _isChangingSystemState = false;

  @override
  void initState() {
    super.initState();
    _listenToDeviceStates();
  }

  void _listenToDeviceStates() {
    FirebaseDatabase.instance.ref('/control/pump').onValue.listen((event) {
      if (event.snapshot.exists) {
        final value = event.snapshot.value;
        if (value is int && value != -1) {
          setState(() {
            _isPumpOn = value == 1;
          });
        }
      }
    });

    FirebaseDatabase.instance.ref('/control/fan').onValue.listen((event) {
      if (event.snapshot.exists) {
        final value = event.snapshot.value;
        if (value is int && value != -1) {
          setState(() {
            _isFanOn = value == 1;
          });
        }
      }
    });

    FirebaseDatabase.instance.ref('/system/state').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _currentSystemState = (event.snapshot.value as int?) ?? 0;
        });
      }
    });
  }

  Future<void> _togglePump() async {
    if (_isChangingPump) return;

    setState(() {
      _isChangingPump = true;
    });

    try {
      await FirebaseDatabase.instance
          .ref('/control/pump')
          .set(_isPumpOn ? 0 : 1);
      setState(() {
        _isPumpOn = !_isPumpOn;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể điều khiển bơm: $e')));
    } finally {
      setState(() {
        _isChangingPump = false;
      });
    }
  }

  Future<void> _toggleFan() async {
    if (_isChangingFan) return;

    setState(() {
      _isChangingFan = true;
    });

    try {
      await FirebaseDatabase.instance.ref('/control/fan').set(_isFanOn ? 0 : 1);
      setState(() {
        _isFanOn = !_isFanOn;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể điều khiển quạt: $e')));
    } finally {
      setState(() {
        _isChangingFan = false;
      });
    }
  }

  Future<void> _changeSystemState(int newState) async {
    if (_isChangingSystemState) return;
    if (newState == _currentSystemState) return;

    if (newState == 2) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Xác nhận'),
              content: Text(
                'Bạn có chắc muốn chuyển hệ thống sang trạng thái KHẨN CẤP?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Xác nhận'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isChangingSystemState = true;
    });

    try {
      await FirebaseDatabase.instance.ref('/control/setState').set(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thay đổi trạng thái hệ thống: $e')),
        );
      }
    } finally {
      setState(() {
        _isChangingSystemState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateInfo = {
      0: {
        'name': 'Bình thường',
        'color': Colors.green,
        'description':
            'Hệ thống đang hoạt động bình thường, không có cảnh báo.',
      },
      1: {
        'name': 'Báo động tạm thời',
        'color': Colors.orange,
        'description':
            'Hệ thống phát hiện điều kiện bất thường nhưng chưa ở mức khẩn cấp.',
      },
      2: {
        'name': 'Khẩn cấp',
        'color': Colors.red,
        'description': 'Tình trạng nguy hiểm! Cần xử lý ngay lập tức.',
      },
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điều khiển trạng thái hệ thống',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Trạng thái hiện tại: ${stateInfo[_currentSystemState]?['name'] ?? 'Không xác định'}',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          stateInfo[_currentSystemState]?['color'] as Color? ??
                          Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    (stateInfo[_currentSystemState]?['description'] ?? '')
                        .toString(),
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  if (_isChangingSystemState)
                    Center(child: CircularProgressIndicator())
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _currentSystemState == 0
                                    ? null
                                    : () => _changeSystemState(0),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Bình thường'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _currentSystemState == 1
                                    ? null
                                    : () => _changeSystemState(1),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Báo động'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _currentSystemState == 2
                                    ? null
                                    : () => _changeSystemState(2),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Khẩn cấp'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điều khiển thiết bị',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Máy bơm', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _isPumpOn,
                        onChanged:
                            _isChangingPump ? null : (value) => _togglePump(),
                        activeColor: Colors.cyan,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quạt', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _isFanOn,
                        onChanged:
                            _isChangingFan ? null : (value) => _toggleFan(),
                        activeColor: Colors.cyan,
                      ),
                    ],
                  ),
                  if (_isChangingPump || _isChangingFan)
                    Padding(
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
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _gasThresholdController = TextEditingController();
  final _flameThresholdController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  void _loadThresholds() {
    FirebaseDatabase.instance.ref('/settings/gas_threshold').once().then((
      event,
    ) {
      if (event.snapshot.exists) {
        setState(() {
          _gasThresholdController.text = event.snapshot.value.toString();
        });
      }
    });

    FirebaseDatabase.instance.ref('/settings/flame_threshold').once().then((
      event,
    ) {
      if (event.snapshot.exists) {
        setState(() {
          _flameThresholdController.text = event.snapshot.value.toString();
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    if (_gasThresholdController.text.isEmpty ||
        _flameThresholdController.text.isEmpty) {
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
      await FirebaseDatabase.instance
          .ref('/settings/gas_threshold')
          .set(int.parse(_gasThresholdController.text.trim()));
      await FirebaseDatabase.instance
          .ref('/settings/flame_threshold')
          .set(int.parse(_flameThresholdController.text.trim()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu cài đặt thành công')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài đặt ngưỡng cảnh báo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _gasThresholdController,
                    decoration: InputDecoration(
                      labelText: 'Ngưỡng khí gas',
                      prefixIcon: Icon(Icons.cloud),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _flameThresholdController,
                    decoration: InputDecoration(
                      labelText: 'Ngưỡng lửa',
                      prefixIcon: Icon(Icons.local_fire_department),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text('Lưu cài đặt'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class LogsPage extends StatefulWidget {
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _isLoading = true;
    });

    FirebaseDatabase.instance.ref('/logs').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        List<Map<String, dynamic>> tempLogs = [];

        if (data != null) {
          data.forEach((key, value) {
            tempLogs.add({
              'timestamp': DateTime.fromMillisecondsSinceEpoch(int.parse(key)),
              'message': value['message'].toString(),
              'type': value['type'].toString(),
            });
          });

          tempLogs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        }

        setState(() {
          _logs = tempLogs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _logs = [];
          _isLoading = false;
        });
      }
    });
  }

  void _filterByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử sự kiện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  _filterByDate(pickedDate);
                },
                icon: Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate == null
                      ? 'Chọn ngày'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                  ? Center(child: Text('Không có lịch sử sự kiện'))
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: Icon(
                            log['type'] == 'alert'
                                ? Icons.warning
                                : log['type'] == 'control'
                                ? Icons.settings_remote
                                : Icons.info,
                            color:
                                log['type'] == 'alert'
                                    ? Colors.red
                                    : log['type'] == 'control'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          title: Text(log['message']),
                          subtitle: Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm:ss',
                            ).format(log['timestamp']),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
