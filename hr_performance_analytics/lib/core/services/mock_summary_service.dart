import '../../models/employee_performance.dart';

class MockSummaryService {
  static List<Map<String, dynamic>> generateMockSummaries(List<EmployeePerformance> employees) {
    return employees.map((e) => {
      "name": e.name,
      "id": e.id,
      "department": e.department,
      "month": e.month,
      "tasksCompleted": e.tasksCompleted.toString(),  // Convert to string
      "goalsMet": "${e.goalsMet}%",  // Add percentage sign
      "peerFeedback": e.peerFeedback ?? "",
      "managerComments": e.managerComments ?? "",
      "summary": _generateMockSummary(e),
    }).toList();
  }

  static String _generateMockSummary(EmployeePerformance employee) {
    // Generate a simple summary based on the employee data
    String performanceLevel = "";
    if (employee.goalsMet >= 90) {
      performanceLevel = "outstanding";
    } else if (employee.goalsMet >= 75) {
      performanceLevel = "good";
    } else if (employee.goalsMet >= 60) {
      performanceLevel = "satisfactory";
    } else {
      performanceLevel = "needs improvement";
    }

    return "${employee.name} has demonstrated $performanceLevel performance during ${employee.month}, "
        "completing ${employee.tasksCompleted} tasks and achieving ${employee.goalsMet}% of their goals. "
        "${_getPeerFeedbackSummary(employee.peerFeedback)} "
        "${_getManagerCommentSummary(employee.managerComments)}";
  }

  static String _getPeerFeedbackSummary(String? peerFeedback) {
    if (peerFeedback == null || peerFeedback.isEmpty) {
      return "No peer feedback was provided.";
    }
    return "Peers noted that they $peerFeedback.";
  }

  static String _getManagerCommentSummary(String? managerComments) {
    if (managerComments == null || managerComments.isEmpty) {
      return "No manager comments were provided.";
    }
    return "Manager comments indicate that the employee $managerComments.";
  }
}