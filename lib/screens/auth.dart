import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatt_app/widgets/user_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//here we are using "flutter pub add cloud_firestore" to store the metadata

final _firebase = FirebaseAuth
    .instance; //returns an instance which is used for authentication

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  var enteredEmail = '';
  var enteredPassword = '';
  var _isLogin = true;
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _formKey.currentState!
        .validate(); //this would check each validator call

    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    _formKey.currentState!.save(); // save triggers onsaved in textformfield

    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        /* final userCredential = */ await _firebase.signInWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user-images')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef
            .getDownloadURL(); //using this url we will access image for login

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': enteredEmail,
          'image_url': imageUrl,
        });

        //bts firebase manages http requests
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          (SnackBar(content: Text(error.message ?? 'Authentication Failed'))));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isLogin)
                                  UserImagePicker(
                                    onPickImage: (pickedImage) {
                                      _selectedImage = pickedImage;
                                    },
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Email Address'),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    enteredEmail = value!;
                                  },
                                ),
                                if (!_isLogin)
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Username'),
                                    enableSuggestions: false,
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          value.trim().length < 4) {
                                        return 'Enter at least 4 characters';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _enteredUsername = value!;
                                    },
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Password'),
                                  obscureText: true, //hides the text
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length < 6) {
                                      return 'Password must be atleast 6 characters long.';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    enteredPassword = value!;
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (_isAuthenticating)
                                  const CircularProgressIndicator(),
                                if (!_isAuthenticating)
                                  ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    child: Text(_isLogin ? 'Login ' : 'Signup'),
                                  ),
                                if (!_isAuthenticating)
                                  TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                        });
                                      },
                                      child: Text(_isLogin
                                          ? 'Create an account'
                                          : 'I already have an account.'))
                              ],
                            ),
                          )))),
            ],
          ),
        ),
      ),
    );
  }
}
