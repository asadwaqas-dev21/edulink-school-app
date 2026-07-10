import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/presentation/global_widgets/primary_button.dart";
import "package:edulink/presentation/modules/auth/controller/auth_controller.dart";

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: controller.registerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Join your institute",
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text("Choose the role that describes you",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    Text("I am a",
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Obx(
                      () => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: UserRole.values.map((role) {
                          final selected =
                              controller.selectedRole.value == role;
                          final color = AppColors.roleColor(role.key);
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) =>
                                controller.selectedRole.value = role,
                            avatar: Icon(role.icon,
                                size: 18,
                                color: selected ? Colors.white : color),
                            label: Text(role.label),
                            selectedColor: color,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Iconsax.user),
                      ),
                      validator: (v) => Validators.required(v, "Full name"),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Iconsax.sms),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Iconsax.lock),
                          suffixIcon: IconButton(
                            icon: Icon(controller.obscurePassword.value
                                ? Iconsax.eye_slash
                                : Iconsax.eye),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                        obscureText: controller.obscurePassword.value,
                        validator: Validators.password,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => PrimaryButton(
                        text: "Create Account",
                        isLoading: controller.isLoading.value,
                        onPressed: controller.register,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.offAllNamed(AppRoutes.login),
                      child: const Text("I already have an account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
