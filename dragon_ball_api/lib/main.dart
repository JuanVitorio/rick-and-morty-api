import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      theme: ThemeData(
        primaryColor: Colors.orange,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Character>> futureCharacters;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureCharacters = ApiService().fetchCharacters();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rick and Morty Personagens', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 70, 158, 44),
      ),
      body: FutureBuilder<List<Character>>(
        future: futureCharacters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No characters found'));
          } else {
            List<Character> characters = snapshot.data!;
            return ListView.builder(
              itemCount: characters.length,
              itemBuilder: (context, index) {
                Character character = characters[index];
                return ListTile(
                  leading: Image.network(character.image),
                  title: Text(character.name),
                  subtitle: Text(character.species),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 117, 218, 87),
        onTap: _onItemTapped,
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  late Future<List<Character>> futureSearchResults;

  @override
  void initState() {
    super.initState();
    futureSearchResults = Future.value([]);
  }

  void _search() {
    setState(() {
      futureSearchResults = ApiService().searchCharacters(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Characters'),
        backgroundColor: Color.fromARGB(255, 70, 158, 44),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by species',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _search();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Character>>(
              future: futureSearchResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No characters found'));
                } else {
                  List<Character> characters = snapshot.data!;
                  return ListView.builder(
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      Character character = characters[index];
                      return ListTile(
                        leading: Image.network(character.image),
                        title: Text(character.name),
                        subtitle: Text(character.species),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Character {
  final String name;
  final String image;
  final String species;

  Character({required this.name, required this.image, required this.species});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      image: json['image'],
      species: json['species'],
    );
  }
}

class ApiService {
  final String apiUrl = 'https://rickandmortyapi.com/api/character';
  //Exibir todos os personagens
  Future<List<Character>> fetchCharacters() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData['results'];
      return data.map((json) => Character.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  Future<List<Character>> searchCharacters(String species) async {
    final response = await http.get(Uri.parse('$apiUrl?species=$species'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData['results'];
      return data.map((json) => Character.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search characters');
    }
  }
}
