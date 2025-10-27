import 'dart:convert';
import 'dart:io' show SocketException, Platform;
import 'dart:async' show TimeoutException;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Edit this if your backend is hosted elsewhere.
const String BASE_URL = 'http://localhost:3002';

// Effective base URL: for Android emulators 'localhost' should be replaced
// with 10.0.2.2. We keep `BASE_URL` as the editable constant above and
// automatically fall back when running on Android to help during development.
String get _effectiveBaseUrl {
  try {
    if (Platform.isAndroid && BASE_URL.contains('localhost')) {
      return BASE_URL.replaceFirst('localhost', '10.0.2.2');
    }
  } catch (_) {
    // Platform isn't available (e.g. web) — fall back to BASE_URL
  }
  return BASE_URL;
}

class SendMessagePage extends StatefulWidget {
  const SendMessagePage({super.key});

  @override
  State<SendMessagePage> createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  bool _loading = false;
  bool _sending = false;

  List<String> _pincodes = [];
  String? _selectedPincode;

  List<String> _areas = [];
  String? _selectedArea;

  List<String> _transformers = [];
  String? _selectedTransformer;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPincodes();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPincodes() async {
    setState(() => _loading = true);
    try {
      final url = '$_effectiveBaseUrl/pincodes';
      debugPrint('Fetching pincodes from: $url');
  final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      if (res.statusCode == 200) {
        try {
          final body = jsonDecode(res.body);
          final list = _extractStringList(body);
          setState(() {
            _pincodes = list;
          });
        } catch (e) {
          debugPrint('JSON parse error for pincodes: $e');
          _showSnackBar('Failed to parse pincodes response');
        }
      } else {
        _showSnackBar('Failed to load pincodes (${res.statusCode}): ${res.body}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException while fetching pincodes: $e');
      _showSnackBar('No internet connection or server unreachable');
    } on TimeoutException catch (e) {
      debugPrint('Timeout while fetching pincodes: $e');
      _showSnackBar('Request timed out while loading pincodes');
    } catch (e, st) {
      debugPrint('Error fetching pincodes: $e\n$st');
      _showSnackBar('Failed to load pincodes: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchAreas(String pincode) async {
    setState(() => _loading = true);
    try {
      final url = '$_effectiveBaseUrl/areas?pincode=${Uri.encodeQueryComponent(pincode)}';
      debugPrint('Fetching areas from: $url');
  final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      if (res.statusCode == 200) {
        try {
          final body = jsonDecode(res.body);
          final list = _extractStringList(body);
          setState(() {
            _areas = list;
          });
        } catch (e) {
          debugPrint('JSON parse error for areas: $e');
          _showSnackBar('Failed to parse areas response');
        }
      } else {
        _showSnackBar('Failed to load areas (${res.statusCode}): ${res.body}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException while fetching areas: $e');
      _showSnackBar('No internet connection or server unreachable');
    } on TimeoutException catch (e) {
      debugPrint('Timeout while fetching areas: $e');
      _showSnackBar('Request timed out while loading areas');
    } catch (e, st) {
      debugPrint('Error fetching areas: $e\n$st');
      _showSnackBar('Failed to load areas: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchTransformers(String area) async {
    setState(() => _loading = true);
    try {
      final url = '$_effectiveBaseUrl/transformers?area=${Uri.encodeQueryComponent(area)}';
      debugPrint('Fetching transformers from: $url');
  final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      if (res.statusCode == 200) {
        try {
          final body = jsonDecode(res.body);
          final list = _extractStringList(body);
          setState(() {
            _transformers = list;
          });
        } catch (e) {
          debugPrint('JSON parse error for transformers: $e');
          _showSnackBar('Failed to parse transformers response');
        }
      } else {
        _showSnackBar('Failed to load transformers (${res.statusCode}): ${res.body}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException while fetching transformers: $e');
      _showSnackBar('No internet connection or server unreachable');
    } on TimeoutException catch (e) {
      debugPrint('Timeout while fetching transformers: $e');
      _showSnackBar('Request timed out while loading transformers');
    } catch (e, st) {
      debugPrint('Error fetching transformers: $e\n$st');
      _showSnackBar('Failed to load transformers: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<String> _extractStringList(dynamic body) {
    if (body is List) {
      return body.map((e) {
        if (e is String) return e;
        if (e is Map && e.containsKey('pincode')) return e['pincode'].toString();
        if (e is Map && e.containsKey('area')) return e['area'].toString();
        if (e is Map && e.containsKey('transformer_number')) return e['transformer_number'].toString();
        // Fallback to string conversion
        return e.toString();
      }).toList();
    }
    return [];
  }

  void _showSnackBar(String message, {bool success = false}) {
    final color = success ? Colors.green : null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  Future<void> _sendMessage() async {
    final pincode = _selectedPincode;
    final area = _selectedArea;
    final transformer = _selectedTransformer;
    final message = _messageController.text.trim();

    if (pincode == null || area == null || transformer == null || message.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    setState(() => _sending = true);
    try {
      final body = jsonEncode({
        'pincode': pincode,
        'area': area,
        'transformer_number': transformer,
        'message': message,
      });

      final url = '$_effectiveBaseUrl/send-message';
      debugPrint('POST to $url with body: $body');

    final res = await http
      .post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body)
      .timeout(const Duration(seconds: 10));

      debugPrint('Send response status: ${res.statusCode}');
      debugPrint('Send response body: ${res.body}');

      if (res.statusCode == 200) {
        dynamic jsonBody;
        try {
          jsonBody = jsonDecode(res.body);
        } catch (e) {
          debugPrint('Failed to parse send response: $e');
          jsonBody = null;
        }

        int? count;
        if (jsonBody is Map) {
          if (jsonBody['sent'] is int) count = jsonBody['sent'];
          if (jsonBody['count'] is int) count = jsonBody['count'];
          if (jsonBody['delivered'] is int) count = jsonBody['delivered'];
          if (jsonBody['users'] is List) count = jsonBody['users'].length;
        }

        final messageText = count != null
            ? 'Message sent to $count users ✅'
            : 'Message sent ✅';

        _showSnackBar(messageText, success: true);
        // Reset only message field after success
        _messageController.clear();
      } else {
        _showSnackBar('Failed to send message (${res.statusCode}): ${res.body}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException while sending message: $e');
      _showSnackBar('No internet connection or server unreachable');
    } on TimeoutException catch (e) {
      debugPrint('Timeout while sending message: $e');
      _showSnackBar('Request timed out while sending message');
    } catch (e, st) {
      debugPrint('Error sending message: $e\n$st');
      _showSnackBar('Failed to send message: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send WhatsApp Message'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Select Pincode'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPincode,
                      items: _pincodes
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v == _selectedPincode) return;
                        setState(() {
                          _selectedPincode = v;
                          _selectedArea = null;
                          _areas = [];
                          _selectedTransformer = null;
                          _transformers = [];
                        });
                        if (v != null) _fetchAreas(v);
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 16),
                    const Text('Select Area'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      items: _areas
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) {
                        if (v == _selectedArea) return;
                        setState(() {
                          _selectedArea = v;
                          _selectedTransformer = null;
                          _transformers = [];
                        });
                        if (v != null) _fetchTransformers(v);
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 16),
                    const Text('Select Transformer'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTransformer,
                      items: _transformers
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTransformer = v),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 16),
                    const Text('Message'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter custom message',
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _sendMessage,
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send WhatsApp Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
