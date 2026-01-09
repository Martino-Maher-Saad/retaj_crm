import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_states.dart';
import 'features/auth/screens/login_web_screen.dart';
import 'features/layout/screens/layout_screen.dart';



void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://owzahfesxoyqfkilvyck.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93emFoZmVzeG95cWZraWx2eWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5NDE3MjksImV4cCI6MjA4MTUxNzcyOX0.WMPd6r4Ih4Bg-KyLoJ5daLz0SckwQAUSE_w1mZTajjs',
  );

  runApp(
    BlocProvider(
      create: (context) => AuthCubit(AuthRepository(AuthService()))..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retaj CRM',
      home: BlocBuilder<AuthCubit, AuthStates>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return LayoutScreen(user: state.user);
          } else if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }else{
            return const LoginWebScreen();
          }
        },
      ),
    );
  }

}
