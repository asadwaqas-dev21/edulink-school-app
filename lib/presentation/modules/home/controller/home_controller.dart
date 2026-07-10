import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";

class HomeController extends GetxController {
  final SessionController session;
  final ReportRepository reportRepo;
  final AcademicsRepository academicsRepo;
  final FinanceRepository financeRepo;

  HomeController({
    required this.session,
    required this.reportRepo,
    required this.academicsRepo,
    required this.financeRepo,
  });

  final RxBool isLoading = false.obs;

  // Principal
  final RxMap<String, int> overview = <String, int>{}.obs;
  final RxMap<String, num> finance = <String, num>{}.obs;

  // Teacher
  final RxList<SchoolClass> myClasses = <SchoolClass>[].obs;
  final RxList<Subject> mySubjects = <Subject>[].obs;

  // Student
  final RxList<Enrollment> myEnrollments = <Enrollment>[].obs;
  final RxList<Invoice> myInvoices = <Invoice>[].obs;
  final RxDouble attendanceRate = 0.0.obs;

  // Parent
  final RxList<ParentLink> children = <ParentLink>[].obs;
  final RxList<Invoice> childrenInvoices = <Invoice>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final role = session.role;
      final uid = session.userId;
      final instituteId = session.instituteId;

      if (role.isPrincipal && instituteId != null) {
        overview.value = await reportRepo.instituteOverview(instituteId);
        finance.value = await reportRepo.financeSummary(instituteId);
      } else if (role.isTeacher && uid != null) {
        myClasses.value = await academicsRepo.classesForTeacher(uid);
        mySubjects.value = await academicsRepo.subjectsForTeacher(uid);
      } else if (role.isStudent && uid != null) {
        myEnrollments.value = await academicsRepo.enrollmentsForStudent(uid);
        myInvoices.value = await financeRepo.forStudent(uid);
        attendanceRate.value = await reportRepo.attendanceRate(uid);
      } else if (role.isParent && uid != null) {
        children.value = await academicsRepo.childrenOfParent(uid);
        final ids = children.map((c) => c.studentId).toList();
        childrenInvoices.value = await financeRepo.forStudents(ids);
      }
    } catch (_) {
      // Surface errors quietly on the dashboard; feature screens report details.
    } finally {
      isLoading.value = false;
    }
  }

  num get outstandingForChildren =>
      childrenInvoices.fold<num>(0, (sum, i) => sum + i.balance);

  num get outstandingForStudent =>
      myInvoices.fold<num>(0, (sum, i) => sum + i.balance);
}
