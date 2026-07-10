import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/global_widgets/stat_card.dart";

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = Get.find<ReportRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final id = _session.instituteId ?? "";
    final overview = await _repo.instituteOverview(id);
    final finance = await _repo.financeSummary(id);
    return [overview, finance];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final overview = snap.data![0] as Map<String, int>;
          final finance = snap.data![1] as Map<String, num>;
          final billed = finance["billed"] ?? 0;
          final collected = finance["collected"] ?? 0;
          final rate = billed == 0 ? 0.0 : (collected / billed).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("People", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                      icon: Iconsax.book_1,
                      label: "Students",
                      value: "${overview["students"] ?? 0}",
                      color: AppColors.roleStudent),
                  StatCard(
                      icon: Iconsax.teacher,
                      label: "Teachers",
                      value: "${overview["teachers"] ?? 0}",
                      color: AppColors.roleTeacher),
                  StatCard(
                      icon: Iconsax.people,
                      label: "Parents",
                      value: "${overview["parents"] ?? 0}",
                      color: AppColors.roleParent),
                  StatCard(
                      icon: Iconsax.buildings,
                      label: "Classes",
                      value: "${overview["classes"] ?? 0}",
                      color: AppColors.rolePrincipal),
                ],
              ),
              const SizedBox(height: 24),
              Text("Finance", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _financeRow("Total billed", Formatters.money(billed)),
                      const SizedBox(height: 10),
                      _financeRow("Collected", Formatters.money(collected),
                          color: AppColors.success),
                      const SizedBox(height: 10),
                      _financeRow("Outstanding",
                          Formatters.money(finance["outstanding"] ?? 0),
                          color: AppColors.error),
                      const SizedBox(height: 16),
                      Text("Collection rate: ${(rate * 100).toStringAsFixed(0)}%",
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: rate.toDouble(),
                          minHeight: 12,
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.15),
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _financeRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
