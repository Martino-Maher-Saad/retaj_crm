import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_text_styles.dart';

import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/design_model.dart';

class DesignDetailsScreen extends StatelessWidget {
  final DesignModel design;

  const DesignDetailsScreen({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    // Adapter for images
    final designImageUrls = design.images?.map((e) => e.imageUrl).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("تفاصيل التصميم", style: AppTextStyles.h3),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Image Header (Reusing existing components or custom logic)
            if (designImageUrls.isNotEmpty)
              SizedBox(
                height: 350.h,
                child: PageView.builder(
                  itemCount: designImageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      designImageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              )
            else
              Container(
                height: 250.h,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(child: Text("لا توجد صور للتصميم")),
              ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RetajSectionCard(
                    title: "البيانات الأساسية",
                    icon: Icons.info_outline,
                    children: [
                      RetajFieldRow(
                        first: RetajTextField(
                          label: "نوع الغرفة",
                          initialValue: design.roomType ?? '---',
                          readOnly: true,
                        ),
                        second: RetajTextField(
                          label: "الطراز (Style)",
                          initialValue: design.style ?? '---',
                          readOnly: true,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      RetajTextArea(
                        label: "وصف التصميم بالعربي",
                        initialValue: design.descAr ?? '---',
                        readOnly: true,
                        minLines: 3,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  RetajSectionCard(
                    title: "بيانات الإضافة",
                    icon: Icons.person_pin,
                    children: [
                      RetajFieldRow(
                        first: RetajTextField(
                          label: "تاريخ الإضافة",
                          initialValue: "${design.createdAt.year}-${design.createdAt.month.toString().padLeft(2, '0')}-${design.createdAt.day.toString().padLeft(2, '0')}",
                          readOnly: true,
                        ),
                        second: RetajTextField(
                          label: "تمت الإضافة بواسطة",
                          initialValue: design.profile != null ? "${design.profile!.firstName} ${design.profile!.lastName}" : '---',
                          readOnly: true,
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
    );
  }
}
