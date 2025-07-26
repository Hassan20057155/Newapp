import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int basePoints = 100;
  int totalBoost = 0;
  DateTime? lastActivated;
  bool active = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final boostSnap = await FirebaseFirestore.instance
        .collection("boosted_counters")
        .where("uid", isEqualTo: uid)
        .get();

    totalBoost = 0;
    for (var doc in boostSnap.docs) {
      totalBoost += doc['power'] ?? 0;
    }

    final data = userDoc.data();
    if (data != null && data.containsKey('lastActivated')) {
      lastActivated = (data['lastActivated'] as Timestamp).toDate();
    }

    final now = DateTime.now();
    active = lastActivated != null &&
        now.difference(lastActivated!).inHours < 24;

    setState(() {});
  }

  Future<void> activateCounter() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final totalPoints = basePoints + totalBoost;

    final now = DateTime.now();
    final userDoc = FirebaseFirestore.instance.collection("users").doc(uid);
    final userSnap = await userDoc.get();
    final currentPoints = userSnap.data()?['points'] ?? 0;

    if (lastActivated != null) {
      final diff = now.difference(lastActivated!);
      if (diff.inHours < 24) return;
    }

    await userDoc.update({
      'points': currentPoints + totalPoints,
      'lastActivated': Timestamp.fromDate(now),
    });

    setState(() {
      lastActivated = now;
      active = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تمت إضافة $totalPoints نقطة إلى حسابك")),
    );
  }

  String timeLeft() {
    if (lastActivated == null) return "00:00:00";
    final next = lastActivated!.add(const Duration(hours: 24));
    final now = DateTime.now();
    final diff = next.difference(now);
    if (diff.isNegative) return "00:00:00";

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
           "${minutes.toString().padLeft(2, '0')}:"
           "${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("العداد يعمل كل 24 ساعة", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text("الوقت المتبقي: ${timeLeft()}",
              style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: active ? null : activateCounter,
            child: const Text("تشغيل العداد"),
          )
        ],
      ),
    );
  }
}