import 'dart:convert';
import 'package:http/http.dart';

class Api {
  static const host = ""; // Change to the base URL of the API
  String? username;
  String? _password;
  String? authorization;
  bool authorized = false;
  User? _user;

  set password(String password) => _password = password;
  User get user => _user!;

  static const GET = "get";
  static const POST = "post";

  Future<Response?> _doRequest(method, String route, [Map<String, String>? header, body]) async {
    if (!authorized) {
      return null;
    }
    final url = Uri.https(host, route);
    final headers = {"Authorization": authorization!, ...?header};
    Response response;
    switch (method) {
      case POST:
        response = await post(url, headers: headers, body: body);
        break;
      default:
        response = await get(url, headers: headers);
        break;
    }

    if (response.statusCode == 401 && await auth()) {
      return _doRequest(method, route, header, body);
    } else {
      return response;
    }
  }

  Future<bool> auth() async {
    final url = Uri.https(host, "login");
    final response = await post(url, body: {"user": username, "password": _password});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = User.fromJson(data);
      authorization = "${data["type"]} ${data["token"]}";
      authorized = true;
    } else {
      authorized = false;
    }
    return authorized;
  }

  Future<String?> getQRToken() async {
    final response = await _doRequest(GET, "ticket");
    if (response != null && response.statusCode == 200) {
      return jsonDecode(response.body)["token"];
    }
    return null;
  }

  Future<MapEntry<bool, String>?> validateToken(String token) async {
    final response = await _doRequest(POST, "ticket", {
      "Content-Type": "application/json"
    }, jsonEncode({
      "ticket": token
    }));
    if (response != null) {
      return MapEntry(response.statusCode == 200, response.body);
    }
    return null;
  }

  Future<Statistic?> getStatistic() async {
    final response = await _doRequest(GET, "statistic/tickets");
    if (response != null) {
      return Statistic.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}

class User {
  final int id;
  final String display;
  final String school;

  const User({required this.id, required this.display, required this.school});

  User.fromJson(Map<String, dynamic> json) : this(
      id: json["user"],
      display: json["display"],
      school: json["school"]);
}

class Statistic {
  final int user;
  final int school;
  final int total;

  const Statistic({required this.user, required this.school, required this.total});

  Statistic.fromJson(Map<String, dynamic> json) : this(
      user: json["self"],
      school: json["school"],
      total: json["total"]);
}

final api = Api();
