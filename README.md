# AttendEase

AttendEase is a lightweight command-line attendance tracker written in Dart. It helps instructors record class sessions, mark each student's attendance, and review attendance percentages against a configurable threshold.

## Features

- Add students and create dated class sessions.
- Record each student's status as present, absent, or late.
- View an individual attendance percentage.
- List students below the attendance threshold.
- Use a clear, color-enhanced terminal interface when ANSI colors are supported.

## Requirements

- Dart SDK 3.0 or later

## Run

From the project directory, run:

```sh
dart run attendease.dart
```

The application is interactive. Use the numbered menu to manage students and sessions, then select **0** to exit.

## Attendance calculation

Present and late statuses count as attended. The percentage is calculated as the student's attended marked sessions divided by the number of sessions for which attendance has been recorded. The default low-attendance threshold is 75%.

## Data storage

This prototype keeps all data in memory for the duration of the current run. Students, sessions, and attendance records are cleared when the application exits.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
