import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../pages/admin/home.dart' as adminHome; 
import '../pages/user/home.dart' as userHome;   
import '../pages/login.dart';                   
class AuthService {
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));

      // Obtener el rol del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      String role = userDoc.get('role'); 

      // Redirigir según el rol
      Widget targetPage;
      if (role == 'Administrador') {
        targetPage = adminHome.Home(); // Usar alias para la página de administrador
      } else {
        targetPage = userHome.Home(); // Usar alias para la página de usuario
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => targetPage,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'El correo electrónico no se encuentra registrado.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error desconocido. Inténtelo de nuevo.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signout({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Login(),
      ),
    );
  }
}
