import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClassementUser {
  final String nom;
  final int score;
  ClassementUser({required this.nom, required this.score});
  factory ClassementUser.fromJson(Map<String, dynamic> json) => ClassementUser(
        nom: json['nom'] ?? '',
        score: json['score'] is int ? json['score'] : int.tryParse(json['score'].toString()) ?? 0,
      );
}

class ClassementComponent extends StatelessWidget {
  final List<ClassementUser> classement;
  const ClassementComponent({super.key, required this.classement});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: classement.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = classement[index];
        final isTop3 = index < 3;
        final colors = [
          Colors.amber.shade700,
          Colors.grey.shade400,
          Colors.brown.shade400,
        ];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isTop3 ? colors[index] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isTop3)
                BoxShadow(
                  color: colors[index].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: isTop3 ? colors[index] : Colors.grey.shade200,
              width: isTop3 ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTop3 ? Colors.white : Colors.blue.shade50,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? colors[index] : Colors.blue,
                ),
              ),
            ),
            title: Text(
              user.nom,
              style: TextStyle(
                fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                color: isTop3 ? Colors.white : Colors.black,
              ),
            ),
            trailing: AnimatedScale(
              scale: isTop3 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${user.score} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTop3 ? 18 : 16,
                  color: isTop3 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  static const String baseUrl = "https://wizi-learn.com/api";
  List<ClassementUser> classement = [];
  bool isLoading = true;
  String? errorMsg;
  String? debugJson;

  @override
  void initState() {
    super.initState();
    fetchClassement();
  }

  Future<void> fetchClassement() async {
    setState(() { isLoading = true; errorMsg = null; debugJson = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/classement'));
      if (res.statusCode == 200) {
        debugJson = res.body;
        final data = json.decode(res.body);
        // Adapter selon la structure réelle du JSON
        final users = (data['classement'] ?? data) as List;
        classement = users.map((e) => ClassementUser.fromJson(e)).toList();
      } else {
        errorMsg = 'Erreur API classement: ${res.statusCode}';
      }
    } catch (e) {
      errorMsg = 'Erreur: $e';
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : Column(
                  children: [
                    if (debugJson != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text('DEBUG JSON: ' + debugJson!, style: const TextStyle(fontSize: 10, color: Colors.red)),
                        ),
                      ),
                    Expanded(child: ClassementComponent(classement: classement)),
                  ],
                ),
    );
  }
}
