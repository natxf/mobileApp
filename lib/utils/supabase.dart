import 'package:supabase_flutter/supabase_flutter.dart';

class SubabaseCredentials{
  static const String subabase_uri='https://inwgeosxpjnkcjivhwha.supabase.co';
  static const String supabase_anon_key='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlud2dlb3N4cGpua2NqaXZod2hhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NjAxMjksImV4cCI6MjA2MzIzNjEyOX0.x5cPcfpyfNWvuqUMCfkjXmf-FCBHiromTtj1QtG4FPs';
}

Future<void> supaInit() async{
  await Supabase.initialize(url: SubabaseCredentials.subabase_uri, anonKey: SubabaseCredentials.supabase_anon_key);
}

SupabaseClient get supabase => Supabase.instance.client;