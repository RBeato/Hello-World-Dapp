import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

final ethUtilsProviders = StateNotifierProvider<EthereumUtils, bool>((ref) {
  return EthereumUtils();
});

class EthereumUtils extends StateNotifier<bool> {
  EthereumUtils() : super(true) {
    initialSetup();
  }

  //!Add to the README.md file

  final String _rpcUrl = "http://10.0.2.2:7545";
  final String _wsUrl = "ws://10.0.2.2:7545/";
  final String _privateKey = dotenv.env['GANACHE_PRIVATE_KEY']!;

  // The library web3dart won’t send signed transactions to miners
  // itself. Instead, it relies on an RPC client to do that. For the
  // WebSocket URL just modify the RPC URL.

  // http.Client _httpClient;
  Web3Client? _ethClient; //connects to the ethereum rpc via WebSocket
  bool isLoading = true; //checks the state of the contract

  String? _abi; //used to read the contract abi
  EthereumAddress? _contractAddress; //address of the deployed contract

  EthPrivateKey? _credentials; //credentials of the smart contract deployer

  DeployedContract? _contract; //where contract is declared, for Web3dart
  ContractFunction?
      _userName; // stores the name getter declared in the HelloWorld.sol
  ContractFunction?
      _setName; // stores the setName function declared in the HelloWorld.sol

  String? deployedName; //will hold the name from the smart contract

  initialSetup() async {
    http.Client _httpClient = http.Client();
    _ethClient = Web3Client(_rpcUrl, _httpClient, socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    //Reading the contract abi
    String abiStringFile =
        await rootBundle.loadString("assets/contracts_abis/HelloWorld.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abi = jsonEncode(jsonAbi["abi"]);

    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(_privateKey);
  }

  Future<void> getDeployedContract() async {
    // Telling Web3dart where our contract is declared.
    _contract = DeployedContract(
        ContractAbi.fromJson(_abi!, "HelloWorld"), _contractAddress!);

    // Extracting the functions, declared in contract.
    _userName = _contract!.function("userName");
    _setName = _contract!.function("setName");
    getName();
  }

  getName() async {
    // Getting the current name declared in the smart contract.
    var currentName = await _ethClient!
        .call(contract: _contract!, function: _userName!, params: []);
    deployedName = currentName[0];
    isLoading = false;
    state = isLoading;
    // notifyListeners();
  }

  setName(String nameToSet) async {
    // Setting the name to nameToSet(name defined by user)
    isLoading = true;
    state = isLoading;
    // notifyListeners();
    await _ethClient!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _setName!,
            parameters: [nameToSet]));
    getName();
  }
}
