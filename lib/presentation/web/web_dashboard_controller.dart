import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/institute_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/domain/entities/announcement.dart";
import "package:edulink/domain/entities/expense.dart";
import "package:edulink/domain/entities/institute.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/invoice_item.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/domain/entities/payment.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";

/// Loads and holds institute-wide data for the web dashboard, reusing the
/// existing repositories so the web version shares the app's real logic.
class WebDashboardController extends GetxController {
  final _session = Get.find<SessionController>();
  final _reports = Get.find<ReportRepository>();
  final _finance = Get.find<FinanceRepository>();
  final _academics = Get.find<AcademicsRepository>();
  final _comm = Get.find<CommunicationRepository>();
  final _institutes = Get.find<InstituteRepository>();

  final isLoading = true.obs;
  final Rxn<Institute> institute = Rxn<Institute>();
  final RxMap<String, int> overview = <String, int>{}.obs;
  final RxMap<String, num> finance = <String, num>{}.obs;
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<SchoolClass> classes = <SchoolClass>[].obs;
  final RxList<Profile> students = <Profile>[].obs;
  final RxList<Profile> teachers = <Profile>[].obs;
  final RxList<Profile> parents = <Profile>[].obs;
  final RxList<Announcement> announcements = <Announcement>[].obs;

  // Parent-scoped data.
  final RxList<ParentLink> children = <ParentLink>[].obs;
  final RxList<Invoice> childrenInvoices = <Invoice>[].obs;
  final RxString _resolvedInstituteId = "".obs;

  String get instituteId =>
      _session.instituteId ?? (_resolvedInstituteId.value);

  num get collected => finance["collected"] ?? 0;
  num get billed => finance["billed"] ?? 0;
  num get outstanding => finance["outstanding"] ?? 0;
  int get pendingInvoices => (finance["pendingInvoices"] ?? 0).toInt();
  num get paidExpense =>
      expenses.where((e) => e.isPaid).fold<num>(0, (s, e) => s + e.amount);
  num get pendingExpense =>
      expenses.where((e) => !e.isPaid).fold<num>(0, (s, e) => s + e.amount);
  num get net => collected - paidExpense;
  double get collectionRate => billed == 0 ? 0 : (collected / billed);

  List<Profile> get allPeople => [...students, ...teachers, ...parents];

  // ── Parent-scoped getters ──
  int get childrenCount => children.length;
  num get childrenFeesDue =>
      childrenInvoices.fold<num>(0, (s, i) => s + i.balance);
  num get childrenFeesPaid =>
      childrenInvoices.fold<num>(0, (s, i) => s + i.amountPaid);
  int get childrenUnpaidSlips =>
      childrenInvoices.where((i) => i.balance > 0).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (_session.role.isParent) {
      await _loadParent();
      return;
    }
    await _loadInstitute();
  }

  Future<void> _loadInstitute() async {
    final id = instituteId;
    if (id.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _institutes.getById(id),
        _reports.instituteOverview(id),
        _reports.financeSummary(id),
        _finance.forInstitute(id),
        _finance.expenses(id),
        _academics.classes(id),
        _academics.peopleByRole(id, "student"),
        _academics.peopleByRole(id, "teacher"),
        _academics.peopleByRole(id, "parent"),
        _comm.announcements(id),
      ]);
      institute.value = results[0] as Institute?;
      overview.assignAll(results[1] as Map<String, int>);
      finance.assignAll(results[2] as Map<String, num>);
      invoices.assignAll(results[3] as List<Invoice>);
      expenses.assignAll(results[4] as List<Expense>);
      classes.assignAll(results[5] as List<SchoolClass>);
      students.assignAll(results[6] as List<Profile>);
      teachers.assignAll(results[7] as List<Profile>);
      parents.assignAll(results[8] as List<Profile>);
      announcements.assignAll(results[9] as List<Announcement>);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadParent() async {
    isLoading.value = true;
    try {
      final uid = _session.userId;
      if (uid == null) return;

      final kids = await _academics.childrenOfParent(uid);
      children.assignAll(kids);
      final ids = kids.map((c) => c.studentId).toList();
      childrenInvoices.assignAll(
          ids.isEmpty ? <Invoice>[] : await _finance.forStudents(ids));

      // Resolve the parent's institute from a child if it isn't set yet, so
      // announcements/timetable/chat and the shell work for them.
      var instId = _session.instituteId ?? "";
      if (instId.isEmpty && ids.isNotEmpty) {
        final childProfile = await _academics.findById(ids.first);
        instId = childProfile?.instituteId ?? "";
        if (instId.isNotEmpty) {
          await _academics.assignInstitute(uid, instId);
          await _session.refreshProfile();
        }
      }
      _resolvedInstituteId.value = instId;

      if (instId.isNotEmpty) {
        institute.value = await _institutes.getById(instId);
        announcements.assignAll(await _comm.announcements(instId));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadChildrenFinance() async {
    final ids = children.map((c) => c.studentId).toList();
    childrenInvoices.assignAll(
        ids.isEmpty ? <Invoice>[] : await _finance.forStudents(ids));
  }

  // ── Actions (reuse existing repositories) ──
  Future<void> addExpense(Expense e) async {
    await _finance.createExpense(e);
    await load();
  }

  Future<void> updateExpense(String id, Expense e) async {
    await _finance.updateExpense(id, e);
    await load();
  }

  Future<void> deleteExpense(String id) async {
    await _finance.deleteExpense(id);
    await load();
  }

  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    await _finance.create(invoice, items: items);
    await load();
  }

  /// Records a payment against an invoice (mirrors the mobile pay flow) and
  /// refreshes the dashboard so balances/status update.
  Future<void> recordPayment({
    required Invoice invoice,
    required num amount,
    String? reference,
    required String method,
  }) async {
    await _finance.recordPayment(
      Payment(
        id: "",
        invoiceId: invoice.id,
        amount: amount,
        method: method,
        reference: reference,
        recordedBy: _session.userId,
      ),
      invoice,
    );
    await load();
  }

  Future<void> postAnnouncement(Announcement a) async {
    await _comm.post(a);
    await load();
  }

  Future<void> addMember(String email, String instituteId) async {
    final profile = await _academics.findByEmail(email);
    if (profile == null) {
      throw "No account found for $email. Ask them to register first.";
    }
    await _academics.assignInstitute(profile.id, instituteId);
    await load();
  }

  /// Manually creates a new member (account + role-specific details) and
  /// refreshes the dashboard data.
  Future<void> createMember({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? enrollClassId,
    String? rollNo,
    String? classTeacherOfId,
    String? childStudentId,
    String? relation,
  }) async {
    await _academics.createMember(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      instituteId: instituteId,
      phone: phone,
      enrollClassId: enrollClassId,
      rollNo: rollNo,
      classTeacherOfId: classTeacherOfId,
      childStudentId: childStudentId,
      relation: relation,
    );
    await load();
  }

  /// Updates an existing member's editable details and refreshes the lists.
  Future<void> updatePerson({
    required String userId,
    required String fullName,
    String? phone,
    UserRole? role,
  }) async {
    await _academics.updatePerson(
      userId: userId,
      fullName: fullName,
      phone: phone,
      role: role,
    );
    await load();
  }

  /// Removes a member from the institute and refreshes the lists.
  Future<void> removePerson(String userId) async {
    await _academics.removeFromInstitute(userId);
    await load();
  }
}
