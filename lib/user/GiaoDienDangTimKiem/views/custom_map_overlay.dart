// lib/GiaoDienDangTimKiem/views/custom_map_overlay.dart

import 'package:flutter/material.dart';

class CustomMapOverlayWidget extends StatelessWidget {
  final Color primaryColor;

  const CustomMapOverlayWidget({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pin Vị trí Nạn nhân
        Align(
          alignment: const Alignment(0, -0.22),
          child: _buildVictimPin('124 Pasteur, Q.1'),
        ),
        // Pin Bác sĩ Tuấn
        Align(
          alignment: const Alignment(-0.38, -0.42),
          child: _buildDoctorPin('Bs. Tuấn • 1.2km'),
        ),
        // Pin Bác sĩ Mai
        Align(
          alignment: const Alignment(0.35, -0.05),
          child: _buildDoctorPin('Bs. Mai • 2.4km'),
        ),
        // Pin Bác sĩ phụ
        Align(
          alignment: const Alignment(0.65, -0.32),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVictimPin(String address) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(
            address,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorPin(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
