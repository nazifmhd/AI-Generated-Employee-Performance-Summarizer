class EmployeePerformance {
  final String name;
  final String id;
  final String department;
  final String month;
  final int tasksCompleted;
  final double goalsMet;
  final String? peerFeedback;
  final String? managerComments;

  EmployeePerformance({
    required this.name,
    required this.id,
    required this.department,
    required this.month,
    required this.tasksCompleted,
    required this.goalsMet,
    this.peerFeedback,
    this.managerComments,
  });

  factory EmployeePerformance.fromCsv(List<dynamic> row) {
    return EmployeePerformance(
      name: row[0],
      id: row[1],
      department: row[2],
      month: row[3],
      tasksCompleted: int.tryParse(row[4]) ?? 0,
      goalsMet: double.tryParse(row[5].toString().replaceAll('%', '')) ?? 0.0,
      peerFeedback: row.length > 6 ? row[6] : null,
      managerComments: row.length > 7 ? row[7] : null,
    );
  }
}
