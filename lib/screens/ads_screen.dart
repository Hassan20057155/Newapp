import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  RewardedAd? _rewardedAd;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3513337049199494/8711209396',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void _showAd() {
    if (_rewardedAd == null) return;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        final points = _generateRandomPoints();
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        final snapshot = await userDoc.get();
        final currentPoints = snapshot.data()?['points'] ?? 0;

        await userDoc.update({
          'points': currentPoints + points,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تمت إضافة $points نقطة إلى حسابك")),
        );

        _loadRewardedAd();
      },
    );
  }

  int _generateRandomPoints() {
    final rand = Random().nextDouble();
    if (rand < 0.9) return Random().nextInt(5) + 1;
    if (rand < 0.93) return Random().nextInt(5) + 6;
    if (rand < 0.935) return Random().nextInt(20) + 11;
    if (rand < 0.9351) return Random().nextInt(40) + 31;
    if (rand < 0.93510001) return Random().nextInt(30) + 71;
    return Random().nextInt(900) + 101;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("شاهد إعلان لتحصل على نقاط"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _rewardedAd != null ? _showAd : null,
          child: const Text("مشاهدة إعلان"),
        ),
      ],
    );
  }
}