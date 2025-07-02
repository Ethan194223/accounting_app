import '../models/user_model.dart';

class UserService {
  // quick singleton getter; replace with Provider/Riverpod
  static final _dummy = UserModel(
    id: '1',
    displayName: 'Jackson Smith',
    email: 'jackson@example.com',
    avatarUrl:
    'https://i.pravatar.cc/150?img=3', // placeholder avatar
  );

  static UserModel get current => _dummy;

  static Future<void> deleteAccount() async {
    // TODO hook up to Firebase/Auth
  }
}
