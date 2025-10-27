import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String BASE_URL = 'http://localhost:3002';

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
      final res = await http.get(Uri.parse('$BASE_URL/pincodes'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = _extractStringList(body);
        setState(() {
          _pincodes = list;
        });
      } else {
        _showSnackBar('Failed to load pincodes (${res.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Failed to load pincodes');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchAreas(String pincode) async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$BASE_URL/areas?pincode=$pincode'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = _extractStringList(body);
        setState(() {
          _areas = list;
        });
      } else {
        _showSnackBar('Failed to load areas (${res.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Failed to load areas');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchTransformers(String area) async {
    setState(() => _loading = true);
    try {
      final res =
          await http.get(Uri.parse('$BASE_URL/transformers?area=${Uri.encodeQueryComponent(area)}'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = _extractStringList(body);
        setState(() {
          _transformers = list;
        });
      } else {
        _showSnackBar('Failed to load transformers (${res.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Failed to load transformers');
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

      final res = await http.post(Uri.parse('$BASE_URL/send-message'),
          headers: {'Content-Type': 'application/json'}, body: body);

      if (res.statusCode == 200) {
        dynamic jsonBody;
        try {
          jsonBody = jsonDecode(res.body);
        } catch (_) {
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
        _showSnackBar('Failed to send message (${res.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Failed to send message');
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
