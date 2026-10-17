// AttendEase - Student Attendance Tracking (console prototype)
// Run with: dart run attendease.dart

import 'dart:io';

// ---------- Entities ----------
class Student {
  final int id;
  final String name;
  Student(this.id, this.name);
}

class ClassSession {
  final int id;
  final String course;
  final String date;
  ClassSession(this.id, this.course, this.date);
}

class AttendanceRecord {
  final int sessionId;
  final int studentId;
  final String status; // Present, Absent, or Late
  AttendanceRecord(this.sessionId, this.studentId, this.status);
}

// ---------- In-memory data ----------
final List<Student> students = [];
final List<ClassSession> sessions = [];
final List<AttendanceRecord> records = [];

const double minimumPercent = 75.0;

// ---------- Helpers ----------
String ask(String prompt) {
  stdout.write(prompt);
  return (stdin.readLineSync() ?? '').trim();
}

// Percentage of marked sessions the student attended (Present or Late).
double attendancePercent(int studentId) {
  final markedSessions = records.map((r) => r.sessionId).toSet().length;
  if (markedSessions == 0) return 0;
  final attended = records
      .where((r) => r.studentId == studentId && r.status != 'Absent')
      .length;
  return attended / markedSessions * 100;
}

// ---------- Features ----------
void addStudent() {
  final name = ask('Student name: ');
  if (name.isEmpty) {
    print('Name cannot be empty.');
    return;
  }
  final id = students.length + 1;
  students.add(Student(id, name));
  print('Student added. ID: $id');
}

void createSession() {
  final course = ask('Course name: ');
  final date = ask('Date (e.g. 2026-10-13): ');
  if (course.isEmpty || date.isEmpty) {
    print('Course and date are required.');
    return;
  }
  final id = sessions.length + 1;
  sessions.add(ClassSession(id, course, date));
  print('Session created. ID: $id');
}

void markAttendance() {
  if (students.isEmpty || sessions.isEmpty) {
    print('Add at least one student and one session first.');
    return;
  }
  for (final s in sessions) {
    print('Session ${s.id}: ${s.course} on ${s.date}');
  }
  final sessionId = int.tryParse(ask('Session ID: '));
  if (!sessions.any((s) => s.id == sessionId)) {
    print('Invalid session ID.');
    return;
  }
  if (records.any((r) => r.sessionId == sessionId)) {
    print('Attendance for this session was already marked.');
    return;
  }
  for (final student in students) {
    String? status;
    while (status == null) {
      final input = ask('${student.name} (P=Present, A=Absent, L=Late): ')
          .toUpperCase();
      status = {'P': 'Present', 'A': 'Absent', 'L': 'Late'}[input];
      if (status == null) print('Invalid option, try again.');
    }
    records.add(AttendanceRecord(sessionId!, student.id, status));
  }
  print('Attendance saved.');
}

void viewStudentAttendance() {
  final id = int.tryParse(ask('Student ID: '));
  final matches = students.where((s) => s.id == id);
  if (matches.isEmpty) {
    print('Student not found.');
    return;
  }
  final student = matches.first;
  final percent = attendancePercent(student.id);
  print('${student.name}: ${percent.toStringAsFixed(1)}% attendance');
  if (percent < minimumPercent) {
    print('Warning: below the $minimumPercent% requirement.');
  }
}

void listLowAttendance() {
  final low = students
      .where((s) => attendancePercent(s.id) < minimumPercent)
      .toList();
  if (low.isEmpty) {
    print('No students below $minimumPercent%.');
    return;
  }
  print('Students below $minimumPercent%:');
  for (final s in low) {
    print('- ${s.name}: ${attendancePercent(s.id).toStringAsFixed(1)}%');
  }
}

// ---------- Main menu ----------
void main() {
  print('=== AttendEase: Student Attendance Tracker ===');
  while (true) {
    print('\n1. Add student');
    print('2. Create class session');
    print('3. Mark attendance');
    print('4. View student attendance %');
    print('5. Show students below $minimumPercent%');
    print('0. Exit');
    final choice = ask('Choose an option: ');

    switch (choice) {
      case '1':
        addStudent();
        break;
      case '2':
        createSession();
        break;
      case '3':
        markAttendance();
        break;
      case '4':
        viewStudentAttendance();
        break;
      case '5':
        listLowAttendance();
        break;
      case '0':
        print('Goodbye!');
        return;
      default:
        print('Invalid option. Please try again.');
    }
  }
}
