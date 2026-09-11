import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';



class MockApiService {
  final Random _random = Random();
  
  // Mock data storage
  final List<User> _users = [];
  
  MockApiService() {
    _initializeMockData();
  }
  
  void _initializeMockData() {
    // Generate mock users
    for (int i = 1; i <= 50; i++) {
      _users.add(User(
        id: 'user_$i',
        email: 'user$i@example.com',
        name: _generateRandomName(),
        avatarUrl: null, //_generateAvatarUrl(i),
        role: _getRandomRole(),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
        isActive: _random.nextBool(),
        department: _getRandomDepartment(),
        phone: '+1 555-${_random.nextInt(900) + 100}-${_random.nextInt(9000) + 1000}',
        lastLogin: DateTime.now().subtract(Duration(hours: _random.nextInt(72))),
      ));
    }
  }
  
  // User endpoints
  Future<List<User>> getUsers({int page = 1, int limit = 10}) async {
    await _simulateNetworkDelay();
    final start = (page - 1) * limit;
    final end = start + limit;
    return _users.sublist(
      start.clamp(0, _users.length),
      end.clamp(0, _users.length),
    );
  }
  
  Future<User?> getUserById(String id) async {
    await _simulateNetworkDelay();
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<User> createUser(User user) async {
    await _simulateNetworkDelay();
    _users.add(user);
    return user;
  }
  
  Future<User> updateUser(User user) async {
    await _simulateNetworkDelay();
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      return user;
    }
    throw Exception('User not found');
  }
  
  Future<void> deleteUser(String id) async {
    await _simulateNetworkDelay();
    _users.removeWhere((user) => user.id == id);
  }
      
  
  // Search functionality
  Future<List<User>> searchUsers(String query) async {
    await _simulateNetworkDelay();
    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             (user.department?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
  
  // Helper methods
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));
  }
  
  String _generateRandomName() {
    final firstNames = ['John', 'Jane', 'Michael', 'Emily', 'David', 'Sarah', 
                       'Robert', 'Lisa', 'James', 'Mary', 'William', 'Patricia',
                       'Richard', 'Jennifer', 'Thomas', 'Elizabeth'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 
                      'Miller', 'Davis', 'Garcia', 'Rodriguez', 'Wilson',
                      'Martinez', 'Anderson', 'Taylor', 'Moore', 'Jackson'];
    
    return '${firstNames[_random.nextInt(firstNames.length)]} '
           '${lastNames[_random.nextInt(lastNames.length)]}';
  }
  
  String _getRandomRole() {
    final roles = ['Admin', 'Manager', 'Developer', 'Designer', 'Analyst', 
                  'Support', 'Sales', 'Marketing'];
    return roles[_random.nextInt(roles.length)];
  }
  
  String _getRandomDepartment() {
    final departments = ['Engineering', 'Sales', 'Marketing', 'HR', 
                        'Finance', 'Operations', 'Support', 'Product'];
    return departments[_random.nextInt(departments.length)];
  }
  
  
  String _getRandomActivity() {
    final activities = [
      'logged in',
      'updated profile',
      'created a new project',
      'completed a task',
      'uploaded a file',
      'sent a message',
      'joined a team',
      'updated settings',
    ];
    return activities[_random.nextInt(activities.length)];
  }
  
  String _getRandomActivityType() {
    final types = ['login', 'update', 'create', 'delete', 'message', 'system'];
    return types[_random.nextInt(types.length)];
  }
  
  String _generateAvatarUrl(int index) {
    // Use reliable services that return proper image formats (PNG/JPG)
    final services = [
      'https://ui-avatars.com/api/?name=User+$index&background=random&color=fff&size=150&format=png',
      'https://robohash.org/user$index?set=set4&size=150x150&format=png',
      'https://ui-avatars.com/api/?name=Person+$index&background=0D8ABC&color=fff&size=150&format=png',
    ];
    
    // Rotate through different services for variety
    return services[index % services.length];
  }
}

// Provider for the mock API service
final mockApiServiceProvider = Provider((ref) => MockApiService());