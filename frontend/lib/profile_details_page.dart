import 'package:flutter/material.dart';
import 'welcome_page.dart';

class ProfileDetailsPage extends StatelessWidget {
  final Map<String, String> userDetails;

  const ProfileDetailsPage({super.key, required this.userDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        title: const Text("Profile Details"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const WelcomePage()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Account Info"),
          _buildDetailTile("Email", userDetails["Email"] ?? ""),
          const SizedBox(height: 12),
          _buildSectionHeader("Personal Info"),
          _buildDetailTile("Full Name", userDetails["Full Name"] ?? ""),
          _buildDetailTile("Age", userDetails["Age"] ?? ""),
          _buildDetailTile("Gender", userDetails["Gender"] ?? ""),
          _buildDetailTile("Height", userDetails["Height"] ?? ""),
          _buildDetailTile("Weight", userDetails["Weight"] ?? ""),
          _buildDetailTile("Contact", userDetails["Contact"] ?? ""),
          const SizedBox(height: 12),
          _buildSectionHeader("Sports Info"),
          _buildDetailTile("Sport", userDetails["Sport"] ?? ""),
          _buildDetailTile("Experience", userDetails["Experience"] ?? ""),
          _buildDetailTile("Goals", userDetails["Goals"] ?? ""),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
