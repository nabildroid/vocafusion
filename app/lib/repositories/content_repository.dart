import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast_io.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/models/modeling.dart';

class ContentRepository extends AuthorizedDio {
  final Database _db = locator.get();
  final isOnline = BehaviorSubject<bool>.seeded(false);

  ContentRepository() : super(rawHttp: AuthorizedDio.defaultHttp) {
    Connectivity().onConnectivityChanged.listen(
          (status) => isOnline.add(!status.contains(ConnectivityResult.none)),
        );

    completerhttp.complete(rawHttp);
  }

  Future<List<WordsFlow>> getFlowsByFilters(FlowFilter filter) async {
    final reponse = await (await http)
        .get("flows/${filter.nativeLanguage}/${filter.targetLanguage}");

    return List.from(reponse.data["flows"])
        .map((e) => WordsFlow(
              id: e["id"],
              targetLanguage: filter.targetLanguage,
              nativeLanguage: filter.nativeLanguage,
              level: 1,
              title: e["title"],
            ))
        .toList();
  }

  Future<List<WordsFlow>> getFlowsByParentFlowId(String flowId) async {
    final reponse = await (await http).get("flows/$flowId");

    return List.from(reponse.data["flows"])
        .map((e) => WordsFlow(
              id: e["id"],
              targetLanguage: "FR",
              nativeLanguage: "EN",
              level: 1,
              parentFlow: e["parentId"],
              title: e["title"],
            ))
        .toList();
  }

  Future<WordsFlow> getFlowsById(String flowId) async {
    final reponse = await (await http).get("flow/$flowId");
    return WordsFlow(
      id: "ezfze",
      targetLanguage: "fr",
      nativeLanguage: "en",
      level: 2,
      title: "helllo world",
    );
  }

  Future<List<WordCard>> getWordsByFlowId(String flowId) async {
    final reponse = await (await http).get("words/$flowId");
    return List.from(reponse.data["words"])
        .map((e) => WordCard(
              context: e["text"],
              aloneContext: e["text"],
              previousSummary: e["text"],
              id: e["id"],
              word: e["word"],
              targetDefinition: e["targetDefinition"],
              nativeDefinition: e["nativeDefinition"],
              previousCard: e["previousCard"],
              flowId: flowId,
              level: "1",
              nativeLanguage: "fr",
              targetLanguage: "en",
              nativeWord: e["word"],
              transliteration: e["word"],
              audioUrl: "efefze",
            ))
        .toList();
  }
}

class FlowFilter {
  final String targetLanguage;
  final String nativeLanguage;

  FlowFilter({
    required this.targetLanguage,
    required this.nativeLanguage,
  });
}
