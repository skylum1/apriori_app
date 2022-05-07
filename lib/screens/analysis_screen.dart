import 'dart:collection';

import 'package:data_mining/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../algorithm/apriori_algo.dart';
import '../utils/association.dart';
import '../utils/utils.dart';
import '../widgets.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen(
      {Key? key,
      required this.data,
      required this.minSupport,
      required this.minConfidence,
      required this.algo})
      : super(key: key);
  final List<List<String>> data;
  final String algo;
  final int minSupport, minConfidence;
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late Future<List<Rule>> futureRules;
  Future<IsolateResponse> futureResponse = Future.value(IsolateResponse());
  List<Item> items = [];
  List<Rule>? rules;
  String? elapsedTime;
  late List<List<String>> dataValues;
  int? sortColumnIndex;
  bool isAscending = false;
  bool showPlot = false;

  @override
  void initState() {
    dataValues = widget.data;
    initialize();
    super.initState();
  }

  void initialize() async {
    futureResponse = compute<List<List<String>>, IsolateResponse>(
        initialProcessing, dataValues);
    IsolateResponse response = await futureResponse;
    temp(response.transactionMap, response.itemNames);
  }

  Future<void> temp(HashMap<int, HashSet<String>>? transactionMap,
      List<String> itemNames) async {
    Stopwatch clock = Stopwatch();
    clock.start();
    rules = await compute(
        getAssociationRules,
        IsolateData(
            algo: widget.algo,
            supMin: widget.minSupport,
            confMin: widget.minConfidence,
            transactionMap: transactionMap!,
            itemNames: itemNames));
    clock.stop();
    if (mounted) {
      setState(() {
        elapsedTime = formatTime(clock.elapsed);
      });
    }

    // return rules;
  }

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);
  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      items.sort(
          (user1, user2) => compareString(ascending, user1.name, user2.name));
    } else if (columnIndex == 1) {
      items.sort((item1, item2) => ascending
          ? item1.frequency.compareTo(item2.frequency)
          : item2.frequency.compareTo(item1.frequency));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analysis',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<IsolateResponse>(
              future: futureResponse,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 4,
                        ),
                        const CircularProgressIndicator(),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Getting item Frequency...',
                          // style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  );
                } else {
                  items = snap.data!.items;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Frequency Information',
                          style: kheadingStyle,
                        ),
                        Row(
                          children: [
                            Container(
                                margin: const EdgeInsets.only(left: 18),
                                child: const Text('Show Plot: ')),
                            Switch(
                                value: showPlot,
                                onChanged: (value) {
                                  setState(() {
                                    showPlot = value;
                                  });
                                }),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 3,
                          child: showPlot
                              ? Histogram(
                                  data: items,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                      color: Color(0xff2c4260),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: SingleChildScrollView(
                                    child: Theme(
                                      data: ThemeData.light().copyWith(
                                        iconTheme: const IconThemeData(
                                            color: Colors.white),
                                      ),
                                      child: DataTable(
                                        sortAscending: isAscending,
                                        sortColumnIndex: sortColumnIndex,
                                        horizontalMargin: 10,
                                        columnSpacing: 25,
                                        // border: TableBorder.all(),
                                        columns: ['Name', 'Frequency']
                                            .map((e) => DataColumn(
                                                  onSort: onSort,
                                                  label: Text(
                                                    e,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                ))
                                            .toList(),
                                        rows: items
                                            .map((e) => DataRow(cells: [
                                                  DataCell(Text(
                                                    e.name,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  )),
                                                  DataCell(Text(
                                                    e.frequency.toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  )),
                                                ]))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }
              }),
          DraggableScrollableSheet(
              initialChildSize: 0.48,
              maxChildSize: 1,
              minChildSize: 0.48,
              builder: (context, scrollController) {
                return Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                      color: Color(0xff2A373F),
                    ),
                    child: (rules == null)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Extracting Rules...',
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Number of Rules: ',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      rules!.length.toString(),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              elapsedTime == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 30),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Elapsed time: ',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            elapsedTime!,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                              const SizedBox(
                                height: 20,
                              ),
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(26),
                                        topRight: Radius.circular(26)),
                                    color: Color(0xffF6F6F6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 18),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Rules',
                                              style: kheadingStyle,
                                            ),
                                            Text(
                                              'Algorithm: ${widget.algo}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        // height: 200,
                                        child: ListView.builder(
                                            controller: scrollController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: rules!.length,
                                            itemBuilder: (context, index) {
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 4),
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16.0),
                                                  ),
                                                  color: Colors.white,
                                                  // margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                                  child: Theme(
                                                      data: Theme.of(context)
                                                          .copyWith(
                                                              dividerColor: Colors
                                                                  .transparent),
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                                .symmetric(
                                                            vertical: 10,
                                                            horizontal: 20),
                                                        child: Column(
                                                          children: [
                                                            getRow(
                                                                rules![index]),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            Container(
                                                              margin: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      10),
                                                              child: Row(
                                                                children: [
                                                                  const Text(
                                                                    'Confidence: ',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black54),
                                                                  ),
                                                                  Text(
                                                                    (rules![index].confidence *
                                                                                100)
                                                                            .toStringAsFixed(1) +
                                                                        ' %',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black54,
                                                                        fontWeight:
                                                                            FontWeight.w700),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              );
                                            }),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ));
              })
        ],
      ),
    ));
  }

  String hashSetToString(HashSet<String> value) {
    String temp = '';
    for (int i = 0; i < value.length - 1; i++) {
      temp += value.elementAt(i);
      temp += ', ';
    }
    temp += value.last;
    return temp;
  }

  Widget getRow(Rule rule) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          flex: 2,
          child: Wrap(children: [
            Text(
              hashSetToString(rule.antecedant),
              style: kCardTextStyle,
            ),
          ]),
        ),
        const SizedBox(
          width: 20,
        ),
        Flexible(
          flex: 1,
          child: Wrap(
            children: [
              Text(
                hashSetToString(rule.consequent),
                textAlign: TextAlign.right,
                style: kCardTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatTime(Duration elapsed) {
    String temp = '';
    // print('as: $elapsed');
    if (elapsed.inMinutes > 0) {
      temp += elapsed.inMinutes.toString() + ' min';
    } else if (elapsed.inSeconds > 0) {
      temp += elapsed.inSeconds.toString() + ' s';
    } else {
      temp += elapsed.inMilliseconds.toString() + ' ms';
    }
    return temp;
  }
}

const TextStyle kCardTextStyle =
    TextStyle(fontWeight: FontWeight.w700, fontSize: 18);
IsolateResponse initialProcessing(List<List<String>> dataValues) {
  IsolateResponse response = IsolateResponse();
  print('rr-init: ');
  if (dataValues.isNotEmpty) {
    print('rr: ');

    response.transactionMap = Utility.extractData(dataValues);
    response.itemNames = Utility.extractItem(response.transactionMap!);
    response.items = AlgorithmApriori.getL0frequency(
        response.transactionMap!, response.itemNames);
  }
  return response;
}

List<Rule> getAssociationRules(IsolateData data) {
  var algo = AlgorithmApriori(data.supMin, data.algo);
  print('ii: ${data.itemNames}');

  List<Rule> rules = [];
  var itemList = algo.findLk(data.transactionMap, null,
      algo.generateL1(data.transactionMap, data.itemNames), 1);
  if (itemList != null) {
    var association = Association(data.confMin);
    association.generateAssociationRule(data.transactionMap, itemList);
    rules = association.tabRule;
  }
  rules.sort((a, b) => b.confidence.compareTo(a.confidence));
  return rules;
}

class IsolateResponse {
  List<Item> items = [];
  HashMap<int, HashSet<String>>? transactionMap;
  List<String> itemNames = [];
  IsolateResponse({this.transactionMap});
}

class IsolateData {
  final String algo;
  final int supMin, confMin;
  final HashMap<int, HashSet<String>> transactionMap;
  final List<String> itemNames;
  IsolateData(
      {required this.supMin,
      required this.algo,
      required this.confMin,
      required this.itemNames,
      required this.transactionMap});
}
