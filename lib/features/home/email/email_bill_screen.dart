import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'email_bill_controller.dart';

class EmailBillScreen extends StatelessWidget {
  final String billType;

  EmailBillScreen({super.key, required this.billType});

  late final EmailBillController controller = Get.put(EmailBillController())
    ..billType = billType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          'home.email_bill.title'.tr,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    /// Top Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF5A1ABE), width: 1.22),
                      ),
                      child: Column(
                        children: [
                             Image.asset(
                              'assets/images/send_mail.webp',
                              fit: BoxFit.contain,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Warning: Use same email
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF9800), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'home.email_bill.confirm_same_email'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Instruction Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF5A1ABE), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'home.email_bill.instructions'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'home.email_bill.instruction_text'.tr,
                            style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'home.email_bill.email_label'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                          ),

                          const SizedBox(height: 8),

                          /// Email Box
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF5A1ABE), width: 1.2),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.email.value,
                                    style: const TextStyle(
                                      color: Color(0xFF5A1ABE),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: controller.copyEmail,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5A1ABE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'home.email_bill.copy'.tr,
                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )),

                          const SizedBox(height: 12),

                          /// Notes
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.w900)),
                              Expanded(
                                child: Text(
                                  'home.email_bill.note1'.tr,
                                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.w900)),
                              Expanded(
                                child: Text(
                                  'home.email_bill.note2'.tr,
                                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isCreating.value ? null : controller.onEmailSent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A1ABE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isCreating.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('home.email_bill.button'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
              )),
            ),

            const SizedBox(height: 10),

            /// Back Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF5A1ABE)),
                  foregroundColor: const Color(0xFF5A1ABE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('home.email_bill.back'.tr, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}
