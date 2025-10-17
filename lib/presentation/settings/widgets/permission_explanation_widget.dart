import 'package:flutter/material.dart';

class PermissionExplanationWidget extends StatelessWidget {
  final String title;
  final String description;
  final List<String> benefits;
  final List<String> limitations;
  final VoidCallback? onRequestPermission;
  final bool isPermissionGranted;

  const PermissionExplanationWidget({
    super.key,
    required this.title,
    required this.description,
    required this.benefits,
    required this.limitations,
    this.onRequestPermission,
    this.isPermissionGranted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPermissionGranted ? Icons.check_circle : Icons.info_outline,
                color: isPermissionGranted ? Colors.green : Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          if (benefits.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(
              'With this permission enabled:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            ...benefits.map((benefit) => _buildBenefitItem(benefit)),
          ],
          if (limitations.isNotEmpty && !isPermissionGranted) ...[
            SizedBox(height: 16),
            Text(
              'Without this permission:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            ...limitations.map((limitation) => _buildLimitationItem(limitation)),
          ],
          if (!isPermissionGranted && onRequestPermission != null) ...[
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: Icon(Icons.security),
                label: Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (isPermissionGranted) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Permission granted and working properly.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}