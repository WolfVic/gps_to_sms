import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:telephony/telephony.dart';

import 'gps_controller.dart';

class HomeController extends GetxController{
  final Telephony telephony = Telephony.instance;
  final GpsController gpsController = Get.put(GpsController());
  Rxn<FullContact> contact = Rxn<FullContact>(null);
  final RxBool loading = false.obs;
  late Box box;

  @override
  onInit() async {
    super.onInit();
    Hive.registerAdapter(FullContactAdapter());
    box = await Hive.openBox("gpsToSms");
    contact.value = box.get('lastContact');
  }

    void chooseContact() async {
    try {
      contact.value = await FlutterContactPicker.pickFullContact(askForPermission: true);
      box.put('lastContact', contact.value);
    } on UserCancelledPickingException {
      Get.snackbar("Canceled", "You have to choose a contact to send you sms");
    }
  }

  void sendLocation() async {
    if (loading.isTrue) {
      Get.snackbar("Wait", "You have already requested to send your location");
    } else {
      loading.value = true;
      try {
        bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
        if (permissionsGranted == null || !permissionsGranted) {
          Get.snackbar("Permissions not granted", "Please, grant Phone ans Sms permissions", onTap: (_) => gpsController.toAppSettings);
        } else {
          final String? phoneNumber = contact.value?.phones[0].number;
          if(_isPhoneNumber(phoneNumber)) {
            final String link = await gpsController.getLocationLink();
            void listener (SendStatus status) {
              if (status == SendStatus.DELIVERED) {
                Get.snackbar("SMS Sent", "Your contact has received your SMS");
              }
            }
            await telephony.sendSms(to: phoneNumber!, message: "This is my location:\n $link", statusListener: listener);
          } else {
            Get.snackbar(
              "SMS Not Sent", "Check if the phone number is correct",);
          }
        }
      } catch (e) {
        Get.snackbar("Error", e.toString());
      }
      finally {
        loading.value = false;
      }
    }
  }

  bool _isPhoneNumber(String? s) {
    if (s == null || s.length > 16 || s.length < 9) return false;
    RegExp reg = RegExp(
      r'^[+]*[(]?[0-9]{1,4}[)]?[-\s\./0-9]*$',
    );
    return reg.hasMatch(s);
  }

}

class FullContactAdapter extends TypeAdapter<FullContact> {
  @override
  final typeId = 0;

  @override
  FullContact read(BinaryReader reader) {
    return FullContact.fromMap(reader.read());
  }

  @override
  void write(BinaryWriter writer, FullContact obj) {
    Map<dynamic, dynamic> contact = <dynamic, dynamic>{
      'instantMessengers': obj.instantMessengers,
      'emails': obj.emails,
      'phones': obj.phones,
      'addresses': obj.addresses,
      'name': obj.name,
      'photo': obj.photo,
      'note': obj.note,
      'company': obj.company,
      'sip': obj.sip,
      'relations': obj.relations,
      'customFields': obj.customFields,
    };
    writer.write(contact);
  }
}
