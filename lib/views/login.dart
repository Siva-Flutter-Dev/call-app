import 'package:app/services/local_storage.dart';
import 'package:app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_manager.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() =>
      _LoginState();
}

class _LoginState extends State<Login> {

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _passwordController =
  TextEditingController();

  final GlobalKey<FormState>
  _formKey =
  GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  var prefs = AppPrefs.instance;

  @override
  void initState() {
    if(mounted){
      if(prefs.getBool(AppPrefsKeys.rememberMe)){
        AuthManager.instance.updateLoginEmail(prefs.getString(AppPrefsKeys.email)??'');
        AuthManager.instance.updateLoginPassword(prefs.getString(AppPrefsKeys.password)??'');
        AuthManager.instance.updateLoginStatus(true);
        Get.offAll(() => const Home(),
          transition: Transition.fadeIn,
        );
      }
    }
    super.initState();
  }

  @override
  void dispose() {

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _onLogin() async {

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(
      const Duration(seconds: 1),
    );

    AuthManager.instance
        .updateLoginEmail(
      _emailController.text.trim(),
    );

    AuthManager.instance
        .updateLoginPassword(
      _passwordController.text.trim(),
    );

    AuthManager.instance
        .updateLoginStatus(true);

    setState(() {
      _isLoading = false;
    });

    prefs.setString(AppPrefsKeys.email, _emailController.text.trim());
    prefs.setString(AppPrefsKeys.password, _passwordController.text.trim());
    prefs.setBool(AppPrefsKeys.rememberMe, true);

    Get.offAll(
          () => const Home(),
      transition:
      Transition.fadeIn,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {

    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor:
      Colors.white.withValues(
        alpha: 0.08,
      ),

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),

        borderSide: BorderSide(
          color: Colors.white
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),

        borderSide:
        const BorderSide(
          color: Colors.white,
          width: 1.2,
        ),
      ),

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:
            Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF111827),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),

              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,

                  children: [

                    /// LOGO
                    Container(
                      width: 90,
                      height: 90,

                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,

                        color: Colors.white
                            .withValues(
                          alpha: 0.08,
                        ),
                      ),

                      child: const Icon(
                        Icons.video_call,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        color:
                        Colors.white,
                        fontSize: 30,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      "Login to continue your calls",
                      style: TextStyle(
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    /// EMAIL
                    TextFormField(
                      controller:
                      _emailController,

                      keyboardType:
                      TextInputType
                          .emailAddress,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                      ),

                      decoration:
                      _inputDecoration(
                        hint:
                        "Email Address",
                        icon:
                        Icons.email,
                      ),

                      validator: (
                          value,
                          ) {

                        if (value ==
                            null ||
                            value
                                .trim()
                                .isEmpty) {
                          return "Enter email";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    /// PASSWORD
                    TextFormField(
                      controller:
                      _passwordController,

                      obscureText:
                      _obscurePassword,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                      ),

                      decoration:
                      _inputDecoration(
                        hint: "Password",
                        icon: Icons.lock,

                        suffixIcon:
                        IconButton(
                          onPressed: () {

                            setState(() {
                              _obscurePassword =
                              !_obscurePassword;
                            });
                          },

                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                .visibility_off
                                : Icons
                                .visibility,
                          ),
                        ),
                      ),

                      validator: (
                          value,
                          ) {

                        if (value ==
                            null ||
                            value
                                .trim()
                                .isEmpty) {
                          return "Enter password";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    /// LOGIN BUTTON
                    SizedBox(
                      width:
                      double.infinity,
                      height: 58,

                      child:
                      ElevatedButton(
                        onPressed:
                        _isLoading
                            ? null
                            : _onLogin,

                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors.white,

                          foregroundColor:
                          Colors.black,

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,

                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Text(
                          "Login",
                          style:
                          TextStyle(
                            fontSize:
                            17,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      "Secure QuickBlox Video Calling",
                      style: TextStyle(
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.55,
                        ),
                        fontSize: 13,
                      ),
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