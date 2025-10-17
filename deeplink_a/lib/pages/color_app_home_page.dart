import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'color_detail_page.dart';

class ColorAppHomePage extends StatefulWidget {
  const ColorAppHomePage({super.key});

  @override
  State<ColorAppHomePage> createState() => _ColorAppHomePageState();
}

class _ColorAppHomePageState extends State<ColorAppHomePage>
    with WidgetsBindingObserver {
  int _successCounter = 0;
  String _lastStatusMessage = "Aguardando primeira resposta do Godot...";

  // Timer automático
  Timer? _timer;
  int _counterSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning) {
        setState(() {
          _counterSeconds++;
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isTimerRunning = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text;

    // Verifica se há JSON válido no clipboard
    bool hasValidCallback = false;
    Map<String, dynamic>? callbackData;

    if (clipboardText != null && clipboardText.isNotEmpty) {
      try {
        callbackData = jsonDecode(clipboardText);
        hasValidCallback = true;
        await Clipboard.setData(const ClipboardData(text: ''));
      } catch (e) {
        hasValidCallback = false;
      }
    }

    if (hasValidCallback && callbackData != null) {
      // Retornou do Godot com callback
      _handleCallback(callbackData);
    } else {
      // Voltou manualmente (sem callback do Godot)
      _showManualReturnDialog();
    }
  }

  void _handleCallback(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final message = data['message'] as String? ?? 'Mensagem não informada.';
    final requestId = data['requestId'] as String?;

    if (status == 'success') {
      // Sucesso: continua a contagem
      _resumeTimer();
      setState(() {
        _successCounter++;
        _lastStatusMessage = 'Sucesso: Requisição $requestId concluída.';
      });
      _showFeedbackSnackbar(
        isError: false,
        message: 'Operação realizada com sucesso!',
      );
    } else {
      // Erro: pausa e mostra dialog
      _pauseTimer();
      setState(() {
        _lastStatusMessage = 'Falha: $message';
      });
      _showErrorDialog(message);
    }
  }

  void _showManualReturnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline, color: Colors.orange, size: 48),
        title: const Text('Retorno Manual Detectado'),
        content: const Text(
          'Você voltou ao app manualmente. Deseja continuar a ação programada ou aguardar o retorno do Godot?',
        ),
        actions: [
          TextButton(
            child: const Text('Aguardar Godot'),
            onPressed: () {
              Navigator.of(context).pop();
              // Mantém timer pausado
            },
          ),
          FilledButton(
            child: const Text('Continuar Ação'),
            onPressed: () {
              Navigator.of(context).pop();
              _resumeTimer();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Erro Recebido do Godot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Houve uma falha na operação:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: Colors.red.shade900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              _resumeTimer(); // Retoma após reconhecer o erro
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackSnackbar({required bool isError, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  //Sugestão de JSON para o formato json que o backend precisa enviar para listar o apk.
  //Para um único APK:
  // {
  //   "packageName": "com.example.testedeeplink",
  //   "activityName": "com.godot.game.GodotApp"
  // }
  //Para uma lista de APKs:
  // {
  //   "apps": [
  //     {
  //       "packageName": "com.example.testedeeplink",
  //       "activityName": "com.godot.game.GodotApp"
  //     },
  //     {
  //       "packageName": "com.outro.app",
  //       "activityName": "com.outro.app.MainActivity"
  //     }
  //   ]
  // }

  Future<void> _openGodotApp() async {
    const packageName = 'com.example.testedeeplink';

    try {
      final List<Uri> urisToTry = [
        Uri.parse(
          'intent://#Intent;package=$packageName;component=$packageName/com.godot.game.GodotApp;end',
        ),
        Uri.parse('package:$packageName'),
        Uri.parse('android-app://$packageName'),
        Uri.parse('intent://#Intent;package=$packageName;end'),
      ];

      bool launched = false;
      String lastError = '';

      for (final uri in urisToTry) {
        try {
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (launched) {
              print('App aberto com sucesso usando: $uri');
              break;
            }
          }
        } catch (e) {
          lastError = e.toString();
          print('Erro ao tentar abrir com $uri: $e');
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App testedeeplink não encontrado ou não pode ser aberto. Erro: $lastError',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Erro geral ao abrir app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir testedeeplink: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter <> Godot'),
        backgroundColor: Colors.deepPurple.shade50,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contador Automático (abaixo do AppBar, acima do ícone)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isTimerRunning
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTimerRunning
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTimerRunning ? Icons.play_arrow : Icons.pause,
                      color: _isTimerRunning ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_counterSeconds),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _isTimerRunning
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Icon(Icons.sync_alt, size: 80, color: Colors.deepPurple.shade200),
              const SizedBox(height: 20),

              // Contador de Sucessos
              const Text(
                'Contador de Sucessos',
                style: TextStyle(fontSize: 24, color: Colors.black54),
              ),
              Text(
                '$_successCounter',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 30),

              // Status do Godot
              const Text(
                'ÚLTIMO STATUS RECEBIDO:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lastStatusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // Botões de Navegação para Telas de Cores
              const Text(
                'NAVEGAÇÃO:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _openGodotApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade50,
                        surfaceTintColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Abrir Godot',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ColorDetailPage(color: Colors.red),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        surfaceTintColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Red Screen',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ColorDetailPage(color: Colors.blue),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        surfaceTintColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Blue Screen',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//opcao 2
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'color_detail_page.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// class _ColorAppHomePageState extends State<ColorAppHomePage>
//     with WidgetsBindingObserver {
//   int _successCounter = 0;
//   String _lastStatusMessage = "Aguardando primeira resposta do Godot...";

//   // Timer automático
//   Timer? _timer;
//   int _counterSeconds = 0;
//   bool _isTimerRunning = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   void _startTimer() {
//     _isTimerRunning = true;
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_isTimerRunning) {
//         setState(() {
//           _counterSeconds++;
//         });
//       }
//     });
//   }

//   void _pauseTimer() {
//     setState(() {
//       _isTimerRunning = false;
//     });
//   }

//   void _resumeTimer() {
//     setState(() {
//       _isTimerRunning = true;
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.paused) {
//       _pauseTimer();
//     } else if (state == AppLifecycleState.resumed) {
//       _handleAppResumed();
//     }
//   }

//   Future<void> _handleAppResumed() async {
//     final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//     final clipboardText = clipboardData?.text;

//     // Verifica se há JSON válido no clipboard
//     bool hasValidCallback = false;
//     Map<String, dynamic>? callbackData;

//     if (clipboardText != null && clipboardText.isNotEmpty) {
//       try {
//         callbackData = jsonDecode(clipboardText);
//         hasValidCallback = true;
//         await Clipboard.setData(const ClipboardData(text: ''));
//       } catch (e) {
//         hasValidCallback = false;
//       }
//     }

//     if (hasValidCallback && callbackData != null) {
//       // Retornou do Godot com callback
//       _handleCallback(callbackData);
//     } else {
//       // Voltou manualmente (sem callback do Godot)
//       _showManualReturnDialog();
//     }
//   }

//   void _handleCallback(Map<String, dynamic> data) {
//     final status = data['status'] as String?;
//     final message = data['message'] as String? ?? 'Mensagem não informada.';
//     final requestId = data['requestId'] as String?;

//     if (status == 'success') {
//       // Sucesso: continua a contagem
//       _resumeTimer();
//       setState(() {
//         _successCounter++;
//         _lastStatusMessage = 'Sucesso: Requisição $requestId concluída.';
//       });
//       _showFeedbackSnackbar(
//         isError: false,
//         message: 'Operação realizada com sucesso!',
//       );
//     } else {
//       // Erro: pausa e mostra dialog
//       _pauseTimer();
//       setState(() {
//         _lastStatusMessage = 'Falha: $message';
//       });
//       _showErrorDialog(message);
//     }
//   }

//   void _showManualReturnDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         icon: const Icon(Icons.help_outline, color: Colors.orange, size: 48),
//         title: const Text('Retorno Manual Detectado'),
//         content: const Text(
//           'Você voltou ao app manualmente. Deseja continuar a ação programada ou aguardar o retorno do Godot?',
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Aguardar Godot'),
//             onPressed: () {
//               Navigator.of(context).pop();
//               // Mantém timer pausado
//             },
//           ),
//           FilledButton(
//             child: const Text('Continuar Ação'),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _resumeTimer();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         icon: const Icon(Icons.error, color: Colors.red, size: 48),
//         title: const Text('Erro Recebido do Godot'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Houve uma falha na operação:'),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 message,
//                 style: TextStyle(fontSize: 12, color: Colors.red.shade900),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: const Text('OK'),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _resumeTimer(); // Retoma após reconhecer o erro
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFeedbackSnackbar({required bool isError, required String message}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.redAccent : Colors.green,
//       ),
//     );
//   }

//   String _formatTime(int seconds) {
//     final hours = seconds ~/ 3600;
//     final minutes = (seconds % 3600) ~/ 60;
//     final secs = seconds % 60;
//     return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }

//   Future<void> _openGodotApp() async {
//     const packageName = 'com.deep.deeplink';
//     final uri = Uri.parse('package:$packageName');

//     try {
//       final canLaunch = await canLaunchUrl(uri);
//       if (canLaunch) {
//         await launchUrl(uri);
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('App Godot não encontrado'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erro ao abrir app: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter <> Godot'),
//         backgroundColor: Colors.deepPurple.shade50,
//         elevation: 1,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Contador Automático (abaixo do AppBar, acima do ícone)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _isTimerRunning
//                       ? Colors.green.shade50
//                       : Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _isTimerRunning
//                         ? Colors.green.shade300
//                         : Colors.orange.shade300,
//                     width: 2,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _isTimerRunning ? Icons.play_arrow : Icons.pause,
//                       color: _isTimerRunning ? Colors.green : Colors.orange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _formatTime(_counterSeconds),
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: _isTimerRunning
//                             ? Colors.green.shade800
//                             : Colors.orange.shade800,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),

//               Icon(Icons.sync_alt, size: 80, color: Colors.deepPurple.shade200),
//               const SizedBox(height: 20),

//               // Contador de Sucessos
//               const Text(
//                 'Contador de Sucessos',
//                 style: TextStyle(fontSize: 24, color: Colors.black54),
//               ),
//               Text(
//                 '$_successCounter',
//                 style: const TextStyle(
//                   fontSize: 72,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.deepPurple,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // Status do Godot
//               const Text(
//                 'ÚLTIMO STATUS RECEBIDO:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _lastStatusMessage,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),

//               const SizedBox(height: 40),
//               const Divider(),
//               const SizedBox(height: 20),

//               // Botões de Navegação para Telas de Cores
//               const Text(
//                 'NAVEGAÇÃO:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     onPressed: _openGodotApp,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple.shade50,
//                       surfaceTintColor: Colors.purple,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: const Text('Abrir GodotApp'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               const ColorDetailPage(color: Colors.red),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade50,
//                       surfaceTintColor: Colors.red,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: const Text('Red Screen'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               const ColorDetailPage(color: Colors.blue),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade50,
//                       surfaceTintColor: Colors.blue,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: const Text('Blue Screen'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//opcao 1
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'color_detail_page.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// class _ColorAppHomePageState extends State<ColorAppHomePage>
//     with WidgetsBindingObserver {
//   int _successCounter = 0;
//   String _lastStatusMessage = "Aguardando primeira resposta do Godot...";

//   Timer? _timer;
//   int _counterSeconds = 0;
//   bool _isTimerRunning = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   void _startTimer() {
//     _isTimerRunning = true;
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_isTimerRunning) {
//         setState(() {
//           _counterSeconds++;
//         });
//       }
//     });
//   }

//   void _pauseTimer() {
//     setState(() {
//       _isTimerRunning = false;
//     });
//   }

//   void _resumeTimer() {
//     setState(() {
//       _isTimerRunning = true;
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.paused) {
//       _pauseTimer();
//     } else if (state == AppLifecycleState.resumed) {
//       _handleAppResumed();
//     }
//   }

//   Future<void> _handleAppResumed() async {
//     final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//     final clipboardText = clipboardData?.text;

//     bool hasValidCallback = false;
//     Map<String, dynamic>? callbackData;

//     if (clipboardText != null && clipboardText.isNotEmpty) {
//       try {
//         callbackData = jsonDecode(clipboardText);
//         hasValidCallback = true;
//         await Clipboard.setData(const ClipboardData(text: ''));
//       } catch (e) {
//         hasValidCallback = false;
//       }
//     }

//     if (hasValidCallback && callbackData != null) {
//       _handleCallback(callbackData);
//     } else {
//       _showManualReturnDialog();
//     }
//   }

//   void _handleCallback(Map<String, dynamic> data) {
//     final status = data['status'] as String?;
//     final message = data['message'] as String? ?? 'Mensagem não informada.';
//     final requestId = data['requestId'] as String?;

//     if (status == 'success') {
//       _resumeTimer();
//       setState(() {
//         _successCounter++;
//         _lastStatusMessage = 'Sucesso: Requisição $requestId concluída.';
//       });
//       _showFeedbackSnackbar(
//         isError: false,
//         message: 'Operação realizada com sucesso!',
//       );
//     } else {
//       _pauseTimer();
//       setState(() {
//         _lastStatusMessage = 'Falha: $message';
//       });
//       _showErrorDialog(message);
//     }
//   }

//   void _showManualReturnDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         icon: const Icon(Icons.help_outline, color: Colors.orange, size: 48),
//         title: const Text('Retorno Manual Detectado'),
//         content: const Text(
//           'Você voltou ao app manualmente. Deseja continuar a ação programada ou aguardar o retorno do Godot?',
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Aguardar Godot'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           FilledButton(
//             child: const Text('Continuar Ação'),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _resumeTimer();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         icon: const Icon(Icons.error, color: Colors.red, size: 48),
//         title: const Text('Erro Recebido do Godot'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Houve uma falha na operação:'),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 message,
//                 style: TextStyle(fontSize: 12, color: Colors.red.shade900),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: const Text('OK'),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _resumeTimer();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFeedbackSnackbar({required bool isError, required String message}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.redAccent : Colors.green,
//       ),
//     );
//   }

//   String _formatTime(int seconds) {
//     final hours = seconds ~/ 3600;
//     final minutes = (seconds % 3600) ~/ 60;
//     final secs = seconds % 60;
//     return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter <> Godot'),
//         backgroundColor: Colors.deepPurple.shade50,
//         elevation: 1,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _isTimerRunning
//                       ? Colors.green.shade50
//                       : Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _isTimerRunning
//                         ? Colors.green.shade300
//                         : Colors.orange.shade300,
//                     width: 2,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _isTimerRunning ? Icons.play_arrow : Icons.pause,
//                       color: _isTimerRunning ? Colors.green : Colors.orange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _formatTime(_counterSeconds),
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: _isTimerRunning
//                             ? Colors.green.shade800
//                             : Colors.orange.shade800,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),

//               Icon(Icons.sync_alt, size: 80, color: Colors.deepPurple.shade200),
//               const SizedBox(height: 20),

//               // Contador de Sucessos
//               const Text(
//                 'Contador de Sucessos',
//                 style: TextStyle(fontSize: 24, color: Colors.black54),
//               ),
//               Text(
//                 '$_successCounter',
//                 style: const TextStyle(
//                   fontSize: 72,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.deepPurple,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // Status do Godot
//               const Text(
//                 'ÚLTIMO STATUS RECEBIDO:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _lastStatusMessage,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),

//               const SizedBox(height: 40),
//               const Divider(),
//               const SizedBox(height: 20),

//               const Text(
//                 'NAVEGAÇÃO:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               const ColorDetailPage(color: Colors.red),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade50,
//                       surfaceTintColor: Colors.red,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: const Text('Red Screen'),
//                   ),
//                   const SizedBox(width: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               const ColorDetailPage(color: Colors.blue),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade50,
//                       surfaceTintColor: Colors.blue,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: const Text('Blue Screen'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
