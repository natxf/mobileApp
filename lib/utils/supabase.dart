import 'package:supabase_flutter/supabase_flutter.dart';

class SubabaseCredentials{
  static const String subabase_uri='URL';
  static const String supabase_anon_key='ANON_KEY';
}

Future<void> supaInit() async{
  await Supabase.initialize(url: SubabaseCredentials.subabase_uri, anonKey: SubabaseCredentials.supabase_anon_key);
}

SupabaseClient get supabase => Supabase.instance.client;
