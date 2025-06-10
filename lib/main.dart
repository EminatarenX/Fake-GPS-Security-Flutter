import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? _latitude;
  String? _longitude;
  bool? _isMockLocation;
  String _statusText = "Verificando permisos...";
  Color _statusColor = Colors.orange;
  bool _isLoading = true;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await requestLocationPermission();
    await startLocationDetection();
  }

  /// request location permission at runtime.
  Future<void> requestLocationPermission() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusText = "❌ Servicio de ubicación deshabilitado";
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusText = "❌ Permisos de ubicación denegados";
            _statusColor = Colors.red;
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusText = "❌ Permisos denegados permanentemente";
          _statusColor = Colors.red;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _statusText = "Iniciando detección GPS...";
      });
      print('permissions: granted');
    } catch (e) {
      setState(() {
        _statusText = "❌ Error solicitando permisos: $e";
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  /// start location detection with mock location check
  Future<void> startLocationDetection() async {
    try {
      // Usar un timer para obtener ubicación periódicamente
      _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
        await _getCurrentLocation();
      });
      
      // Primera lectura inmediata
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _statusText = "❌ Error iniciando detección: $e";
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude.toStringAsFixed(6);
        _longitude = position.longitude.toStringAsFixed(6);
        _isMockLocation = position.isMocked;
        _isLoading = false;
        
        if (_isMockLocation == true) {
          _statusText = "⚠️ FAKE GPS DETECTADO";
          _statusColor = Colors.red;
        } else {
          _statusText = "✅ GPS REAL";
          _statusColor = Colors.green;
        }
      });
    } on LocationServiceDisabledException {
      setState(() {
        _statusText = "❌ Servicio de ubicación deshabilitado";
        _statusColor = Colors.red;
        _isLoading = false;
      });
    } on PermissionDeniedException {
      setState(() {
        _statusText = "❌ Permisos de ubicación denegados";
        _statusColor = Colors.red;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = "❌ Error obteniendo ubicación: $e";
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCheck() async {
    setState(() {
      _isLoading = true;
      _statusText = "Verificando nuevamente...";
      _statusColor = Colors.orange;
    });
    
    _locationTimer?.cancel();
    await Future.delayed(Duration(milliseconds: 500));
    await _initializeLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Detector Fake GPS'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.location_on,
                  size: 80,
                  color: _statusColor,
                ),
                SizedBox(height: 30),
                if (_isLoading)
                  Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        _statusText,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      if (_latitude != null && _longitude != null)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Coordenadas:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Latitud: $_latitude',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              Text(
                                'Longitud: $_longitude',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Mock: ${_isMockLocation == true ? "SÍ" : "NO"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isMockLocation == true ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _refreshCheck,
                  child: Text('Verificar Nuevamente'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}