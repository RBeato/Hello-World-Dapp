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
        ref.read(imageOpacityProvider.notifier).state = 1.0;
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
                                    ref
                                        .read(imageOpacityProvider.notifier)
                                        .state = 1.0;
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
