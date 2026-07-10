import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/presentation/global_widgets/primary_button.dart";
import "package:edulink/presentation/modules/auth/controller/auth_controller.dart";

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: controller.loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/applogo.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Welcome to Edulink",
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in to your account",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
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
                        text: "Sign In",
                        isLoading: controller.isLoading.value,
                        onPressed: controller.login,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                            style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.register),
                          child: const Text("Create one"),
                        ),
                      ],
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
