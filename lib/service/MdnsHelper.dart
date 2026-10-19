import 'package:multicast_dns/multicast_dns.dart';

class MdnsHelper {
  static Future<String?> discoverService() async {
    final client = MDnsClient();
    await client.start();

    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.service('_http._tcp'))) {
      print('Found service: ${ptr.domainName}');
      // bisa return domainName atau IP sesuai kebutuhan
      return ptr.domainName;
    }

    return null;
  }
}
