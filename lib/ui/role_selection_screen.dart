import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import 'server_chat_screen.dart';
import 'client_chat_screen.dart';

/// Screen for selecting the role (Server or Client)
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checkingPermissions = true);
    
    final granted = await PermissionService.requestBlePermissions();
    
    setState(() {
      _permissionsGranted = granted;
      _checkingPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF00FF94)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bluetooth_connected,
                  size: 60,
                  color: Color(0xFF0D1117),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'BLE Chat',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Bluetooth Low Energy Messenger',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1,
                ),
              ),
              
              const Spacer(),
              
              if (_checkingPermissions)
                const CircularProgressIndicator(
                  color: Color(0xFF00D9FF),
                )
              else if (!_permissionsGranted)
                _buildPermissionWarning()
              else
                _buildRoleButtons(),
              
              const Spacer(),
              
              // Footer
              Text(
                'Select your device role to begin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BLE Chat needs Bluetooth and Location permissions to work properly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Open Settings',
                Icons.settings,
                const Color(0xFF2C2C2E),
                Colors.white,
                () => PermissionService.openSettings(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Retry',
                Icons.refresh,
                const Color(0xFF00D9FF),
                const Color(0xFF0D1117),
                _checkPermissions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButtons() {
    return Column(
      children: [
        // Server Button (Phone A)
        _buildRoleCard(
          title: 'Server Mode',
          subtitle: 'Phone A - BLE Peripheral',
          description: 'Advertise and wait for connections',
          icon: Icons.cell_tower,
          gradient: const [Color(0xFF00D9FF), Color(0xFF0099FF)],
          onTap: () => _navigateToRole(isServer: true),
        ),
        
        const SizedBox(height: 16),
        
        // Client Button (Phone B)
        _buildRoleCard(
          title: 'Client Mode',
          subtitle: 'Phone B - BLE Central',
          description: 'Scan and connect to servers',
          icon: Icons.phone_android,
          gradient: const [Color(0xFF00FF94), Color(0xFF00CC76)],
          onTap: () => _navigateToRole(isServer: false),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.15),
              gradient[1].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient[0].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0D1117),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: gradient[0],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRole({required bool isServer}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => isServer
            ? const ServerChatScreen()
            : const ClientChatScreen(),
      ),
    );
  }
}

