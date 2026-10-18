// AttendEase | Student Attendance Tracker
// Run with: dart run attendease.dart

import 'dart:io';

/// ANSI styling is enabled only when the current output supports it.
class TerminalStyle {
  static final bool enabled = stdout.supportsAnsiEscapes;

  static String _code(String code) => enabled ? '\u001B[${code}m' : '';

  static String get reset => enabled ? '\u001B[0m' : '';
  static String get title => _code('1;36');
  static String get accent => _code('94');
  static String get success => _code('32');
  static String get warning => _code('33');
  static String get error => _code('31');
  static String get muted => _code('90');
}

// ---------- Domain models ----------
class Student {
  final int id;
  final String name;

  const Student(this.id, this.name);
}

class ClassSession {
  final int id;
  final String course;
  final String date;

  const ClassSession(this.id, this.course, this.date);
}

class AttendanceRecord {
  final int sessionId;
  final int studentId;
  final String status;

  const AttendanceRecord(this.sessionId, this.studentId, this.status);
}

// ---------- In-memory data ----------
final List<Student> students = [];
final List<ClassSession> sessions = [];
final List<AttendanceRecord> records = [];

const double minimumPercent = 75.0;

// ---------- Terminal helpers ----------
String ask(String prompt) {
  stdout.write('${TerminalStyle.accent}$prompt${TerminalStyle.reset}');
  return (stdin.readLineSync() ?? '').trim();
}

void showMessage(String message, String style) {
  print('$style$message${TerminalStyle.reset}');
}

void showHeader(String heading) {
  print('\n${TerminalStyle.title} $heading ${TerminalStyle.reset}');
  print('${TerminalStyle.muted} ${'─' * heading.length} ${TerminalStyle.reset}');
}

bool isValidDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null &&
      parsed.year.toString().padLeft(4, '0') == value.substring(0, 4) &&
      parsed.month.toString().padLeft(2, '0') == value.substring(5, 7) &&
      parsed.day.toString().padLeft(2, '0') == value.substring(8, 10);
}

// Percentage of marked sessions the student attended (Present or Late).
double attendancePercent(int studentId) {
  final markedSessions = records.map((record) => record.sessionId).toSet().length;
  if (markedSessions == 0) return 0;

  final attended = records
      .where((record) =>
          record.studentId == studentId && record.status != 'Absent')
      .length;
  return attended / markedSessions * 100;
}

// ---------- Features ----------
void addStudent() {
  showHeader('Add student');
  final name = ask('Student name: ');
  if (name.isEmpty) {
    showMessage('A student name is required.', TerminalStyle.error);
    return;
  }

  final id = students.length + 1;
  students.add(Student(id, name));
  showMessage('Student added successfully (ID: $id).', TerminalStyle.success);
}

void createSession() {
  showHeader('Create class session');
  final course = ask('Course name: ');
  final date = ask('Session date (YYYY-MM-DD): ');
  if (course.isEmpty) {
    showMessage('A course name is required.', TerminalStyle.error);
    return;
  }
  if (!isValidDate(date)) {
    showMessage('Enter a valid date in YYYY-MM-DD format.', TerminalStyle.error);
    return;
  }

  final id = sessions.length + 1;
  sessions.add(ClassSession(id, course, date));
  showMessage('Session created successfully (ID: $id).', TerminalStyle.success);
}

