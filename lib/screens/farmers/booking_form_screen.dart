import 'package:flutter/material.dart';
import 'package:argi_project/models/drone_service.dart';
import 'package:argi_project/services/api_service.dart';
import 'dart:convert';

class BookingFormScreen extends StatefulWidget {
  final DroneService service;

  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String location = '', notes = '';
  double areaSize = 1;
  DateTime? selectedDate;

  bool isLoading = false;

  void submitBooking() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final res = await ApiService.post(
        '/api/bookings/create',
        {
          "serviceId": widget.service.id,
          "scheduledDate": selectedDate!.toIso8601String(),
          "areaSize": areaSize,
          "location": location,
          "notes": notes,
        },
        useAuth: true);

    setState(() => isLoading = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đặt dịch vụ thành công')));
      Navigator.pop(context);
    } else {
      final error = jsonDecode(res.body)['message'];
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt dịch vụ: ${widget.service.serviceName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Vị trí thửa ruộng'),
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
                onSaved: (val) => location = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Diện tích (ha)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => areaSize = double.parse(val!),
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
                onSaved: (val) => notes = val ?? '',
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(selectedDate == null
                    ? 'Chọn ngày hẹn'
                    : 'Ngày: ${selectedDate!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : submitBooking,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Đặt dịch vụ'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
