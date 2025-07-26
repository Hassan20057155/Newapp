import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();

  Future<void> submitRequest() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final snapshot = await userDoc.get();
    final currentPoints = snapshot.data()?['points'] ?? 0;
    final referral = snapshot.data()?['referral'] ?? 'بدون رمز';

    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    final phone = phoneController.text.trim();

    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("أقل عدد نقاط للسحب هو 50000")),
      );
      return;
    }

    if (amount > currentPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ليس لديك نقاط كافية")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('withdraw_requests').add({
      'uid': uid,
      'referral': referral,
      'amount': amount,
      'phone': phone,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'beforePoints': currentPoints,
      'afterPoints': currentPoints - amount,
    });

    await userDoc.update({'points': currentPoints - amount});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إرسال طلب السحب")),
    );

    amountController.clear();
    phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("طلب سحب النقاط", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 10),
        TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: "عدد النقاط المراد سحبها",
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: "رقم محفظة زين كاش",
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitRequest,
          child: const Text("إرسال الطلب"),
        )
      ],
    );
  }
}