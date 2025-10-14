# DeepLink

## 📱 O que é o projeto

Este é um aplicativo Flutter de demonstração que implementa **Deep Links** para navegação direta entre telas. O app permite navegar para telas específicas através de URLs externas, demonstrando como configurar e usar deep links em aplicações Flutter.

## 🔧 Funcionamento do projeto

O aplicativo possui três telas principais:

- **Tela Inicial**: Apresenta dois botões para navegar para telas coloridas
- **Tela Vermelha**: Acessível via deep link `/red` 
- **Tela Azul**: Acessível via deep link `/blue`

### Configuração de Deep Links

O app está configurado para receber deep links do domínio `gusoliveira21.eu5.org` através do protocolo HTTPS. Quando um link é acessado, o aplicativo abre automaticamente na tela correspondente.

### Tecnologias utilizadas

- **Flutter**: Framework de desenvolvimento
- **Go Router**: Gerenciamento de rotas e navegação
- **Android Intent Filters**: Configuração de deep links no Android

## 🚀 Como rodar o projeto

### Em um emulador

1. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

2. **Execute o aplicativo:**
   ```bash
   flutter run
   ```

3. **Selecione o emulador** quando solicitado pelo Flutter

### Testando Deep Links

Para testar os deep links, use o comando ADB no terminal:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://gusoliveira21.eu5.org/red" com.deep.deeplink
```

**Comandos disponíveis:**
- Para tela vermelha: `https://gusoliveira21.eu5.org/red`
- Para tela azul: `https://gusoliveira21.eu5.org/blue`
- Para tela inicial: `https://gusoliveira21.eu5.org/`

### Pré-requisitos

- Flutter SDK instalado
- Android Studio com emulador configurado
- ADB (Android Debug Bridge) disponível no PATH

---

**Nota**: Certifique-se de que o emulador esteja rodando e o aplicativo esteja instalado antes de testar os deep links.
