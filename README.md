![](markdown/hello_world_dapp.png)


# hello_world_dapp

Hello World Dapp. 
A Flutter project to interact with the blockchain that uses truffle, and the solidity to write Ethereum smart contracts.

This project is based on this blog:
 https://www.geeksforgeeks.org/flutter-and-blockchain-hello-world-dapp/

But with some important differences:
- It uses solidity 0.8.7 instead of 0.5.9
- It has some small changes in the smart contract code
- The model that makes the connection to the blockchain is rewritten with the intent of making the code more easily reusable
- the abis are stored as assets
- It uses .env, with consequent implications on privatekey safety
- It makes use of flutter_riverpod instead of provider
- The UI is completely changed
  

## Tutorial

**1. Setting up the development environment**
> `npm install -g truffle`

**3. Create a flutter project**
> `flutter create hello_world`

**2. Creating a Truffle Project**
   Initialize Truffle inside the flutter project directory.
 > `truffle init`


**3. Directory Structure**
   
![](markdown/directory_structure.png)
* **contracts/**: Contains the solidity contract fie.
* **migrations/**: Contains the migration script files.
* **test/**: Contains test script files.
*  **truffle-config.js**: Contains truffle deployment configurations information.
      
**4. Writing your first Smart Contract**

``` javascript
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract HelloWorld {

    string public userName;

    constructor() {
        userName = "Subscriber";
    }

    function setName(string memory _name) public {
        userName  = _name;
    }
}
```    

**5. Compiling and Migrating the Smart Contract**
   
*Compilation*

In the terminal, in the root directory of the flutter project, run the command:

  `truffle compile`

*Migration*
    
Create **2_deploy_contracts.js** file in the **migrations/** folder next to **1_initial_migrations.js**, and the following content.

``` javascript
const HelloWorld = artifacts.require("HelloWorld");
  
module.exports = function (deployer) {
  deployer.deploy(HelloWorld);
};
```   
Now, we'll use [ganache](https://trufflesuite.com/ganache/), a personal blockchain for development purposes. 

Edit **truffle-config.js**:

```javascript
module.exports = {
  networks: {
     development: {
      host: "127.0.0.1",     // Localhost 
      port: 7545,            // Standard Ethereum port 
      network_id: "*",       // Any network 
     },
  },
  // Configure your compilers
  contracts_directory: './contracts/', // solidity contracts path
  contract_build_directory: './assets/contracts_abis/', //where abis .json files are placed

  compilers: {
    solc: {    
        version: "0.8.7",
        optimizer: {
          enabled: false,
          runs: 200
        },
    }
  }
};
```

Next we need go to the migrations folder and create the file `2_deploy_contracts.js` with the following content.

```javascript
const HelloWorld = artifacts.require("HelloWorld");

module.exports = function (deployer) {
    deployer.deploy(HelloWorld);
}
```
Now we can migrate the contract.

  `truffle migrate`

Or if it ins't the first time you are doing this you can use the --reset option to run all your migrations from the beginning. 

  `truffle migrate --reset`


**7. Testing the Smart Contract**

We can write tests in Solidity or Javascript in Truffle.
Truffle uses the Mocha testing framework and Chai for assertions to provide you with a solid framework from which to write your JavaScript tests.

In the **test/** directory create a file named **helloWorld.js** and add the following content:

```javascript
const HelloWorld = artifacts.require("HelloWorld");
// We begin by importing the smart contract

contract("HelloWorld", () => {
    it("should return the passed string", async() => {
        const helloWorld = await HelloWorld.deployed();
        //we get an instance of the contract
        await helloWorld.setName("Romeu");
        // we pass a string as an argument to the setName function
        const result = await helloWorld.userName()
        //because the `name` variable uses a public modifier in the smart contract it automatically generates a getter for us so we can call it directly
        assert(result === "Romeu");
        // We can use the assert function because Truffle imports Chai. And we check if the name is set properly in this way 
    })
})
```

* Run the tests
  >`truffle test`

**8. Contract linking with Flutter**

In the **pubspec.yaml** file import the packages:

    flutter_dotenv: ^5.0.2
    flutter_riverpod: ^1.0.3
    flutter_svg: ^1.0.0
    google_fonts: ^2.1.1
    web3dart: ^2.3.3
    http: ^0.13.4
    web_socket_channel: ^2.1.0

We will also add the abi to the **pubspec.yaml** located in the **assets/contracts_abis/** folder, that is automatically generated when migrating the contract.

    assets:
        - assets/contracts_abis/
        - assets/images/

**Add some security**
     
In the root directory create a file **.env** . This is where you will put sensible information. Namely the private keys that we will be using.

No avoid sharing your private information when uploading your project to github go to **.gitignore** and anywhere in the file add this line:

    *.env

Next, add the file to your assets.

    assets:
        - assets/contracts_abis/
        - assets/images/
        - .env
  
Get the private key from ganache: 

Click the key.
![](markdown/ganache.png)

Copy it
  ![](markdown/ganache_private_key.png)

And put it inside .env file. assigning the value to *GANACHE_PRIVATE_KEY*.
  ![](markdown/dot_env.png)


**Ethereum utils**

In the **lib/** folder create a **utils** folder and inside this folder create a **eth_utils.dart**  file, and add the following code.

```dart
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
  }

  setName(String nameToSet) async {
    // Setting the name to nameToSet(name defined by user)
    isLoading = true;
    state = isLoading;
    await _ethClient!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _setName!,
            parameters: [nameToSet]));
    getName();
  }
}

```

**9.  Creating a UI to interact with the smart contract**

* Add the **images** folder to the **assets** folder and inside place the *hello_image.png*.
* Add the **google_fonts** folder with the files:
  * DancingScript-VariableFont_wght.ttf
  * OpenSansCondensed-Light.ttf

* Create a **UI** folder inside **lib/**.

* **Create helloUI.dart**
Create a new file named **helloUI.dart** in the **UI/** folder and add the following content to the file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_world_dapp/utils/eth_utils.dart';

import 'custom_text.dart';

final imageOpacityProvider = StateProvider<double>((ref) => 1.0);

class HelloUI extends ConsumerStatefulWidget {
  const HelloUI({Key? key}) : super(key: key);

  @override
  _HelloUIState createState() => _HelloUIState();
}

class _HelloUIState extends ConsumerState<HelloUI> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onFocusChange() {
    debugPrint("Focus: ${_focus.hasFocus.toString()}");
    if (_focus.hasFocus) {
      ref.read(imageOpacityProvider.notifier).state = 0.4;
    }
    if (!_focus.hasFocus) {
      ref.read(imageOpacityProvider.notifier).state = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ethUtilsProviders);
    final ethUtils = ref.watch(ethUtilsProviders.notifier);
    final imageOpacity = ref.watch(imageOpacityProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        ref.read(imageOpacityProvider) == 1.0;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const CustomText(
            text: "Hello World!",
            fontSize: 22.0,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.blue, Colors.white])),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: ethUtils.isLoading
                ? const CircularProgressIndicator()
                : Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Opacity(
                            opacity: imageOpacity,
                            child:
                                Image.asset('assets/images/hello_image.png')),
                        widthFactor: 1.2,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    flex: 1,
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: CustomText(
                                        text: "Hello ",
                                        color: Colors.blue,
                                        fontSize: 60.0,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: CustomText(
                                        text: ethUtils.deployedName!,
                                        color: Colors.white,
                                        fontSize: 60.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 50.0,
                              ),
                              TextField(
                                focusNode: _focus,
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter a name!',
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(32.0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.lightBlueAccent,
                                        width: 1.0),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(32.0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.lightBlueAccent,
                                        width: 2.0),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(32.0)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: ElevatedButton(
                                  child: const Text(
                                    'Set Name',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.blue,
                                  ),
                                  onPressed: () {
                                    if (_nameController.text.isEmpty) return;
                                    ethUtils.setName(_nameController.text);
                                    ref.read(imageOpacityProvider) == 1.0;
                                    _nameController.clear();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

```
* Add **custom_text.dart** file to the **UI** folder and add the following:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    Key? key,
    required this.text,
    required this.fontSize,
    required this.color,
  }) : super(key: key);

  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dancingScript(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            offset: const Offset(0.0, 6.0),
            blurRadius: 6.0,
            color: Colors.white30.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
```


* Change the  **main.dart** file.
  
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'UI/helloUI.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hello World',
      home: HelloUI(),
    );
  }
}
```
**10.  Interacting with the complete Dapp**

And this is it. The dApp is ready for you to try! Enjoy!