class User {
  String? userId;
  String? email;
  String? firstName;
  String? lastName;
  String? username;
  String? role; // 'user' | 'admin'
  String? status; // 'online' | 'offline'
  bool? archived;
  DateTime? createdAt;
  String? token;
  String? refreshToken;

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.role,
    required this.status,
    required this.archived,
    required this.createdAt,
    required this.token,
    this.refreshToken
  });

  // Getter pembantu untuk mengambil nama tampilan pengguna secara konsisten
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    if (username != null && username!.isNotEmpty) return username!;
    return 'Pengguna';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Mendukung kunci 'userId' (camelCase) maupun 'user_id' / 'id' (snake_case)
      userId: json['userId'] ?? json['user_id'] ?? json['id'],
      email: json['email'],
      // Mendukung kunci 'firstName' (camelCase) maupun 'first_name' (snake_case)
      firstName: json['firstName'] ?? json['first_name'],
      // Mendukung kunci 'lastName' (camelCase) maupun 'last_name' (snake_case)
      lastName: json['lastName'] ?? json['last_name'],
      username: json['username'],
      role: json['role'],
      status: json['status'],
      archived: json['archived'],
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString())
          : null,
      token: json['token'] ?? json['accessToken'] ?? json['access_token'],
      refreshToken: json['refreshToken'] ?? json['refresh_token']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'role': role,
      'status': status,
      'archived': archived,
      'createdAt': createdAt?.toIso8601String(),
      'token': token,
      'refreshToken': refreshToken
    };
  }
}