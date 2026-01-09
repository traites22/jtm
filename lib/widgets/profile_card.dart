import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final int age;
  final String bio;
  final String photoPath;

  const ProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: FuturisticTheme.glass,
        boxShadow: [BoxShadow(color: FuturisticTheme.neonBlue.withAlpha(26), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              photoPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name, $age',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
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
}
