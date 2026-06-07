import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  late AnimationController
  _animationController;

  late Animation<double>
  _fadeAnimation;

  late Animation<Offset>
  _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 1200,
          ),
        );

    _fadeAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent:
            _animationController,
            curve:
            Curves.easeInOut,
          ),
        );

    _slideAnimation =
        Tween<Offset>(
          begin:
          const Offset(
            0,
            0.2,
          ),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent:
            _animationController,
            curve:
            Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    return BlocListener<
        AuthBloc,
        AuthState>(
      listener: (
          context,
          state,
          ) {
        if (state
        is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
              const HomeScreen(),
            ),
          );
        }

        if (state
        is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration:
          const BoxDecoration(
            gradient:
            LinearGradient(
              begin:
              Alignment
                  .topLeft,
              end:
              Alignment
                  .bottomRight,
              colors: [
                Color(
                  0xFF1E3C72,
                ),
                Color(
                  0xFF2A5298,
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child:
              SingleChildScrollView(
                padding:
                const EdgeInsets
                    .all(
                  24,
                ),
                child:
                FadeTransition(
                  opacity:
                  _fadeAnimation,
                  child:
                  SlideTransition(
                    position:
                    _slideAnimation,
                    child:
                    _loginCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        24,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset:
            const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble,
            size: 80,
            color: Color(
              0xFF2A5298,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'QuickBlox Chat',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Login to continue',
            style: TextStyle(
              color:
              Colors.grey,
            ),
          ),

          const SizedBox(
            height: 32,
          ),

          TextField(
            controller:
            emailController,
            keyboardType:
            TextInputType
                .emailAddress,
            decoration:
            InputDecoration(
              hintText:
              'Email',
              prefixIcon:
              const Icon(
                Icons.email,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
            passwordController,
            obscureText: true,
            decoration:
            InputDecoration(
              hintText:
              'Password',
              prefixIcon:
              const Icon(
                Icons.lock,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          BlocBuilder<
              AuthBloc,
              AuthState>(
            builder:
                (
                context,
                state,
                ) {
              final loading =
              state
              is AuthLoading;

              return SizedBox(
                width: double.infinity,
                height: 55,
                child:
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  onPressed:
                  loading
                      ? null
                      : () {
                    context
                        .read<
                        AuthBloc>()
                        .add(
                      LoginRequested(
                        email:
                        emailController
                            .text
                            .trim(),
                        password:
                        passwordController
                            .text,
                      ),
                    );
                  },
                  child:
                  loading
                      ? const SizedBox(
                    width:
                    22,
                    height:
                    22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}