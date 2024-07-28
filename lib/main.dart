import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'api.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kartenvorverkauf Mittelstufenparty",
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 48, 67, 170),
          foregroundColor: Colors.white
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      // home: const MainWidget(),
      home: const MainWidget()
    );
  }
}

void loginFirst(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Bitte zuerst anmelden")));
  DefaultTabController.of(context).animateTo(2);
}

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kartenvorverkauf Mittelstufenparty"),
          bottom: const TabBar(
            tabs: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tab(icon: Icon(Icons.sell)),
                  Text("Vorverkauf")
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tab(icon: Icon(Icons.verified_user)),
                  Text("Einlass")
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tab(icon: Icon(Icons.bar_chart)),
                  Text("Login/Über"),
                ],
              )
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SellWidget(),
            EntryWidget(),
            LoginWidget()
          ],
        ),
      )
    );
  }
}

class SellWidget extends StatefulWidget {
  const SellWidget({super.key});

  @override
  State<StatefulWidget> createState() => _SellWidget();
}

class _SellWidget extends State<SellWidget> with AutomaticKeepAliveClientMixin<SellWidget> {
  String qrData = "";

  _updateQrData (BuildContext context) async {
    if (!api.authorized) {
      loginFirst(context);
    } else {
      final token = await api.getQRToken();
      setState(() => qrData = Uri.https(Api.host, "online-ticket", {"t": token}).toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: LayoutBuilder(
      builder: (context, constraints) =>
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "digitale Eintrittskarte",
                    style: TextStyle(
                      fontSize: 36
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: qrData != "" ?
                    QrImageView(
                      data: qrData,
                      size: constraints.biggest.shortestSide / 1.5
                    ):const Text(
                      "Klicke auf den kleinen QR-Code,\num eine neue Eintrittskarte abzurufen!",
                      style: TextStyle(
                        fontSize: 18
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.qr_code_2, size: 32),
                  onPressed: () => _updateQrData(context),
                )
            )
          ],
        ),
      ),
    );
  }
}

class EntryWidget extends StatefulWidget {
  const EntryWidget({super.key});

  @override
  State<StatefulWidget> createState() => _EntryWidget();
}

class _EntryWidget extends State<EntryWidget> {
  MapEntry<bool, String>? result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) =>
      Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2)
            ),
            child: QRScanWidget(
              width: constraints.biggest.shortestSide,
              height: constraints.maxHeight / 2,
              onDetect: (value) async {
                if (!api.authorized) {
                  loginFirst(context);
                } else {
                  final response = await api.validateToken(value);
                  setState(() => result = response);
                  Future.delayed(
                      const Duration(milliseconds: 3500),
                          () => setState(() => result = null)
                  );
                }
              },
            ),
          ),
          Text(
            result?.value ?? "",
            style: TextStyle(
              color: result?.key == true ? Colors.green:Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          )
        ],
      )
    );
  }
}

class QRScanWidget extends StatelessWidget {
  final double width;
  final double height;
  final void Function(String value) onDetect;
  const QRScanWidget({super.key, required this.width, required this.height, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionTimeoutMs: 3500
            ),
            onDetect: (cap) {
              final detected = cap.barcodes;
              final value = detected.length <= 1 ? detected[0].rawValue:null;
              if (value != null) {
                onDetect(value);
              }
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Scanne den QR-Code der Eintrittskarte",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: min(width, height) * 0.67,
                  height: min(width, height) * 0.67,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                      style: BorderStyle.solid
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(32))
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: api.authorized ? AboutWidget(() => setState(() {})):const LoginForm()
    );
  }
}


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<StatefulWidget> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _user = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AutofillGroup(
          child: Column(
            children: [
              TextFormField(
                controller: _user,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                    labelText: "Benutzername",
                    border: OutlineInputBorder()
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Bitte Benutzernamen eingeben";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: "Passwort",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return "Bitte richtiges Passwort eingeben";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                child: const Text("Anmelden"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    api.username = _user.text;
                    api.password = _password.text;
                    final state = await api.auth();

                    if (state) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        FocusScope.of(context).unfocus();
                        DefaultTabController.of(context).animateTo(0);
                      }
                    } else {
                      _password.text = "";
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(
                                "ungültiger Benutzername oder falsches Passwort")
                            )
                        );
                      }
                    }
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AboutWidget extends StatefulWidget {
  final Function rebuild;
  const AboutWidget(this.rebuild, {super.key});

  @override
  State<AboutWidget> createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  late Timer _timer;
  late List<ChartData> _chartData;

  @override
  void initState() {
    super.initState();
    _chartData = [
      ChartData("Nutzer", 0),
      ChartData("Schule", 0),
      ChartData("Gesamt", 0)
    ];
    updateChartData();
    _timer = Timer.periodic(const Duration(minutes: 3), (t) => updateChartData());
  }

  void updateChartData() async {
    final data = (await api.getStatistic())!;
    setState(() {
    _chartData[0].value = data.user;
    _chartData[1].value = data.school;
    _chartData[2].value = data.total;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("angemeldet als: ", style: TextStyle(fontSize: 16)),
                  Text("${api.user.display} (${api.user.school})", style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  )),
                ],
              ),
              ElevatedButton.icon(
                label: const Text("Abmelden"),
                icon: const Icon(Icons.logout),
                onPressed: () {
                  api.authorized = false;
                  widget.rebuild();
                },
              )
            ]),
          SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            series: [
              ColumnSeries<ChartData, String>(
                animationDelay: 200,
                animationDuration: 750,
                color: Colors.indigo,
                dataSource: _chartData,
                xValueMapper: (data, _) => data.label,
                yValueMapper: (data, _) => data.value)
            ],
          )
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  int value;

  ChartData(this.label, this.value);
}
