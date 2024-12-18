import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// Model Pengguna
class User {
  final int? id;
  final String name;
  final int age;

  User({this.id, required this.name, required this.age});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, age: $age}';
  }
}

// Database Helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    String path = p.join(await getDatabasesPath(), dbName); // Perbaikan
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<List<User>> fetchUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<User>> searchUsers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });
  }
}

// Flutter App
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Demo',
      home: UserList(),
    );
  }
}

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    users = await dbHelper.fetchUsers();
    setState(() {});
  }

  void _addUser(String name, int age) async {
    await dbHelper.insertUser(User(name: name, age: age));
    _showSuccessMessage('Pengguna berhasil ditambahkan');
    _loadUsers();
  }

  void _updateUser(User user, String name, int age) async {
    user = User(id: user.id, name: name, age: age);
    await dbHelper.updateUser(user);
    _showSuccessMessage('Pengguna berhasil diperbarui');
    _loadUsers();
  }

  void _deleteUser(int id) async {
    await dbHelper.deleteUser(id);
    _showSuccessMessage('Pengguna berhasil dihapus');
    _loadUsers();
  }

  void _searchUsers(String query) async {
    users = await dbHelper.searchUsers(query);
    setState(() {});
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Pengguna Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: 'Usia'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              String name = nameController.text;
              int age = int.parse(ageController.text);
              _addUser(name, age);
              Navigator.of(context).pop();
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengguna'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final searchController = TextEditingController();
                  return AlertDialog(
                    title: Text('Cari Pengguna'),
                    content: TextField(
                      controller: searchController,
                      decoration: InputDecoration(labelText: 'Nama'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          String query = searchController.text;
                          _searchUsers(query);
                          Navigator.of(context).pop();
                        },
                        child: Text('Cari'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index].name),
            subtitle: Text('Usia: ${users[index].age}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    final nameController = TextEditingController(text: users[index].name);
                    final ageController = TextEditingController(text: users[index].age.toString());
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Edit Pengguna'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(labelText: 'Nama'),
                            ),
                            TextField(
                              controller: ageController,
                              decoration: InputDecoration(labelText: 'Usia'),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              String name = nameController.text;
                              int age = int.parse(ageController.text);
                              _updateUser(users[index], name, age);
                              Navigator.of(context).pop();
                            },
                            child: Text('Simpan'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteUser(users[index].id!),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