void markAttendance() {
  showHeader('Record attendance');
  if (students.isEmpty || sessions.isEmpty) {
    showMessage('Add at least one student and one session first.',
        TerminalStyle.warning);
    return;
  }

  print('Available sessions:');
  for (final session in sessions) {
    print('  ${TerminalStyle.accent}[${session.id}]${TerminalStyle.reset} '
        '${session.course} · ${session.date}');
  }

  final sessionId = int.tryParse(ask('Session ID: '));
  if (!sessions.any((session) => session.id == sessionId)) {
    showMessage('That session ID does not exist.', TerminalStyle.error);
    return;
  }
  if (records.any((record) => record.sessionId == sessionId)) {
    showMessage('Attendance has already been recorded for this session.',
        TerminalStyle.warning);
    return;
  }

  for (final student in students) {
    String? status;
    while (status == null) {
      final input = ask('${student.name} (P = Present, A = Absent, L = Late): ')
          .toUpperCase();
      status = const {'P': 'Present', 'A': 'Absent', 'L': 'Late'}[input];
      if (status == null) {
        showMessage('Choose P, A, or L.', TerminalStyle.error);
      }
    }
    records.add(AttendanceRecord(sessionId!, student.id, status));
  }

  showMessage('Attendance recorded successfully.', TerminalStyle.success);
}

void viewStudentAttendance() {
  showHeader('Student attendance');
  if (students.isEmpty) {
    showMessage('No students have been added yet.', TerminalStyle.warning);
    return;
  }

  final id = int.tryParse(ask('Student ID: '));
  final matches = students.where((student) => student.id == id);
  if (matches.isEmpty) {
    showMessage('Student not found. Check the ID and try again.',
        TerminalStyle.error);
    return;
  }

  final student = matches.first;
  final percent = attendancePercent(student.id);
  print('\n${TerminalStyle.title}${student.name}${TerminalStyle.reset}');
  print('Attendance: ${TerminalStyle.accent}${percent.toStringAsFixed(1)}%'
      '${TerminalStyle.reset}');
  if (percent < minimumPercent) {
    showMessage('Below the ${minimumPercent.toStringAsFixed(0)}% requirement.',
        TerminalStyle.warning);
  } else {
    showMessage('Meeting the ${minimumPercent.toStringAsFixed(0)}% requirement.',
        TerminalStyle.success);
  }
}

void listLowAttendance() {
  showHeader('Students below attendance threshold');
  if (students.isEmpty) {
    showMessage('No students have been added yet.', TerminalStyle.warning);
    return;
  }

  final lowAttendanceStudents = students
      .where((student) => attendancePercent(student.id) < minimumPercent)
      .toList();
  if (lowAttendanceStudents.isEmpty) {
    showMessage('All students meet the ${minimumPercent.toStringAsFixed(0)}% '
        'attendance requirement.', TerminalStyle.success);
    return;
  }

  print('Name                         Attendance');
  print('${TerminalStyle.muted}${'─' * 40}${TerminalStyle.reset}');
  for (final student in lowAttendanceStudents) {
    final name = student.name.length > 26
        ? '${student.name.substring(0, 23)}…'
        : student.name;
    final percent = attendancePercent(student.id).toStringAsFixed(1);
    print('${name.padRight(28)} ${TerminalStyle.warning}$percent%'
        '${TerminalStyle.reset}');
  }
}

void showMenu() {
  print('\n${TerminalStyle.title} AttendEase ${TerminalStyle.reset}'
      '${TerminalStyle.muted}│ Student Attendance Tracker${TerminalStyle.reset}');
  print('${TerminalStyle.muted}${'─' * 42}${TerminalStyle.reset}');
  print('  ${TerminalStyle.accent}1${TerminalStyle.reset}  Add student');
  print('  ${TerminalStyle.accent}2${TerminalStyle.reset}  Create class session');
  print('  ${TerminalStyle.accent}3${TerminalStyle.reset}  Record attendance');
  print('  ${TerminalStyle.accent}4${TerminalStyle.reset}  View student attendance');
  print('  ${TerminalStyle.accent}5${TerminalStyle.reset}  List students below '
      '${minimumPercent.toStringAsFixed(0)}%');
  print('  ${TerminalStyle.muted}0  Exit${TerminalStyle.reset}');
}

// ---------- Application entry point ----------
void main() {
  while (true) {
    showMenu();
    switch (ask('\nSelect an option: ')) {
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
        showMessage('Goodbye.', TerminalStyle.success);
        return;
      default:
        showMessage('Invalid selection. Choose an option from 0 to 5.',
            TerminalStyle.error);
    }
  }
}
