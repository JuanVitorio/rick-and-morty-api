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
  List<Character> characters = [];
  List<Character> filteredCharacters = [];
  int page = 1;
  int searchPage = 1;
  bool isLoading = false;
  bool isSearching = false;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMoreCharacters();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
      if (_selectedIndex == 0) {
        _fetchMoreCharacters();
      } else if (_selectedIndex == 1 && !isSearching) {
        _fetchMoreSearchResults();
      }
    }
  }

  Future<void> _fetchMoreCharacters() async {
    setState(() {
      isLoading = true;
    });
    List<Character> newCharacters = await ApiService().fetchCharacters(page: page);
    setState(() {
      characters.addAll(newCharacters);
      filteredCharacters = characters; // Atualiza a lista filtrada
      page++;
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      filteredCharacters = characters
          .where((character) => character.species
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
      searchPage = 1;
    });
  }

  Future<void> _fetchMoreSearchResults() async {
    setState(() {
      isSearching = true;
    });
    List<Character> moreCharacters = await ApiService().fetchCharacters(page: searchPage);
    setState(() {
      filteredCharacters.addAll(moreCharacters);
      searchPage++;
      isSearching = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rick and Morty Personagens', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 70, 158, 44),
      ),
      body: _selectedIndex == 0 ? _buildCharacterList() : _buildSearch(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Pesquisa',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 117, 218, 87),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCharacterList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: characters.length + 1, // +1 para o indicador de carregamento
      itemBuilder: (context, index) {
        if (index == characters.length) {
          return isLoading ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
        }
        Character character = characters[index];
        return ListTile(
          leading: Image.network(character.image),
          title: Text(character.name),
          subtitle: Text(character.species),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterDetailScreen(character: character),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Procurar por espécie',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredCharacters.length + 1,
            itemBuilder: (context, index) {
              if (index == filteredCharacters.length) {
                return isSearching ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
              }
              Character character = filteredCharacters[index];
              return ListTile(
                leading: Image.network(character.image),
                title: Text(character.name),
                subtitle: Text(character.species),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterDetailScreen(character: character),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class Character {
  final String name;
  final String image;
  final String species;
  final String status;
  final String gender;

  Character({required this.name, required this.image, required this.species, required this.status, required this.gender});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      image: json['image'],
      species: json['species'],
      status: json['status'], 
      gender: json['gender'],
    );
  }
}

class ApiService {
  final String apiUrl = 'https://rickandmortyapi.com/api/character';

  Future<List<Character>> fetchCharacters({int page = 1}) async {
    final response = await http.get(Uri.parse('$apiUrl?page=$page'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData['results'];
      return data.map((json) => Character.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }
}

class CharacterDetailScreen extends StatelessWidget {
  final Character character;

  CharacterDetailScreen({required this.character});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(character.image),
            SizedBox(height: 16),
            Text(
              character.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Espécie: ${character.species}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Status: ${character.status}',
              style: TextStyle(fontSize: 18),
            ),
              Text(
              'Genero: ${character.gender}',
              style: TextStyle(fontSize: 18),
            ),
            // Adicione mais informações do personagem aqui
          ],
        ),
      ),
    );
  }
}
