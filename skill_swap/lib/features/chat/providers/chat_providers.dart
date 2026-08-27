import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../auth/providers/auth_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((_) => ChatRepository());

final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchUserChats(user.uid);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});
