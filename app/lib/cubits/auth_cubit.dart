import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/user_repository.dart';

enum AuthStatus { inside, out, checking }

class AuthState extends Equatable {
  final User? user;
  final bool loginLoading;

  final AuthStatus status;

  const AuthState(
      {required this.user,
      this.loginLoading = false,
      this.status = AuthStatus.checking});

  copyWith({User? user, bool? loginLoading, AuthStatus? status}) {
    return AuthState(
      user: user ?? this.user,
      loginLoading: loginLoading ?? this.loginLoading,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [user, loginLoading, status];
}

class AuthCubit extends Cubit<AuthState> {
  final UserRepository _repo = locator.get<UserRepository>();

  AuthCubit() : super(AuthState(user: null));

  void init() async {
    final currentUser = await _repo.getUser();

    if (currentUser == null) {
      emit(state.copyWith(status: AuthStatus.out));
    } else {
      emit(state.copyWith(
        status: AuthStatus.inside,
        user: currentUser,
      ));
    }

    // _repo.currentUser.listen((user) {
    //   emit(state.copyWith(
    //     user: user,
    //     status: user == null ? AuthStatus.out : null,
    //   ));
    // });

    unawaited(_repo.getUser(live: true));
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);

    final user = change.nextState.user;
    if (user != null) {
      // Sentry.configureScope((scope) async {
      //   await scope.setUser(
      //     SentryUser(
      //         id: user.uid,
      //         segment: user.claims.grade,
      //         data: {"phone": user.phone}),
      //   );

      //   if (user.claims.isPremium) {
      //     await scope.setTag("premium", "true");
      //   }
      // });
    }
  }
}
