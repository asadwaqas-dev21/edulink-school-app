import "package:edulink/core/utils/dialog_utils.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:url_launcher/url_launcher.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/data/repositories/attendance_repository.dart";
import "package:edulink/domain/entities/assignment.dart";
import "package:edulink/domain/entities/attendance_record.dart";
import "package:edulink/domain/entities/custom_test.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/quiz.dart";
import "package:edulink/domain/entities/quiz_question.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/quiz_result.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/domain/entities/submission.dart";
import "package:edulink/domain/entities/test_result.dart";
import "package:edulink/presentation/web/pages/web_performance_pages.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_modals.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

/// The three kinds of assessment a subject can hold, presented as one list.
enum _AsmtType { assignment, quiz, exam }

/// A unified row that wraps whichever underlying assessment it represents so
/// assignments, quizzes and exams can be shown in a single filterable list.
class _AssessmentRow {
  final _AsmtType type;
  final String title;
  final String meta;
  final Assignment? assignment;
  final Quiz? quiz;
  final CustomTest? customTest;

  const _AssessmentRow({
    required this.type,
    required this.title,
    required this.meta,
    this.assignment,
    this.quiz,
    this.customTest,
  });
}

/// Web drill-down that lets teachers and admins browse a class's activities:
/// subjects → assessments → submissions (with grading), quiz results & marks.
class WebClassActivitiesScreen extends StatefulWidget {
  final SchoolClass cls;
  final Subject? initialSubject;
  const WebClassActivitiesScreen(
      {super.key, required this.cls, this.initialSubject});

  @override
  State<WebClassActivitiesScreen> createState() =>
      _WebClassActivitiesScreenState();
}

class _WebClassActivitiesScreenState extends State<WebClassActivitiesScreen> {
  final _assessment = Get.find<AssessmentRepository>();
  final _academics = Get.find<AcademicsRepository>();
  final _attendanceRepo = Get.find<AttendanceRepository>();
  UserRole get _role => Get.find<SessionController>().role;
  String get _uid => Get.find<SessionController>().userId ?? "";
  bool get _canGrade => _role.canGrade;
  bool get _canManageClass => _role.isPrincipal;
  bool get _canAttend => _role.canMarkAttendance;

  /// Principals can manage any subject; teachers only the subjects they teach.
  bool _canManage(Subject s) =>
      _role.isPrincipal || (_role.isTeacher && s.teacherId == _uid);

  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Enrollment>> _studentsFuture;

  Subject? _subject;
  Assignment? _assignment;
  Quiz? _quiz;
  CustomTest? _customTest;
  bool _showAttendance = false;

