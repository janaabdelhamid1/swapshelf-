
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class PinPoints extends StatelessWidget {
  final String name;
  final String area;
  final String location;
  final String image;

  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const PinPoints({
    super.key,
    required this.name,
    required this.area,
    required this.location,
    required this.image,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  // Open location in Google Maps
  Future<void> openMap(String location) async {
    final Uri url = Uri.parse(location);

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not open map');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),

      onTap: () {
        if (selectionMode) {
          onSelect?.call();
        } else {
          openMap(location);
        }
      },

      child: Card(
        color: isSelected
            ? const Color(0xFFEAC8B0)
            : const Color(0xFFFFF8EF),

        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF713E29)
                : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),

        child: Padding(
          padding: EdgeInsets.all(10.w),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF2A0A09),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 7.h),

                    Text(
                      area,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF713E29),
                      ),
                    ),

                    if (selectionMode) ...[
                      SizedBox(height: 12.h),

                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: const Color(0xFF713E29),
                        size: 23.sp,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              ClipRRect(
                borderRadius: BorderRadius.circular(13.r),

                child: Image.network(
                  image,
                  height: 110.h,
                  width: 110.w,
                  fit: BoxFit.cover,

                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 110.h,
                      width: 110.w,
                      color: const Color(0xFFE8D8C7),

                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF713E29),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
