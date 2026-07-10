import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/presentation/modules/home/controller/home_controller.dart";
import "package:edulink/presentation/modules/shell/controller/shell_controller.dart";

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShellController(session: Get.find<SessionController>()));
    Get.put(
      HomeController(
        session: Get.find<SessionController>(),
        reportRepo: Get.find<ReportRepository>(),
        academicsRepo: Get.find<AcademicsRepository>(),
        financeRepo: Get.find<FinanceRepository>(),
      ),
    );
  }
}
