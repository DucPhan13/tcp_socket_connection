library tcp_socket_connection;
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class TcpSocketConnection{

  String _ipAddress;
  int _portAddress;
  Socket _server;
  String _eos;
  String _separator="";
  bool _connected=false;
  bool _logPrintEnabled=false;

  /// Initializes che class itself
  ///  * @param  ip  server's ip you are trying to connect to
  ///  * @param  port servers's port you are trying to connect to
  TcpSocketConnection(String ip, int port){
    _ipAddress=ip;
    _portAddress=port;
  }

  /// Initializes che class itself
  ///  * @param  ip  server's ip you are trying to connect to
  ///  * @param  port servers's port you are trying to connect to
  ///  * @param  enable if set to true, then events will be printed in the console
  TcpSocketConnection.constructorWithPrint(String ip, int port, bool enable){
    _ipAddress=ip;
    _portAddress=port;
    _logPrintEnabled=enable;
  }

  /// Show events in the console with print method
  /// * @param  enable if set to true, then events will be printed in the console
  enableConsolePrint(bool enable){
    _logPrintEnabled=enable;
  }


  /// Initializes the connection. Socket starts listening to server for data.
  /// 'callback' function will be called when 'eos' is received
  ///
  ///  * @param  timeOut  amount of time to attempt the connection in milliseconds
  ///  * @param  separator  sequence of characters to use between commands
  ///  * @param  eos  sequence of characters at the end of each single message
  ///  * @param  callback  function called when received a message. It must take 2 'String' as params. The first one is the command received, the second one is the message itself.
  connectWithCommand(int timeOut, String separator, String eos,  Function callback) async{
    if(_ipAddress==null){
      print("Cass not initialized. You must call the constructor!");
      return;
    }
    _eos=eos;
    _separator=separator;
    Timer t=_startTimeout(timeOut);
    _server = await Socket.connect(_ipAddress, _portAddress);
    _connected=true;
    _printData("Socket successfully connected");
    String message="";
    t.cancel();
    _server.listen((List<int> event) async {
      message += (utf8.decode(event));
      if(message.contains(eos)){
        List<String> commands=message.split(_separator);
        _printData("Message received: "+message);
        callback(commands[0],commands[1].split(eos)[0]);
        if(commands[1].split(eos).length>1){
          message=commands[1].split(eos)[1];
        }else{
          message="";
        }
      }
    });
    _connected=false;
  }

  /// Initializes the connection. Socket starts listening to server for data.
  /// 'callback' function will be called whenever data is received. The developer elaborates the message received however he wants.
  /// No separator is used to split message into parts
  ///  * @param  timeOut  amount of time to attempt the connection in milliseconds
  ///  * @param  callback  function called when received a message. It must take a 'String' as param which is the message received.
  simpleConnect(int timeOut, Function callback) async{
    if(_ipAddress==null){
      print("Cass not initialized. You must call the constructor!");
      return;
    }
    Timer t=_startTimeout(timeOut);
    _server = await Socket.connect(_ipAddress, _portAddress);
    _connected=true;
    _printData("Socket successfully connected");
    String message="";
    t.cancel();
    _server.listen((List<int> event) async {
      String received=(utf8.decode(event));
      message += received;
      _printData("Message received: "+message);
      callback(message);
      message="";
    });
    _connected=false;
  }



  /// Initializes the connection. Socket starts listening to server for data.
  /// 'callback' function will be called when 'eos' is received.
  /// No separator is used to split message into parts
  ///  * @param  timeOut  amount of time to attempt the connection in milliseconds
  ///  * @param  eos  sequence of characters at the end of each single message
  ///  * @param  callback  function called when received a message. It must take a 'String' as param which is the message received.
  connect(int timeOut, String eos,  Function callback) async{
    if(_ipAddress==null){
      print("Cass not initialized. You must call the constructor!");
      return;
    }
    _eos=eos;
    Timer t=_startTimeout(timeOut);
    _server = await Socket.connect(_ipAddress, _portAddress);
    _connected=true;
    _printData("Socket successfully connected");
    String message="";
    t.cancel();
    _server.listen((List<int> event) async {
      String received=(utf8.decode(event));
      message += received;
      if(message.contains(eos)){
        _printData("Message received: "+message);
        callback(message.split(eos)[0]);
        if(message.split(eos).length>1){
          message=message.split(eos)[1];
        }else{
          message="";
        }
      }
    });
    _connected=false;
  }

  /// Stop the connection and close the socket
  void disconnect(){
    if(_server!=null){
      try{
        _server.close();
        _printData("Socket disconnected successfully");
      }catch(Exception){
        print("ERROR");
      }
    }
    _connected=false;
  }

  /// Check if the socket is connected
  bool isConnected(){
    return _connected;
  }

  /// Send message to server. Make sure to have established a connection before calling this method
  /// Message will be sent as 'message'+'separator'+'eos'
  ///  * @param  message  message to send to server
  void sendMessage(String message) async{
    if(_server!=null){
      _server.add(utf8.encode(message+_separator+_eos));
      _printData("Message sent: "+message+_separator+_eos);
    }else{
      print("Socket not initialized before sending message! Make sure you have already called the method 'connect()'");
    }
  }

  /// Send message to server with a command. Make sure to have established a connection before calling this method
  /// Message will be sent as 'command'+'separator'+'message'+'separator'+'eos'
  ///  * @param  message  message to send to server
  ///  * @param  command  tells the server what to do with the message
  void sendMessageWithCommand(String message, String command) async{
    if(_server!=null){
      _server.add(utf8.encode(command+_separator+message+_separator+_eos));
      _printData("Message sent: "+command+_separator+message+_separator+_eos);
    }else{
      print("Socket not initialized before sending message! Make sure you have alreadt called the method 'connect()'");
    }
  }

  _startTimeout(int time) {
    var duration = Duration(milliseconds: time);
    return new Timer(duration, ()=> _handleTimeout());
  }

  void _handleTimeout() {
    if(_server!=null){
      try{
        _server.close();
      }catch(Exception){
        print("ERROR");
      }
    }
    _connected=false;
    print("Timer elapsed! Can't connect to server!");
  }

  void _printData(String data){
    if(_logPrintEnabled){
      print(data);
    }
  }
}