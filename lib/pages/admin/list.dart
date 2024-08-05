import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart'; // Asegúrate de importar el archivo register.dart
import '../../pages/login.dart';

class ListMessage extends StatelessWidget {
  const ListMessage({Key? key}) : super(key: key);

  Map<String, List<QueryDocumentSnapshot>> _groupUsersByRole(List<QueryDocumentSnapshot> users) {
    return {
      'Administrador': users.where((user) => user['role'] == 'Administrador').toList(),
      'Usuario': users.where((user) => user['role'] == 'Usuario').toList(),
    };
  }

  Future<void> _showUserOptionsDialog(BuildContext context, String userId, bool isActive) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isActive ? 'Desactivar usuario' : 'Activar usuario'),
          content: Text('¿Estás seguro de que deseas ${isActive ? 'desactivar' : 'activar'} este usuario?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance.collection('users').doc(userId).update({'active': !isActive});
              },
              child: Text(isActive ? 'Desactivar' : 'Activar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  
                  if (currentUser != null && currentUser.uid == userId) {
                    await currentUser.delete();
                  } else {
                    print("No se puede eliminar la cuenta de autenticación de otro usuario directamente.");
                  }
                  await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Usuario eliminado correctamente')),
                  );
                } catch (e) {
                  print("Error al eliminar usuario: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar usuario: $e')),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => Login(), 
    ));
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context), 
            ),
          ],
        title: const Text('Usuarios'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          final groupedUsers = _groupUsersByRole(snapshot.data!.docs);

          return ListView(
            children: [
              _buildUserSection('Administradores', groupedUsers['Administrador']!),
              _buildUserSection('Usuarios', groupedUsers['Usuario']!),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userId = user.id;
            final name = user['name'] ?? 'Sin nombre';
            final email = user['email'] ?? 'Sin correo';
            final isActive = user['active'] ?? false;

            return ListTile(
              title: Text(name),
              subtitle: Text(email),
              trailing: Text(isActive ? 'Activo' : 'Inactivo'),
              onTap: () {
                _showUserOptionsDialog(context, userId, isActive);
              },
            );
          },
        ),
      ],
    );
  }
}
