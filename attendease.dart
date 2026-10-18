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

String _fitCell(String value, int width) {
  if (value.length <= width) return value.padRight(width);
  if (width < 2) return value.substring(0, width);
  return '${value.substring(0, width - 1)}…';
}

void printTable(List<String> headers, List<List<String>> rows) {
  final widths = List<int>.generate(headers.length, (column) {
    final largestValue = rows
        .map((row) => row[column].length)
        .fold(0, (largest, length) => length > largest ? length : largest);
    return [headers[column].length, largestValue, 3].reduce((a, b) => a > b ? a : b);
  });

  String border(String left, String join, String right) =>
      '$left${widths.map((width) => '─' * (width + 2)).join(join)}$right';
  String line(List<String> cells) =>
      '│ ${List<int>.generate(headers.length, (i) => i)
          .map((column) => _fitCell(cells[column], widths[column]))
          .join(' │ ')} │';

  print('${TerminalStyle.muted}${border('┌', '┬', '┐')}${TerminalStyle.reset}');
  print('${TerminalStyle.title}${line(headers)}${TerminalStyle.reset}');
  print('${TerminalStyle.muted}${border('├', '┼', '┤')}${TerminalStyle.reset}');
  for (final row in rows) {
    print(line(row));
  }
  print('${TerminalStyle.muted}${border('└', '┴', '┘')}${TerminalStyle.reset}');
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

  printTable(
    const ['ID', 'COURSE', 'DATE'],
    sessions
        .map((session) => [session.id.toString(), session.course, session.date])
        .toList(),
  );

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

  final markedAttendance = <List<String>>[];
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
    markedAttendance.add([student.id.toString(), student.name, status]);
  }

  printTable(const ['ID', 'STUDENT', 'STATUS'], markedAttendance);
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
  final requirement = percent < minimumPercent ? 'Below threshold' : 'On track';
  printTable(const ['ID', 'STUDENT', 'ATTENDANCE', 'REQUIREMENT'], [
    [student.id.toString(), student.name, '${percent.toStringAsFixed(1)}%', requirement],
  ]);
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

  printTable(
    const ['ID', 'STUDENT', 'ATTENDANCE', 'REQUIREMENT'],
    lowAttendanceStudents
        .map((student) => [
              student.id.toString(),
              student.name,
              '${attendancePercent(student.id).toStringAsFixed(1)}%',
              'Below threshold',
            ])
        .toList(),
  );
}

void showMenu() {
  print('\n${TerminalStyle.title} AttendEase | Student Attendance Tracker'
      '${TerminalStyle.reset}');
  printTable(const ['OPTION', 'ACTION'], [
    ['1', 'Add student'],
    ['2', 'Create class session'],
    ['3', 'Record attendance'],
    ['4', 'View student attendance'],
    ['5', 'List students below ${minimumPercent.toStringAsFixed(0)}%'],
    ['0', 'Exit'],
  ]);
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
