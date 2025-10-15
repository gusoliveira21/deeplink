import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_detail_page.dart';

class ColorAppHomePage extends StatefulWidget {
  const ColorAppHomePage({super.key});

  @override
  State<ColorAppHomePage> createState() => _ColorAppHomePageState();
}

class _ColorAppHomePageState extends State<ColorAppHomePage>
    with WidgetsBindingObserver {
  // Variáveis de estado da tela
  int _successCounter = 0;
  String _lastStatusMessage = "Aguardando primeira resposta do Godot...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForCallback();
    }
  }

  Future<void> _checkClipboardForCallback() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text;

    if (clipboardText == null || clipboardText.isEmpty) return;

    try {
      final callbackData = jsonDecode(clipboardText);
      _handleCallback(callbackData);
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (e) {
      print("Clipboard não continha um JSON de callback válido.");
    }
  }

  void _handleCallback(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final message = data['message'] as String? ?? 'Mensagem não informada.';
    final requestId = data['requestId'] as String?;

    if (status == 'success') {
      setState(() {
        _successCounter++;
        _lastStatusMessage = 'Sucesso: Requisição $requestId concluída.';
      });
      _showFeedbackSnackbar(
        isError: false,
        message: 'Operação realizada com sucesso!',
      );
    } else {
      setState(() {
        _lastStatusMessage = 'Falha: $message';
      });
      _showErrorDialog(message);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro Recebido do Godot'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
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
                  ElevatedButton(
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
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Red Screen'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
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
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Blue Screen'),
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

//tela 4
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// // Usamos 'WidgetsBindingObserver' para saber quando o app é reativado.
// class _ColorAppHomePageState extends State<ColorAppHomePage>
//     with WidgetsBindingObserver {
//   // Variáveis de estado da tela
//   int _successCounter = 0;
//   String _lastStatusMessage = "Aguardando primeira resposta do Godot...";

//   @override
//   void initState() {
//     super.initState();
//     // Registra esta classe para ouvir as mudanças de ciclo de vida do app.
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     // É importante remover o observador para evitar vazamentos de memória.
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   /// Este método é chamado automaticamente pelo Flutter sempre que o app
//   /// muda de estado (ex: vai para segundo plano, volta ao foco, etc).
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     // Nosso interesse é apenas quando o app volta a ficar ativo.
//     if (state == AppLifecycleState.resumed) {
//       _checkClipboardForCallback();
//     }
//   }

//   /// Lê a área de transferência em busca de uma resposta formatada em JSON.
//   Future<void> _checkClipboardForCallback() async {
//     // Pega o texto atual da área de transferência.
//     final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//     final clipboardText = clipboardData?.text;

//     // Se não houver texto, não faz nada.
//     if (clipboardText == null || clipboardText.isEmpty) return;

//     try {
//       // Tenta decodificar o texto. Se não for um JSON válido, vai gerar um erro.
//       final callbackData = jsonDecode(clipboardText);

//       // Se deu certo, processa os dados...
//       _handleCallback(callbackData);

//       // ...e limpa a área de transferência para não processar a mesma resposta de novo.
//       await Clipboard.setData(const ClipboardData(text: ''));
//     } catch (e) {
//       // Acontece se o clipboard tiver um texto comum. Apenas ignoramos.
//       print("Clipboard não continha um JSON de callback válido.");
//     }
//   }

//   /// Atualiza a UI com base nos dados recebidos do Godot.
//   void _handleCallback(Map<String, dynamic> data) {
//     final status = data['status'] as String?;
//     final message = data['message'] as String? ?? 'Mensagem não informada.';
//     final requestId = data['requestId'] as String?;

//     if (status == 'success') {
//       // Se foi sucesso, atualiza o contador e a mensagem de status.
//       setState(() {
//         _successCounter++;
//         _lastStatusMessage = 'Sucesso: Requisição $requestId concluída.';
//       });
//       _showFeedbackSnackbar(
//         isError: false,
//         message: 'Operação realizada com sucesso!',
//       );
//     } else {
//       // Se foi erro, apenas atualiza a mensagem e mostra o diálogo.
//       setState(() {
//         _lastStatusMessage = 'Falha: $message';
//       });
//       _showErrorDialog(message);
//     }
//   }

//   /// Mostra um pop-up de erro.
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Erro Recebido do Godot'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             child: const Text('OK'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Mostra uma barra de notificação temporária.
//   void _showFeedbackSnackbar({required bool isError, required String message}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.redAccent : Colors.green,
//       ),
//     );
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
//               Icon(Icons.sync_alt, size: 80, color: Colors.deepPurple.shade200),
//               const SizedBox(height: 20),
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
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




//tela 3
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// // Adicionamos 'WidgetsBindingObserver' para detectar quando o app volta ao foco.
// class _ColorAppHomePageState extends State<ColorAppHomePage>
//     with WidgetsBindingObserver {
//   int _counter = 0;

//   @override
//   void initState() {
//     super.initState();
//     // Registra este widget como um observador do ciclo de vida do app.
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     // Remove o observador para evitar vazamentos de memória.
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   /// Este método é chamado sempre que o estado do app muda (ex: para fundo, para foco).
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     // Se o app acabou de voltar para o primeiro plano (ficou ativo)...
//     if (state == AppLifecycleState.resumed) {
//       print("App voltou ao foco, verificando clipboard...");
//       _checkClipboardForCallback();
//     }
//   }

//   /// Verifica a área de transferência por uma mensagem de callback do Godot.
//   Future<void> _checkClipboardForCallback() async {
//     // Pega o conteúdo da área de transferência.
//     ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
//     if (data?.text == null || data!.text!.isEmpty) return;

//     try {
//       // Tenta decodificar o texto como um JSON.
//       final callbackData = jsonDecode(data.text!);

//       // Se for um JSON válido, processa e limpa a área de transferência
//       // para não processar o mesmo callback duas vezes.
//       _handleCallback(callbackData);
//       await Clipboard.setData(const ClipboardData(text: ''));
//     } catch (e) {
//       // Se o texto no clipboard não for um JSON válido, ignora.
//       print(
//         "Conteúdo do clipboard não é um callback JSON válido: ${data.text}",
//       );
//     }
//   }

//   /// Processa os dados do callback recebidos.
//   void _handleCallback(Map<String, dynamic> data) {
//     final status = data['status'] as String?;
//     final message =
//         data['message'] as String? ?? 'Ocorreu um erro desconhecido.';
//     final requestId = data['requestId'] as String?;

//     if (status == 'success') {
//       setState(() {
//         _counter++;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Sucesso! Requisição $requestId concluída. Contador: $_counter',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } else {
//       _showErrorDialog(message);
//     }
//   }

//   /// Exibe um diálogo de erro amigável.
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Erro Recebido do Godot'),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Aguardando Callback do Godot'),
//         backgroundColor: Colors.deepPurple[100],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Contador de Sucessos:', style: TextStyle(fontSize: 22)),
//             Text(
//               '$_counter',
//               style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text(
//                 'Esta tela está ouvindo... Vá para o app Godot e dispare uma ação.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



//solucao 2
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:uni_links/uni_links.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// class _ColorAppHomePageState extends State<ColorAppHomePage> {
//   StreamSubscription? _sub;

//   int _counter = 0;

//   @override
//   void initState() {
//     super.initState();
//     _initUniLinks();
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   Future<void> _initUniLinks() async {
//     _sub = uriLinkStream.listen(
//       (Uri? uri) {
//         if (uri != null && mounted) {
//           _handleCallback(uri);
//         }
//       },
//       onError: (err) {
//         print('Erro no uni_links: $err');
//       },
//     );
//   }

//   void _handleCallback(Uri uri) {
//     if (uri.host == 'callback') {
//       final status = uri.queryParameters['status'];
//       final message =
//           uri.queryParameters['message'] ?? 'Ocorreu um erro desconhecido.';
//       final requestId = uri.queryParameters['requestId'];

//       print('Callback recebido: id=$requestId, status=$status, msg=$message');

//       if (status == 'success') {
//         setState(() {
//           _counter++;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Sucesso! Requisição $requestId concluída. Contador: $_counter',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         _showErrorDialog(message);
//       }
//     }
//   }

//   /// Exibe um diálogo de erro amigável.
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Erro Recebido do Godot'),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // A UI agora apenas exibe o estado (o contador) e aguarda o callback.
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Aguardando Callback do Godot'),
//         backgroundColor: Colors.deepPurple[100],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Contador de Sucessos:', style: TextStyle(fontSize: 22)),
//             Text(
//               '$_counter',
//               style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Text(
//                 'Esta tela está ouvindo... Vá para o app Godot e dispare uma ação para ver o contador mudar ou um diálogo de erro aparecer.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










//solucao 1
// import 'package:flutter/material.dart';
// import 'color_detail_page.dart';

// class ColorAppHomePage extends StatefulWidget {
//   const ColorAppHomePage({super.key});

//   @override
//   State<ColorAppHomePage> createState() => _ColorAppHomePageState();
// }

// class _ColorAppHomePageState extends State<ColorAppHomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ColorDetailPage(
//                               color: Colors.red,
//                             )));
//               },
//               style: ElevatedButton.styleFrom(surfaceTintColor: Colors.red),
//               child: const Text('Red Screen'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ColorDetailPage(
//                               color: Colors.blue,
//                             )));
//               },
//               style: ElevatedButton.styleFrom(surfaceTintColor: Colors.blue),
//               child: const Text('Blue Screen'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
