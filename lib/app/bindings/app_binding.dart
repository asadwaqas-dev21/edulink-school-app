import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/theme_controller.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/data/repositories/attendance_repository.dart";
import "package:edulink/data/repositories/auth_repository.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/data/repositories/course_repository.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/institute_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";

/// Injects core controllers and repositories on app start.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories (single instances, revived if disposed)
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
    Get.lazyPut<InstituteRepository>(() => InstituteRepository(), fenix: true);
    Get.lazyPut<AcademicsRepository>(() => AcademicsRepository(), fenix: true);
    Get.lazyPut<CourseRepository>(() => CourseRepository(), fenix: true);
    Get.lazyPut<AssessmentRepository>(() => AssessmentRepository(), fenix: true);
    Get.lazyPut<AttendanceRepository>(() => AttendanceRepository(), fenix: true);
    Get.lazyPut<FinanceRepository>(() => FinanceRepository(), fenix: true);
    Get.lazyPut<CommunicationRepository>(() => CommunicationRepository(), fenix: true);
    Get.lazyPut<ReportRepository>(() => ReportRepository(), fenix: true);

    // Core controllers (kept alive for the whole app)
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<SessionController>(
      SessionController(authRepository: Get.find<AuthRepository>()),
      permanent: true,
    );
  }
}
