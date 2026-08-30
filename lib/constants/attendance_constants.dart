import 'package:flutter/material.dart';

class AttendanceConstants {
  static const primaryNavy = Color(0xFF073B6F);
  static const darkNavy = Color(0xFF052B52);
  static const primaryBlue = Color(0xFF0B6EAA);
  static const cyan = Color(0xFF18A8C8);
  static const successGreen = Color(0xFF159957);
  static const warningOrange = Color(0xFFF39A00);
  static const red = Color(0xFFE94B4B);
  static const background = Color(0xFFF6F9FC);
  static const textGrey = Color(0xFF6B7C93);
  
  static const branches = ['IF', 'CM'];
  static const years = ['1', '2', '3'];

  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Used only when Firestore has no course catalog yet.
  static const fallbackCourses = [
    'JAVA',
    'PYTHON',
    'DBMS',
    'OPS',
    'SWE',
    'IFS',
    'EES',
  ];
}
