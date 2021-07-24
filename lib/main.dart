import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controller/home_controller.dart';


void main() async {
  await Hive.initFlutter();
  runApp(const GetMaterialApp(
    home: Home()
  ),
  );
}

class Home extends StatelessWidget {

  const Home({Key? key}) : super(key: key);
  @override
  Widget build(context) {
  final HomeController c = Get.put(HomeController());

  return SafeArea(
    child: Scaffold(
      appBar: AppBar(title: const Text("GPS To SMS")),

      body: Center(
        child: Column(
          children: [
            Obx(() => c.loading.isTrue ? const LinearProgressIndicator(color: Colors.orange) : Container(height: 5.0,)),
            ElevatedButton(
              child: const Text("Choose Contact"),
              onPressed: c.chooseContact,
            ),
            ElevatedButton(
              child:const Text("Send Location"),
              onPressed: c.sendLocation,
            ),
            GetX<HomeController>(
              builder: (c) {
                if (c.contact.value == null) return const Text("No Contact");
                return Text("Contact: ${c.contact.value!.name!.nickName} (${c.contact.value!.phones[0].number})");
              }
            ),
          ],
        ),
      ),
    ),
  );
  }
}