  Future<List<_AssessmentRow>>? _assessmentsFuture;
  _AsmtType? _filter; // null = show all
  Future<List<Submission>>? _submissionsFuture;
  Future<List<QuizQuestion>>? _questionsFuture;
  Future<List<QuizResult>>? _resultsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _academics.subjects(widget.cls.id);
    _studentsFuture = _academics.enrollments(widget.cls.id);
    if (widget.initialSubject != null) {
      _subject = widget.initialSubject;
      _assessmentsFuture = _loadAssessments(widget.initialSubject!.id);
    }
  }

  /// Loads assignments, quizzes and exams for a subject and merges them into a
  /// single, typed list so the subject view can show one unified table.
  Future<List<_AssessmentRow>> _loadAssessments(String subjectId) async {
    final assignments = await _assessment.assignmentsForSubject(subjectId);
    final quizzes = await _assessment.quizzes(subjectId);
    final tests = await _assessment.customTestsForSubject(subjectId);
    return [
      for (final a in assignments)
        _AssessmentRow(
          type: _AsmtType.assignment,
          title: a.title,
          meta:
              "${a.dueDate == null ? "No due date" : "Due ${Formatters.date(a.dueDate!)}"}  •  Max ${a.maxPoints} pts",
          assignment: a,
        ),
      for (final q in quizzes)
        _AssessmentRow(
          type: _AsmtType.quiz,
          title: q.title,
          meta:
              "${q.questionCount} question${q.questionCount == 1 ? "" : "s"}  •  auto-graded",
          quiz: q,
        ),
      for (final ct in tests)
        _AssessmentRow(
          type: _AsmtType.exam,
          title: ct.title,
          meta:
              "${ct.testDate == null ? "No date" : Formatters.date(ct.testDate!)}  •  Max ${ct.maxMarks} marks",
          customTest: ct,
        ),
    ];
  }

  void _refreshAssessments() {
    if (_subject != null) {
      _assessmentsFuture = _loadAssessments(_subject!.id);
    }
  }

  void _openSubject(Subject s) {
    setState(() {
      _subject = s;
      _assignment = null;
      _quiz = null;
      _customTest = null;
      _filter = null;
      _assessmentsFuture = _loadAssessments(s.id);
    });
  }

  void _openAssignment(Assignment a) {
    setState(() {
      _assignment = a;
      _quiz = null;
      _customTest = null;
      _submissionsFuture = _assessment.submissions(a.id);
    });
  }

  void _openQuiz(Quiz q) {
    setState(() {
      _quiz = q;
      _assignment = null;
      _customTest = null;
      _questionsFuture = _assessment.questions(q.id);
      _resultsFuture = _assessment.getQuizResults(q.id);
    });
  }

  void _openCustomTest(CustomTest ct) {
    setState(() {
      _customTest = ct;
      _assignment = null;
      _quiz = null;
    });
  }

  void _back() {
    setState(() {
      if (_showAttendance) {
        _showAttendance = false;
      } else if (_assignment != null) {
        _assignment = null;
      } else if (_quiz != null) {
        _quiz = null;
      } else if (_customTest != null) {
        _customTest = null;
      } else if (_subject != null && widget.initialSubject == null) {
        _subject = null;
      } else {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _bar(t),
            Expanded(child: _body(t)),
          ],
        ),
      ),
    );
  }

  Widget _bar(WebTokens t) {
    final crumbs = <String>[
      widget.cls.displayName,
      if (_showAttendance) "Attendance",
      if (_subject != null) _subject!.name,
      if (_assignment != null) _assignment!.title,
      if (_quiz != null) _quiz!.title,
      if (_customTest != null) _customTest!.title,
    ];
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          Material(
            color: t.panel2,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _back,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.line),
                ),
                child: Icon(Iconsax.arrow_left_2, size: 17, color: t.ink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              crumbs.join("  ›  "),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: t.ink, fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(WebTokens t) {
    if (_showAttendance) {
      return _ClassAttendance(
        cls: widget.cls,
        academics: _academics,
        attendance: _attendanceRepo,
        canMark: _canAttend,
        markedBy: _uid,
      );
    }
    if (_assignment != null) return _assignmentDetail(t);
    if (_quiz != null) return _quizDetail(t);
    if (_customTest != null) return _customTestDetail(t);
    if (_subject != null) return _subjectDetail(t);
    return _subjectsList(t);
  }

  // ── Level 1: subjects + students ──
  Widget _subjectsList(WebTokens t) {
    return WebPageBody(
      children: [
        WebPageHead(
          title: widget.cls.displayName,
          subtitle:
              "Class overview — subjects and enrolled students. Open a subject to view its activities.",
          actions: [
            if (_canAttend)
              WebButton(
                label: "Take attendance",
                icon: Iconsax.calendar_tick,
                kind: WebBtnKind.primary,
                onTap: () => setState(() => _showAttendance = true),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionHead(
              title: "Subjects",
              subtitle:
                  "Pick a subject to view its assignments, quizzes and submissions."),
        ),
        FutureBuilder<List<Subject>>(
          future: _subjectsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loading();
            }
            final subjects = snap.data ?? [];
            if (subjects.isEmpty) {
              return _empty(t, Iconsax.book, "No subjects yet",
                  "Add subjects to this class to start posting activities.");
            }
            return WebGrid(
              columns: _cols(context),
              children: [
                for (final s in subjects)
                  WebCard(
                    onTap: () => _openSubject(s),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Monogram(_initial(s.name), tone: Tone.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: t.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(s.teacherName ?? "Unassigned",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(color: t.muted, fontSize: 10)),
                            ],
                          ),
                        ),
                        Icon(Iconsax.arrow_right_3, size: 16, color: t.muted),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _studentsCard(t),
      ],
    );
  }

  Widget _studentsCard(WebTokens t) {
    return FutureBuilder<List<Enrollment>>(
      future: _studentsFuture,
      builder: (context, snap) {
        final students = snap.data ?? [];
        final loading = snap.connectionState == ConnectionState.waiting;
        return WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                  title: loading ? "Students" : "Students (${students.length})",
                  subtitle: "Each student belongs to one class only",
                  trailing: _canManageClass
                      ? WebButton(
                          label: "Enroll student",
                          icon: Iconsax.add,
                          kind: WebBtnKind.primary,
                          onTap: _enrollStudent)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                _loading()
              else if (students.isEmpty)
                _emptyMini(t, "No students enrolled in this class yet.")
              else
                WebTable(
                  columns: const [
                    WebCol("#", flex: 1),
                    WebCol("Student", flex: 4),
                    WebCol("Roll no", flex: 2),
                    WebCol("Email", flex: 4),
                    WebCol("", flex: 2, right: true),
                  ],
                  rows: [
                    for (int i = 0; i < students.length; i++)
                      [
                        Text("${i + 1}", style: TextStyle(color: t.muted)),
                        Row(
                          children: [
                            Monogram(_initial(students[i].studentName ?? "?"),
                                size: 28, radius: 8),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(students[i].studentName ?? "Student",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        Text(students[i].rollNo ?? "—"),
                        Text(students[i].studentEmail ?? "—",
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TableAction(Iconsax.chart_success,
                                onTap: () => _openReport(students[i])),
                            if (_canManageClass) ...[
                              const SizedBox(width: 5),
                              TableAction(Iconsax.profile_remove,
                                  onTap: () => _removeFromClass(students[i])),
                            ],
                          ],
                        ),
                      ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _openReport(Enrollment e) {
    final student = Profile(
      id: e.studentId,
      email: e.studentEmail ?? "",
      fullName: e.studentName ?? "Student",
      role: UserRole.student,
    );
    Get.to(() => WebStudentReportScreen(student: student));
  }

  Future<void> _enrollStudent() async {
    final t = WebTokens.of(context);
    final students = Get.find<WebDashboardController>().students.toList()
      ..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    if (students.isEmpty) {
      SnackbarUtils.showWarning(
          "No students in the institute yet. Add students first.");
      return;
    }
    String? selectedId = students.first.id;
    final rollCtrl = TextEditingController();
    await showWebModal(
      context: context,
      title: "Enroll student",
      saveLabel: "Enroll",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Student",
            child: DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: _dec(t),
              items: [
                for (final s in students)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.fullName, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setSt(() => selectedId = v),
            ),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Roll no (optional)",
            child: TextField(
                controller: rollCtrl, decoration: _dec(t, hint: "e.g. 12")),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                "If the student is already in another class, they will be moved here.",
                style: TextStyle(color: t.muted, fontSize: 10.5)),
          ),
        ],
      ),
      onSave: () async {
        if (selectedId == null) {
          SnackbarUtils.showWarning("Pick a student");
          return false;
        }
        try {
          await _academics.enroll(Enrollment(
            id: "",
            classId: widget.cls.id,
            studentId: selectedId!,
            rollNo: rollCtrl.text.trim().isEmpty ? null : rollCtrl.text.trim(),
          ));
          SnackbarUtils.showSuccess("Student enrolled in ${widget.cls.displayName}");
          if (mounted) {
            setState(
                () => _studentsFuture = _academics.enrollments(widget.cls.id));
          }
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _removeFromClass(Enrollment e) async {
    final confirm = await DialogUtils.showConfirmation(
      context: context,
      title: "Remove student",
      message:
          "Remove ${e.studentName ?? "this student"} from ${widget.cls.displayName}? Their account is kept — they just won't belong to this class anymore.",
      confirmText: "Remove",
      isDestructive: true,
    );
    if (confirm != true) return;
    try {
      await _academics.unenroll(e.id);
      SnackbarUtils.showSuccess("Removed from class");
      if (mounted) {
        setState(() => _studentsFuture = _academics.enrollments(widget.cls.id));
      }
    } catch (err) {
      SnackbarUtils.showError(err.toString());
    }
  }

  // ── Level 2: subject — one unified list of all assessments ──
  Widget _subjectDetail(WebTokens t) {
    final canManage = _canManage(_subject!);
    return WebPageBody(
      children: [
        WebPageHead(
          title: _subject!.name,
          subtitle: canManage
              ? "You teach this subject — create and manage its assessments below."
              : "Teacher: ${_subject!.teacherName ?? "Unassigned"}",
        ),
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                  title: "Assessments",
                  subtitle:
                      "Assignment = homework & files · Quiz = auto-graded MCQs · Exam = manual marks",
                  trailing: canManage ? _addMenu(t) : null,
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<_AssessmentRow>>(
                future: _assessmentsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  final all = snap.data ?? [];
                  final filtered = _filter == null
                      ? all
                      : all.where((r) => r.type == _filter).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        child: _typeFilters(t, all),
                      ),
                      const SizedBox(height: 14),
                      if (all.isEmpty)
                        _emptyMini(
                            t,
                            canManage
                                ? "No assessments yet. Use \u201cNew\u201d to add an assignment, quiz or exam."
                                : "No assessments have been posted yet.")
                      else if (filtered.isEmpty)
                        _emptyMini(t,
                            "No ${_typeLabel(_filter!).toLowerCase()}s in this subject yet.")
                      else
                        WebTable(
                          columns: const [
                            WebCol("Assessment", flex: 4),
                            WebCol("Type", flex: 2),
                            WebCol("Details", flex: 4),
                            WebCol("", flex: 1, right: true),
                          ],
                          rows: [
                            for (final r in filtered)
                              [
                                Text(r.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                StatusChip(_typeLabel(r.type),
                                    tone: _typeTone(r.type)),
                                Text(r.meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: t.muted, fontSize: 11)),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TableAction(Iconsax.arrow_right_3,
                                      onTap: () => _openRow(r)),
                                ),
                              ],
                          ],
                        ),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openRow(_AssessmentRow r) {
    switch (r.type) {
      case _AsmtType.assignment:
        _openAssignment(r.assignment!);
      case _AsmtType.quiz:
        _openQuiz(r.quiz!);
      case _AsmtType.exam:
        _openCustomTest(r.customTest!);
    }
  }

  String _typeLabel(_AsmtType t) => switch (t) {
        _AsmtType.assignment => "Assignment",
        _AsmtType.quiz => "Quiz",
        _AsmtType.exam => "Exam",
      };

  Tone _typeTone(_AsmtType t) => switch (t) {
        _AsmtType.assignment => Tone.primary,
        _AsmtType.quiz => Tone.info,
        _AsmtType.exam => Tone.warning,
      };

  Widget _typeFilters(WebTokens t, List<_AssessmentRow> all) {
    int countOf(_AsmtType? ty) =>
        ty == null ? all.length : all.where((r) => r.type == ty).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterPill(t, "All", null, countOf(null)),
        _filterPill(
            t, "Assignments", _AsmtType.assignment, countOf(_AsmtType.assignment)),
        _filterPill(t, "Quizzes", _AsmtType.quiz, countOf(_AsmtType.quiz)),
        _filterPill(t, "Exams", _AsmtType.exam, countOf(_AsmtType.exam)),
      ],
    );
  }

  Widget _filterPill(WebTokens t, String label, _AsmtType? ty, int count) {
    final selected = _filter == ty;
    return Material(
      color: selected ? t.primary : t.panel2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _filter = ty),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? t.primary : t.line),
          ),
          child: Text("$label ($count)",
              style: TextStyle(
                  color: selected ? Colors.white : t.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _addMenu(WebTokens t) {
    return PopupMenuButton<_AsmtType>(
      tooltip: "Add assessment",
      offset: const Offset(0, 44),
      color: t.panel,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.line)),
      onSelected: (ty) {
        switch (ty) {
          case _AsmtType.assignment:
            _createAssignment();
          case _AsmtType.quiz:
            _createQuiz();
          case _AsmtType.exam:
            _createCustomTest();
        }
      },
      itemBuilder: (_) => [
        _addMenuItem(t, _AsmtType.assignment, Iconsax.document_text,
            "Assignment", "Homework & file submissions"),
        _addMenuItem(t, _AsmtType.quiz, Iconsax.task_square, "Quiz",
            "Auto-graded multiple choice"),
        _addMenuItem(t, _AsmtType.exam, Iconsax.clipboard_text, "Exam / Test",
            "Manual mark sheet"),
      ],
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: t.primary, borderRadius: BorderRadius.circular(11)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.add, size: 15, color: Colors.white),
            SizedBox(width: 8),
            Text("New",
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            SizedBox(width: 4),
            Icon(Iconsax.arrow_down_1, size: 13, color: Colors.white),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_AsmtType> _addMenuItem(
      WebTokens t, _AsmtType ty, IconData icon, String title, String sub) {
    return PopupMenuItem<_AsmtType>(
      value: ty,
      child: Row(
        children: [
          Icon(icon, size: 17, color: t.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: TextStyle(
                      color: t.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(color: t.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Level 3a: assignment submissions ──
  Widget _assignmentDetail(WebTokens t) {
    final a = _assignment!;
    return WebPageBody(
      children: [
        WebPageHead(
          title: a.title,
          subtitle:
              "${a.dueDate == null ? "No due date" : "Due ${Formatters.date(a.dueDate!)}"}  •  Max ${a.maxPoints} pts",
        ),
        if ((a.description ?? "").isNotEmpty) ...[
          WebCard(
            padding: const EdgeInsets.all(16),
            child: Text(a.description!,
                style: TextStyle(color: t.ink, fontSize: 12, height: 1.5)),
          ),
          const SizedBox(height: 17),
        ],
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                    title: "Submissions",
                    subtitle: _canGrade
                        ? "Open a file and record a grade"
                        : "Student submissions"),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Submission>>(
                future: _submissionsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return _emptyMini(t, "No submissions yet.");
                  }
                  return WebTable(
                    columns: const [
                      WebCol("Student", flex: 3),
                      WebCol("Submitted", flex: 2),
                      WebCol("Status", flex: 2),
                      WebCol("Grade", flex: 2, right: true),
                      WebCol("", flex: 2, right: true),
                    ],
                    rows: [
                      for (final s in items)
                        [
                          Text(s.studentName ?? "Student",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(s.submittedAt == null
                              ? "—"
                              : Formatters.date(s.submittedAt!)),
                          StatusChip(s.status.label,
                              tone: _submissionTone(s.status)),
                          Text(
                              s.grade == null
                                  ? "—"
                                  : "${s.grade}/${a.maxPoints}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if ((s.fileUrl ?? "").isNotEmpty)
                                TableAction(Iconsax.document_download,
                                    onTap: () => _openUrl(s.fileUrl!)),
                              if (_canGrade) ...[
                                const SizedBox(width: 5),
                                TableAction(Iconsax.edit_2,
                                    onTap: () => _gradeSubmission(s, a)),
                              ],
                            ],
                          ),
                        ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 3b: quiz questions + results ──
  Widget _quizDetail(WebTokens t) {
    final q = _quiz!;
    return WebPageBody(
      children: [
        WebPageHead(
          title: q.title,
          subtitle: (q.description ?? "").isEmpty
              ? "Questions and student results"
              : q.description!,
        ),
        WebCard(
          padding: const EdgeInsets.fromLTRB(17, 17, 17, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHead(
                  title: "Questions",
                  trailing: (_subject != null && _canManage(_subject!))
                      ? WebButton(
                          label: "Add question",
                          icon: Iconsax.add,
                          kind: WebBtnKind.primary,
                          onTap: () => _addQuestion(q))
                      : null),
              const SizedBox(height: 8),
              FutureBuilder<List<QuizQuestion>>(
                future: _questionsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return _emptyMini(t, "No questions added yet.");
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        _questionTile(t, i, items[i]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                    title: "Results", subtitle: "Scores per student"),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<QuizResult>>(
                future: _resultsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return _emptyMini(
                        t, "No students have attempted this quiz.");
                  }
                  return WebTable(
                    columns: const [
                      WebCol("Student", flex: 3),
                      WebCol("Score", flex: 2, right: true),
                      WebCol("Percent", flex: 2, right: true),
                      WebCol("Submitted", flex: 2, right: true),
                    ],
                    rows: [
                      for (final r in items)
                        [
                          Text(r.studentName ?? "Student",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text("${r.score}/${r.totalPoints}"),
                          Align(
                            alignment: Alignment.centerRight,
                            child: StatusChip(
                                "${r.percentage.toStringAsFixed(0)}%",
                                tone: _percentTone(r.percentage)),
                          ),
                          Text(r.submittedAt == null
                              ? "—"
                              : Formatters.date(r.submittedAt!)),
                        ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 3c: custom test — mark-sheet style result entry ──
  Widget _customTestDetail(WebTokens t) {
    final ct = _customTest!;
    return _CustomTestMarkSheet(
      test: ct,
      cls: widget.cls,
      assessment: _assessment,
      academics: _academics,
      canManage: _subject != null && _canManage(_subject!),
      onRefreshTests: () {
        if (_subject != null && mounted) setState(_refreshAssessments);
      },
      onEdit: () => _editCustomTest(ct),
      onDelete: () => _deleteCustomTest(ct),
    );
  }

  Future<void> _createCustomTest() async {
    final s = _subject!;
    final t = WebTokens.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: "100");
    DateTime? testDate;
    await showWebModal(
      context: context,
      title: "New custom test",
      saveLabel: "Create",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "e.g. Midterm Exam")),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Description (optional)",
            child: TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _dec(t, hint: "What this test covers")),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WebField(
                  label: "Max marks",
                  child: TextField(
                      controller: marksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(t, hint: "100")),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebField(
                  label: "Test date (optional)",
                  child: _dateField(t, testDate, () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: testDate ?? DateTime.now(),
                    );
                    if (picked != null) setSt(() => testDate = picked);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        if (titleCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter a title");
          return false;
        }
        final marks = int.tryParse(marksCtrl.text.trim()) ?? 100;
        try {
          await _assessment.createCustomTest(CustomTest(
            id: "",
            subjectId: s.id,
            classId: s.classId,
            title: titleCtrl.text.trim(),
            description:
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            testDate: testDate,
            maxMarks: marks,
            createdBy: _uid,
          ));
          SnackbarUtils.showSuccess("Test created");
          if (mounted) setState(_refreshAssessments);
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _editCustomTest(CustomTest ct) async {
    final t = WebTokens.of(context);
    final titleCtrl = TextEditingController(text: ct.title);
    final descCtrl = TextEditingController(text: ct.description);
    final marksCtrl = TextEditingController(text: "${ct.maxMarks}");
    DateTime? testDate = ct.testDate;
    await showWebModal(
      context: context,
      title: "Edit custom test",
      saveLabel: "Save",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "e.g. Midterm Exam")),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Description (optional)",
            child: TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _dec(t, hint: "What this test covers")),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WebField(
                  label: "Max marks",
                  child: TextField(
                      controller: marksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(t, hint: "100")),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebField(
                  label: "Test date (optional)",
                  child: _dateField(t, testDate, () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: testDate ?? DateTime.now(),
                    );
                    if (picked != null) setSt(() => testDate = picked);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        if (titleCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter a title");
          return false;
        }
        final marks = int.tryParse(marksCtrl.text.trim()) ?? 100;
        try {
          final updated = await _assessment.updateCustomTest(CustomTest(
            id: ct.id,
            subjectId: ct.subjectId,
            classId: ct.classId,
            title: titleCtrl.text.trim(),
            description:
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            testDate: testDate,
            maxMarks: marks,
            createdBy: ct.createdBy,
          ));
          SnackbarUtils.showSuccess("Test updated");
          if (mounted) {
            setState(() {
              _customTest = updated;
              _refreshAssessments();
            });
          }
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _deleteCustomTest(CustomTest ct) async {
    final confirm = await DialogUtils.showConfirmation(
      context: context,
      title: "Delete custom test",
      message:
          "Are you sure you want to delete '${ct.title}'? This cannot be undone.",
      confirmText: "Delete",
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      await _assessment.deleteCustomTest(ct.id);
      SnackbarUtils.showSuccess("Test deleted");
      if (mounted) {
        setState(() {
          _customTest = null;
          _refreshAssessments();
        });
      }
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    }
  }

  Widget _questionTile(WebTokens t, int index, QuizQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Q${index + 1}.",
                  style: TextStyle(
                      color: t.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(q.question,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
              Text("${q.points} pt${q.points == 1 ? "" : "s"}",
                  style: TextStyle(color: t.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    i == q.correctIndex
                        ? Iconsax.tick_circle
                        : Iconsax.record_circle,
                    size: 15,
                    color: i == q.correctIndex ? t.success : t.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.options[i],
                        style: TextStyle(
                            color: i == q.correctIndex ? t.ink : t.muted,
                            fontSize: 11.5,
                            fontWeight: i == q.correctIndex
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createAssignment() async {
    final s = _subject!;
    final t = WebTokens.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: "100");
    DateTime? due;
    await showWebModal(
      context: context,
      title: "New assignment",
      saveLabel: "Create",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "e.g. Chapter 3 worksheet")),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Description (optional)",
            child: TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _dec(t, hint: "Instructions for students")),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WebField(
                  label: "Max points",
                  child: TextField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(t, hint: "100")),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebField(
                  label: "Due date (optional)",
                  child: _dateField(t, due, () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: due ?? DateTime.now(),
                    );
                    if (picked != null) setSt(() => due = picked);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        if (titleCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter a title");
          return false;
        }
        final pts = int.tryParse(pointsCtrl.text.trim()) ?? 100;
        try {
          await _assessment.createAssignment(Assignment(
            id: "",
            subjectId: s.id,
            classId: s.classId,
            title: titleCtrl.text.trim(),
            description:
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            dueDate: due,
            maxPoints: pts,
            createdBy: _uid,
          ));
          SnackbarUtils.showSuccess("Assignment created");
          if (mounted) setState(_refreshAssessments);
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _createQuiz() async {
    final s = _subject!;
    final t = WebTokens.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showWebModal(
      context: context,
      title: "New quiz",
      saveLabel: "Create",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "e.g. Unit 1 quiz")),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Description (optional)",
            child: TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _dec(t, hint: "What this quiz covers")),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("You can add questions after creating the quiz.",
                style: TextStyle(color: t.muted, fontSize: 10.5)),
          ),
        ],
      ),
      onSave: () async {
        if (titleCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter a title");
          return false;
        }
        try {
          await _assessment.createQuiz(Quiz(
            id: "",
            subjectId: s.id,
            title: titleCtrl.text.trim(),
            description:
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            createdBy: _uid,
          ));
          SnackbarUtils.showSuccess("Quiz created");
          if (mounted) setState(_refreshAssessments);
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _addQuestion(Quiz q) async {
    final t = WebTokens.of(context);
    final questionCtrl = TextEditingController();
    final optCtrls = List.generate(4, (_) => TextEditingController());
    final pointsCtrl = TextEditingController(text: "1");
    int correct = 0;
    await showWebModal(
      context: context,
      title: "New question",
      saveLabel: "Add question",
      body: (ctx, setSt) => Column(
        children: [
          WebField(
            label: "Question",
            child: TextField(
                controller: questionCtrl,
                maxLines: 2,
                decoration: _dec(t, hint: "Enter the question")),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    // ignore: deprecated_member_use
                    groupValue: correct,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setSt(() => correct = v ?? 0),
                  ),
                  Expanded(
                    child: TextField(
                        controller: optCtrls[i],
                        decoration: _dec(t, hint: "Option ${i + 1}")),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Select the radio next to the correct option.",
                style: TextStyle(color: t.muted, fontSize: 10.5)),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Points",
            child: TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec(t, hint: "1")),
          ),
        ],
      ),
      onSave: () async {
        if (questionCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter the question");
          return false;
        }
        final options = optCtrls
            .map((c) => c.text.trim())
            .where((o) => o.isNotEmpty)
            .toList();
        if (options.length < 2) {
          SnackbarUtils.showWarning("Add at least two options");
          return false;
        }
        if (correct >= options.length) {
          SnackbarUtils.showWarning("Pick a correct option that has text");
          return false;
        }
        try {
          await _assessment.addQuestion(QuizQuestion(
            id: "",
            quizId: q.id,
            question: questionCtrl.text.trim(),
            options: options,
            correctIndex: correct,
            points: int.tryParse(pointsCtrl.text.trim()) ?? 1,
          ));
          SnackbarUtils.showSuccess("Question added");
          if (mounted) {
            setState(() {
              _questionsFuture = _assessment.questions(q.id);
            });
          }
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Widget _dateField(WebTokens t, DateTime? value, VoidCallback onTap) {
    return Material(
      color: t.panel2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(Iconsax.calendar_1, size: 15, color: t.muted),
              const SizedBox(width: 8),
              Text(value == null ? "Select date" : Formatters.date(value),
                  style: TextStyle(
                      color: value == null ? t.muted : t.ink, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gradeSubmission(Submission s, Assignment a) async {
    final t = WebTokens.of(context);
    final gradeCtrl =
        TextEditingController(text: s.grade == null ? "" : "${s.grade}");
    final feedbackCtrl = TextEditingController(text: s.feedback ?? "");
    await showWebModal(
      context: context,
      title: "Grade ${s.studentName ?? "submission"}",
      saveLabel: "Save grade",
      body: (ctx, setState) => Column(
        children: [
          WebField(
            label: "Grade (out of ${a.maxPoints})",
            child: TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(t, hint: "e.g. 85"),
            ),
          ),
          const SizedBox(height: 12),
          WebField(
            label: "Feedback (optional)",
            child: TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: _dec(t, hint: "Notes for the student"),
            ),
          ),
        ],
      ),
      onSave: () async {
        final g = num.tryParse(gradeCtrl.text.trim());
        if (g == null) {
          SnackbarUtils.showWarning("Enter a valid grade");
          return false;
        }
        if (g < 0 || g > a.maxPoints) {
          SnackbarUtils.showWarning(
              "Grade must be between 0 and ${a.maxPoints}");
          return false;
        }
        try {
          await _assessment.grade(
              s.id,
              g,
              feedbackCtrl.text.trim().isEmpty
                  ? null
                  : feedbackCtrl.text.trim());
          SnackbarUtils.showSuccess("Grade saved");
          if (mounted) {
            setState(() {
              _submissionsFuture = _assessment.submissions(a.id);
            });
          }
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) SnackbarUtils.showError("Couldn't open the file");
    } catch (e) {
      SnackbarUtils.showError("Couldn't open the file");
    }
  }

  InputDecoration _dec(WebTokens t, {String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: t.panel2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.line),
        ),
      );

  Tone _submissionTone(SubmissionStatus s) {
    switch (s) {
      case SubmissionStatus.graded:
        return Tone.success;
      case SubmissionStatus.late:
        return Tone.danger;
      case SubmissionStatus.returned:
        return Tone.warning;
      case SubmissionStatus.submitted:
        return Tone.info;
    }
  }

  Tone _percentTone(double p) {
    if (p >= 75) return Tone.success;
    if (p >= 50) return Tone.warning;
    return Tone.danger;
  }

  int _cols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 900) return 1;
    if (w < 1280) return 2;
    return 3;
  }

  String _initial(String s) =>
      s.trim().isEmpty ? "?" : s.trim()[0].toUpperCase();

  Widget _loading() => const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _emptyMini(WebTokens t, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(17, 4, 17, 20),
        child: Text(text, style: TextStyle(color: t.muted, fontSize: 11)),
      );

  Widget _empty(WebTokens t, IconData icon, String title, String sub) =>
      WebCard(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 34, color: t.muted),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      color: t.ink, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(color: t.muted, fontSize: 11)),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// Mark-sheet style custom test result entry
// ══════════════════════════════════════════════════════════════

class _CustomTestMarkSheet extends StatefulWidget {
  final CustomTest test;
  final SchoolClass cls;
  final AssessmentRepository assessment;
  final AcademicsRepository academics;
  final bool canManage;
  final VoidCallback onRefreshTests;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomTestMarkSheet({
    required this.test,
    required this.cls,
    required this.assessment,
    required this.academics,
    required this.canManage,
    required this.onRefreshTests,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CustomTestMarkSheet> createState() => _CustomTestMarkSheetState();
}

class _CustomTestMarkSheetState extends State<_CustomTestMarkSheet> {
  bool _loading = true;
  bool _saving = false;
  List<Enrollment> _students = [];
  Map<String, TestResult> _existingResults = {};

  // Controllers keyed by studentId
  final Map<String, TextEditingController> _marksCtrls = {};
  final Map<String, TextEditingController> _remarksCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final enrollments = await widget.academics.enrollments(widget.cls.id);
      final results = await widget.assessment.testResults(widget.test.id);
      final resultMap = <String, TestResult>{};
      for (final r in results) {
        resultMap[r.studentId] = r;
      }
      for (final e in enrollments) {
        final existing = resultMap[e.studentId];
        _marksCtrls[e.studentId] = TextEditingController(
            text: existing != null ? "${existing.obtainedMarks}" : "");
        _remarksCtrls[e.studentId] =
            TextEditingController(text: existing?.remarks ?? "");
      }
      if (mounted) {
        setState(() {
          _students = enrollments;
          _existingResults = resultMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final results = <TestResult>[];
      for (final e in _students) {
        final marksText = _marksCtrls[e.studentId]?.text.trim() ?? "";
        if (marksText.isEmpty) continue; // skip students with no marks entered
        final marks = num.tryParse(marksText);
        if (marks == null) continue;
        final remarks = _remarksCtrls[e.studentId]?.text.trim();
        results.add(TestResult(
          id: "",
          testId: widget.test.id,
          studentId: e.studentId,
          obtainedMarks: marks,
          remarks: (remarks ?? "").isEmpty ? null : remarks,
        ));
      }
      if (results.isEmpty) {
        SnackbarUtils.showWarning("Enter marks for at least one student");
        setState(() => _saving = false);
        return;
      }
      await widget.assessment.upsertTestResults(results);
      SnackbarUtils.showSuccess(
          "Results saved for ${results.length} student${results.length == 1 ? "" : "s"}");
      // Reload to update existing results
      await _loadData();
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    for (final c in _marksCtrls.values) {
      c.dispose();
    }
    for (final c in _remarksCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final ct = widget.test;
    return WebPageBody(
      children: [
        WebPageHead(
          title: ct.title,
          subtitle:
              "${ct.testDate == null ? "No date set" : "Date: ${Formatters.date(ct.testDate!)}"}  •  Max ${ct.maxMarks} marks",
          actions: widget.canManage
              ? [
                  WebButton(
                    label: "Edit",
                    icon: Iconsax.edit_2,
                    kind: WebBtnKind.secondary,
                    onTap: widget.onEdit,
                  ),
                  SizedBox(width: 8),
                  WebButton(
                    label: "Delete",
                    icon: Iconsax.trash,
                    kind: WebBtnKind.danger,
                    onTap: widget.onDelete,
                  ),
                  const SizedBox(width: 8),
                  WebButton(
                    label: _saving ? "Saving…" : "Save all results",
                    icon: Iconsax.tick_circle,
                    kind: WebBtnKind.success,
                    onTap: _saving ? null : _saveAll,
                  ),
                ]
              : [],
        ),
        if ((ct.description ?? "").isNotEmpty) ...[
          WebCard(
            padding: const EdgeInsets.all(16),
            child: Text(ct.description!,
                style: TextStyle(color: t.ink, fontSize: 12, height: 1.5)),
          ),
          const SizedBox(height: 17),
        ],
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                  title: "Student Results",
                  subtitle: widget.canManage
                      ? "Enter marks for each student and click Save all results"
                      : "Results overview",
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_students.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 4, 17, 20),
                  child: Text("No students enrolled in this class.",
                      style: TextStyle(color: t.muted, fontSize: 11)),
                )
              else
                _buildMarkSheet(t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkSheet(WebTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 17),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
          4: FixedColumnWidth(70),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line, width: 1.5)),
            ),
            children: [
              _headerCell(t, "#"),
              _headerCell(t, "Student"),
              _headerCell(t, "Marks / ${widget.test.maxMarks}"),
              _headerCell(t, "Remarks"),
              _headerCell(t, "Status"),
            ],
          ),
          // Rows
          for (int i = 0; i < _students.length; i++)
            _studentRow(t, i, _students[i]),
        ],
      ),
    );
  }

  Widget _headerCell(WebTokens t, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(label,
          style: TextStyle(
              color: t.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4)),
    );
  }

  TableRow _studentRow(WebTokens t, int index, Enrollment e) {
    final existing = _existingResults[e.studentId];
    final hasGrade = existing != null;
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.transparent : t.panel2,
        border: Border(bottom: BorderSide(color: t.line, width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text("${index + 1}",
              style: TextStyle(
                  color: t.muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.studentName ?? "Student",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.ink, fontSize: 12, fontWeight: FontWeight.w700)),
              if (e.rollNo != null)
                Text("Roll: ${e.rollNo}",
                    style: TextStyle(color: t.muted, fontSize: 9.5)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: widget.canManage
              ? SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _marksCtrls[e.studentId],
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: t.ink, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "—",
                      isDense: true,
                      filled: true,
                      fillColor: t.panel,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.line),
                      ),
                    ),
                  ),
                )
              : Text(
                  hasGrade
                      ? "${existing.obtainedMarks}/${widget.test.maxMarks}"
                      : "—",
                  style: TextStyle(
                      color: t.ink, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: widget.canManage
              ? SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _remarksCtrls[e.studentId],
                    style: TextStyle(color: t.ink, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: "Optional",
                      isDense: true,
                      filled: true,
                      fillColor: t.panel,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.line),
                      ),
                    ),
                  ),
                )
              : Text(existing?.remarks ?? "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.muted, fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: hasGrade
              ? StatusChip("Saved", tone: Tone.success)
              : StatusChip("Pending", tone: Tone.warning),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Class attendance — mark present / late / absent for a date
// ══════════════════════════════════════════════════════════════

class _ClassAttendance extends StatefulWidget {
  final SchoolClass cls;
  final AcademicsRepository academics;
  final AttendanceRepository attendance;
  final bool canMark;
  final String? markedBy;

  const _ClassAttendance({
    required this.cls,
    required this.academics,
    required this.attendance,
    required this.canMark,
    this.markedBy,
  });

  @override
  State<_ClassAttendance> createState() => _ClassAttendanceState();
}

class _ClassAttendanceState extends State<_ClassAttendance> {
  DateTime _date = DateTime.now();
  List<Enrollment> _students = [];
  final Map<String, AttendanceStatus> _marks = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final enr = await widget.academics.enrollments(widget.cls.id);
      final existing =
          await widget.attendance.forClassOnDate(widget.cls.id, _date);
      final map = {for (final r in existing) r.studentId: r.status};
      if (!mounted) return;
      setState(() {
        _students = enr;
        _marks
          ..clear()
          ..addEntries(enr.map((e) => MapEntry(
              e.studentId, map[e.studentId] ?? AttendanceStatus.present)));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _load();
    }
  }

  Future<void> _save() async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final records = _students
          .map((e) => AttendanceRecord(
                id: "",
                classId: widget.cls.id,
                studentId: e.studentId,
                date: _date,
                status: _marks[e.studentId] ?? AttendanceStatus.present,
                markedBy: widget.markedBy,
              ))
          .toList();
      await widget.attendance.saveBatch(records);
      SnackbarUtils.showSuccess("Attendance saved");
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _count(AttendanceStatus s) => _marks.values.where((v) => v == s).length;

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebPageBody(
      children: [
        WebPageHead(
          title: "Attendance",
          subtitle: "${widget.cls.displayName}  •  ${Formatters.date(_date)}",
          actions: [
            WebButton(
                label: "Change date",
                icon: Iconsax.calendar_1,
                onTap: _pickDate),
            if (widget.canMark) ...[
              const SizedBox(width: 8),
              WebButton(
                  label: _saving ? "Saving…" : "Save attendance",
                  icon: Iconsax.tick_circle,
                  kind: WebBtnKind.primary,
                  onTap: _saving ? null : _save),
            ],
          ],
        ),
        WebGrid(
          columns: MediaQuery.of(context).size.width < 1180 ? 2 : 4,
          childAspectRatio: 3.1,
          children: [
            _summary(t, Iconsax.tick_circle, "Present",
                "${_count(AttendanceStatus.present)}", Tone.success),
            _summary(t, Iconsax.clock, "Late", "${_count(AttendanceStatus.late)}",
                Tone.warning),
            _summary(t, Iconsax.close_circle, "Absent",
                "${_count(AttendanceStatus.absent)}", Tone.danger),
            _summary(t, Iconsax.people, "Students", "${_students.length}",
                Tone.primary),
          ],
        ),
        const SizedBox(height: 17),
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                child: SectionHead(
                  title: "Mark attendance",
                  subtitle: widget.canMark
                      ? "Tap a status for each student, then Save."
                      : "Attendance overview",
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()))
              else if (_students.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 4, 17, 20),
                  child: Text(
                      "No students enrolled in this class yet. Enroll students first.",
                      style: TextStyle(color: t.muted, fontSize: 11)),
                )
              else
                WebTable(
                  columns: const [
                    WebCol("Student", flex: 4),
                    WebCol("Roll", flex: 2),
                    WebCol("Status", flex: 5),
                  ],
                  rows: [
                    for (final e in _students)
                      [
                        Row(children: [
                          Monogram(Formatters.initials(e.studentName)),
                          const SizedBox(width: 9),
                          Flexible(
                              child: Text(e.studentName ?? "Student",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                        ]),
                        Text(e.rollNo ?? "—"),
                        _markGroup(t, e.studentId),
                      ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _markGroup(WebTokens t, String studentId) {
    final current = _marks[studentId] ?? AttendanceStatus.present;
    return Wrap(
      spacing: 5,
      children: [
        _markBtn(t, "Present", AttendanceStatus.present, current, studentId,
            Tone.success),
        _markBtn(t, "Absent", AttendanceStatus.absent, current, studentId,
            Tone.danger),
        _markBtn(
            t, "Late", AttendanceStatus.late, current, studentId, Tone.warning),
        _markBtn(t, "Excused", AttendanceStatus.excused, current, studentId,
            Tone.info),
      ],
    );
  }

  Widget _markBtn(WebTokens t, String label, AttendanceStatus s,
      AttendanceStatus current, String studentId, Tone tone) {
    final active = s == current;
    return InkWell(
      onTap: widget.canMark
          ? () => setState(() => _marks[studentId] = s)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: active ? tone.bg(t) : t.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.transparent : t.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: active ? tone.fg(t) : t.muted)),
      ),
    );
  }

  Widget _summary(
      WebTokens t, IconData icon, String label, String value, Tone tone) {
    return WebCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
                color: tone.bg(t), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: tone.fg(t)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: t.muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: t.ink, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
