import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:data_mining/constants.dart';
import 'package:data_mining/screens/analysis_screen.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(DevicePreview(
      enabled: !kReleaseMode, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.light,
      darkTheme: ThemeData.dark(),
      title: 'Apriori App',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(primarySwatch: Colors.indigo, brightness: Brightness.light),

      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      // theme: ThemeData.light(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int colCount = 0, minSupport = 1, minConfidence = 50;
  String dropdownvalue = 'Apriori';
  FocusNode textSecondFocusNode = FocusNode();

  List<PlatformFile>? _paths;
  List<List<String>>? dataValues;
  bool dlo = false;
  int uniqueCount = 0;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      uniqueCount = 0;
      _paths = null;
      dlo = false;
      colCount = 0;
      dataValues = null;
      // _saveAsFileName = null;
    });
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  List<List<String>> preProcessing(List<List<String>> input) {
    print('pp: ');
    List<List<String>> temp = [];
    String name = '';
    if (input.isNotEmpty) {
      for (var list in input) {
        List<String> str = [];
        for (var item in list) {
          name = item.trim();
          if (name.isNotEmpty) {
            str.add(name);
          }
        }
        temp.add(str);
      }
    }
    print('ppo: ${temp.length}, $colCount');
    return temp;
  }

  void readFile(String path) {
    final File temp = File(path);
    String data = temp.readAsStringSync();
    List<List<String>> rowsAsListOfValues =
        const CsvToListConverter(shouldParseNumbers: false).convert(data);
    for (var element in rowsAsListOfValues) {
      colCount = max(element.length, colCount);
    }
    dataValues = preProcessing(rowsAsListOfValues);
    if (dataValues!.isEmpty) {
      _resetState();
    } else {
      setState(() {
        uniqueCount = getUniqueCount();
      });
    }
    //
    // print(
    //     'oo: ${_paths![0].path!}, ${rowsAsListOfValues[rowsAsListOfValues.length - 1]}');
  }

  void _pickFiles() async {
    _resetState();
    try {
      // _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false, //_multiPick,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: ['csv'],
      ))
          ?.files;
      if (_paths?[0].path != null) {
        if (_paths![0].extension == 'csv') {
          readFile(_paths![0].path!);
          if (mounted) {
            setState(() {
              dlo = true;
            });
          }
        } else {
          showDialog(
            builder: (context) => Container(
              decoration: const ShapeDecoration(
                  shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30),
                ),
              )),
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Text(
                  'Please select csv file , ${_paths![0].extension} extension not supported',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Ok'),
                  ),
                ],
              ),
            ),
            context: context,
          );
        }
      }
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
  }

  int getUniqueCount() {
    Set<String> set = {};
    if (dataValues != null) {
      for (var list in dataValues!) {
        for (var item in list) {
          set.add(item);
        }
      }
    }
    return set.length;
  }

  List<DataRow> rowList() {
    List<DataRow> temp = [];
    int i = 0;
    List<String> el = [];
    if (dataValues != null) {
      for (int j = 0; j < min(dataValues!.length, 60); j++) {
        el = dataValues![j];
        temp.add(DataRow(cells: [
          DataCell(Text('${j + 1}')),
          for (i = 0; i < el.length; i++) DataCell(Text(el[i])),
          for (i = el.length; i < colCount; i++) DataCell.empty
        ]));
      }
    }
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffDFEBE9),
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: dlo ? 4 : 1,
              child: dlo
                  ? InteractiveViewer(
                      constrained: false,
                      scaleEnabled: false,
                      // scrollDirection: Axis.horizontal,
                      child: colCount == 0
                          ? const SizedBox.shrink()
                          : DataTable(
                              horizontalMargin: 10,
                              columnSpacing: 25,
                              // border: TableBorder.all(),
                              columns: List.generate(
                                      colCount + 1,
                                      (index) =>
                                          index == 0 ? 'Sno' : 'Item $index')
                                  .map((e) => DataColumn(
                                        label: Text(
                                          e,
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ))
                                  .toList(),
                              rows: rowList(),
                            ),
                    )
                  : GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          dashPattern: const [3, 3, 3, 3],
                          radius: const Radius.circular(30),
                          child: SizedBox(
                            width: 250,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Opacity(
                                  opacity: 0.5,
                                  child: Image.asset(
                                    'assets/database.png',
                                    height: 45,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Text(
                                  'Add Data (csv)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Colors.white,
                ),
                child: ScrollConfiguration(
                  behavior: MyBehavior(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        MyExpansionTile(
                          initiallyExpanded: true,
                          childrenPadding: const EdgeInsets.only(left: 18),
                          title: const Text(
                            'Dataset Details',
                            style: kheadingStyle,
                          ),
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Number of Columns: ',
                                  style: TextStyle(
                                      // color:
                                      ),
                                ),
                                Text(colCount.toString())
                              ],
                            ),
                            dataValues == null
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      const Text(
                                        'Number of Rows: ',
                                        style: TextStyle(
                                            // color:
                                            ),
                                      ),
                                      Text(dataValues!.length.toString())
                                    ],
                                  ),
                            Row(
                              children: [
                                const Text('Number of Unique Values: '),
                                Text(uniqueCount.toString())
                              ],
                            )
                          ],
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              MyExpansionTile(
                                initiallyExpanded: true,
                                childrenPadding:
                                    const EdgeInsets.only(left: 18),
                                title: const Text(
                                  'Parameters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Algorithm: ',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            23, 10, 23, 10),
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton(
                                            value: dropdownvalue,
                                            items: ['Apriori', 'DHP']
                                                .map((e) => DropdownMenuItem(
                                                    value: e, child: Text(e)))
                                                .toList(),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            onChanged: (String? item) {
                                              setState(() {
                                                dropdownvalue =
                                                    item ?? 'Apriori';
                                              });
                                            },

                                            // onChanged: (value) => {
                                            //   feedbackType = value,
                                            // },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  MyTextFormField(
                                    onFieldSubmitted: (String value) {
                                      FocusScope.of(context)
                                          .requestFocus(textSecondFocusNode);
                                    },
                                    textInputAction: TextInputAction.next,
                                    hintText: 'Minimum support (in %)',
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter minimum support';
                                      } else if (int.tryParse(value) == null) {
                                        return 'Please enter only integer value';
                                      } else if (int.tryParse(value)! < 0) {
                                        return 'Please enter positive value';
                                      }
                                      return null;
                                    },
                                    onSaved: (String? value) {
                                      if (value != null) {
                                        minSupport = int.tryParse(value) ?? 0;
                                      }
                                    },
                                  ),
                                  MyTextFormField(
                                    focusNode: textSecondFocusNode,
                                    textInputAction: TextInputAction.done,
                                    hintText: 'Minimum confidence (in %)',
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter minimum confidence';
                                      } else if (int.tryParse(value) == null) {
                                        return 'Please enter only integer value';
                                      } else if (int.tryParse(value)! > 100 ||
                                          int.tryParse(value)! <= 0) {
                                        return 'Please enter value between 0 and 100';
                                      }

                                      return null;
                                    },
                                    onSaved: (value) {
                                      if (value != null) {
                                        minConfidence =
                                            int.tryParse(value) ?? 0;
                                      }
                                    },
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ))),
                                onPressed: () {
                                  if (_formKey.currentState != null &&
                                      _formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    if (dataValues == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please load data first')));
                                    } else {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AnalysisScreen(
                                                    algo: dropdownvalue,
                                                    data: dataValues!,
                                                    minConfidence:
                                                        minConfidence,
                                                    minSupport: (minSupport /
                                                            100 *
                                                            dataValues!.length)
                                                        .toInt(),
                                                  )));
                                    }
                                  }
                                },
                                child: const Text('Analyze'),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Get Data',
          onPressed: _pickFiles,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class MyTextFormField extends StatelessWidget {
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  const MyTextFormField({
    this.hintText,
    this.validator,
    this.onSaved,
    required this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 18, bottom: 10),
      child: TextFormField(
        onFieldSubmitted: onFieldSubmitted,
        focusNode: focusNode,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.all(15.0),
          // border: InputBorder.none,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),

          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: validator,
        onSaved: onSaved,
        keyboardType: TextInputType.number,
      ),
    );
  }
}
