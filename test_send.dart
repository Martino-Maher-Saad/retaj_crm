import 'package:supabase_flutter/supabase_flutter.dart'; void main() { final channel = Supabase.instance.client.channel('foo'); channel.sendBroadcastMessage(event: 'event', payload: {}); }
