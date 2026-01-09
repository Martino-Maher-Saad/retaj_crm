import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/core/constants/app_colors.dart';
import 'package:retaj_crm/core/constants/app_strings.dart';
import 'package:retaj_crm/core/widgets/custom_button.dart';
import 'package:retaj_crm/core/widgets/custom_text_form_field.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../layout/screens/layout_screen.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_states.dart';


class LoginWebScreen extends StatelessWidget {

  const LoginWebScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Builder(
      builder: (context) {
        final authCubit = context.read<AuthCubit>();

        return Scaffold(

          body: Center(
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(32.0),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),

              child: Form(
                key: formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    const Text(
                      AppStrings.login,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.blue28Bold,
                    ),

                    const SizedBox(height: 32),

                    CustomTextFormField(
                      labelText: AppStrings.email,
                      controller: emailController,
                      obscureText: false,
                      validator: (value) => (value == null || value.length < 6) ? "Must be 6+ characters" : null,
                      enabledBorderColor: AppColors.primaryBlueDark,
                      focusedBorderColor: AppColors.greyLight,
                      prefixIcon: Icons.email,
                      prefixIconSize: 20,
                      prefixIconColor: AppColors.primaryBlueDark,
                    ),

                    const SizedBox(height: 20),

                    CustomTextFormField(
                      labelText: AppStrings.password,
                      controller: passwordController,
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 6) ? "Must be 6+ characters" : null,
                      enabledBorderColor: AppColors.primaryBlueDark,
                      focusedBorderColor: AppColors.greyLight,
                      prefixIcon: Icons.lock_outline,
                      prefixIconSize: 20,
                      prefixIconColor: AppColors.primaryBlueDark,
                      suffixIcon: Icons.remove_red_eye,
                      suffixIconSize: 20,
                      suffixIconColor: AppColors.primaryBlueDark,
                    ),

                    const SizedBox(height: 30),

                    BlocConsumer<AuthCubit, AuthStates>(
                      listener: (context, state) {
                        if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                          );
                        }
                      },

                      builder: (context, state) {
                        if (state is AuthLoading) return const Center(child: CircularProgressIndicator());

                        return CustomButton(
                          isCenter: true,
                          title: AppStrings.login,
                          onTap: () {
                            if(formKey.currentState!.validate()) {
                              authCubit.login(emailController.text.trim(), passwordController.text.trim());
                            }
                          },
                          buttonColor: AppColors.primaryBlueDark,
                          titleColor: AppColors.white,
                          titleSize: 22,
                          titleWeight: FontWeight.bold,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
