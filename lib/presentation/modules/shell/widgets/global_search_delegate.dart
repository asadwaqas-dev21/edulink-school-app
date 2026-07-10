import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/modules/academics/view/class_details_screen.dart";
import "package:edulink/presentation/modules/communication/view/chat_screen.dart";

class _SearchResults {
  final List<Profile> people;
  final List<SchoolClass> classes;
  const _SearchResults(this.people, this.classes);

  bool get isEmpty => people.isEmpty && classes.isEmpty;
}

/// App-wide search across people and classes in the current institute.
class GlobalSearchDelegate extends SearchDelegate<void> {
  final _academics = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  GlobalSearchDelegate() : super(searchFieldLabel: "Search people, classes…");

  Future<_SearchResults> _search(String q) async {
    final institute = _session.instituteId ?? "";
    final results = await Future.wait([
      _academics.searchPeople(institute, q),
      _academics.searchClasses(institute, q),
    ]);
    return _SearchResults(
      results[0] as List<Profile>,
      results[1] as List<SchoolClass>,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: () => query = "",
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Iconsax.arrow_left),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  @override
  Widget buildResults(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    if (query.trim().length < 2) {
      return const _Hint();
    }
    return FutureBuilder<_SearchResults>(
      future: _search(query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data;
        if (data == null || data.isEmpty) {
          return const _Hint(noResults: true);
        }
        return ListView(
          children: [
            if (data.people.isNotEmpty)
              _section(context, "People", "${data.people.length}"),
            ...data.people.map((p) => ListTile(
                  leading: AppAvatar(
                      name: p.fullName,
                      imageUrl: p.avatarUrl,
                      radius: 18,
                      color: AppColors.roleColor(p.role.key)),
                  title: Text(p.fullName),
                  subtitle: Text("${p.role.label}  •  ${p.email}"),
                  trailing: const Icon(Iconsax.message, size: 18),
                  onTap: () {
                    close(context, null);
                    Get.to(() => ChatScreen(contact: p));
                  },
                )),
            if (data.classes.isNotEmpty)
              _section(context, "Classes", "${data.classes.length}"),
            ...data.classes.map((c) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Iconsax.book_1, color: AppColors.primary),
                  ),
                  title: Text(c.displayName),
                  subtitle: Text(c.gradeLevel ?? "Class"),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () {
                    close(context, null);
                    Get.to(() => ClassDetailsScreen(schoolClass: c));
                  },
                )),
          ],
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, String count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(count,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textTertiaryLight)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final bool noResults;
  const _Hint({this.noResults = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(noResults ? Iconsax.search_normal : Iconsax.search_normal_1,
              size: 40, color: AppColors.textTertiaryLight),
          const SizedBox(height: 12),
          Text(
            noResults
                ? "No matches found"
                : "Type at least 2 characters to search",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
