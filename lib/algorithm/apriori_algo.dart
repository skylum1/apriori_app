import 'dart:collection';

import '../utils/utils.dart';

class AlgorithmApriori {
  late int supMin;
  final String algoType;
  bool ableToGenerateCk = true;
  bool ableToGenerateLk = true;

  AlgorithmApriori(this.supMin, this.algoType);

  List<HashSet<String>>? findLk(HashMap<int, HashSet<String>> tabTransaction,
      List<HashSet<String>>? tabLk, List<String> tabL1, int k) {
    if (ableToGenerateLk == false) {
      return tabLk;
    } else {
      List<HashSet<String>> CkSet = [];
      if (k == 1) {
        if (algoType == 'DHP') {
          CkSet = generateDhpC2(tabL1, tabTransaction);
        } else {
          CkSet = generateC2(tabL1);
        }
      } else {
        CkSet = generateCk(tabLk!);
      }
      k++;
      if (ableToGenerateCk == false) {
        return tabLk;
      } else {
        List<HashSet<String>> LkSet = generateLk(tabTransaction, CkSet);
        if (ableToGenerateLk == false) {
          return tabLk;
        } else {
          // print(
          //     '****************************            ************************');
          // print('candidate ${CkSet.length} size: ${CkSet[0].length}');
          // print('Lk length: ${LkSet.length}');
          // print('Lk: $LkSet');
          // print(
          //     '****************************       $k     ************************');
          return findLk(tabTransaction, LkSet, tabL1, k);
        }
      }
    }
  }

  static List<Item> getL0frequency(
      HashMap<int, HashSet<String>> tabTransaction, List<String> tabItem) {
    var sup = 0;
    List<Item> itemFrequency = [];
    for (var i = 0; i < tabItem.length; i++) {
      var iterator = tabTransaction.values.iterator;
      while (iterator.moveNext()) {
        if (iterator.current.contains(tabItem[i]) == true) {
          sup++;
        }
      }
      itemFrequency.add(Item(i, name: tabItem[i], frequency: sup));
      sup = 0;
    }

    return itemFrequency;
  }

  List<String> generateL1(
      HashMap<int, HashSet<String>> tabTransaction, List<String> tabItem) {
    var sup = 0;
    List<String> tabL1 = [];
    for (var i = 0; i < tabItem.length; i++) {
      var iterator = tabTransaction.values.iterator;
      while (iterator.moveNext()) {
        if (iterator.current.contains(tabItem[i]) == true) {
          sup++;
        }
      }
      print('L0: ${tabItem[i]},s: ${tabItem[i].length} sup: $sup');
      if (sup >= supMin) {
        tabL1.add(tabItem[i]);
      }
      sup = 0;
    }
    print('L1: $tabL1');
    return tabL1;
  }

  List<HashSet<String>> generateDhpC2(
      List<String> tabL1, HashMap<int, HashSet<String>> tabTransaction) {
    List<HashSet<String>> tabC2 = [];

    HashMap<HashSet<String>, int> bucket =
        HashMap<HashSet<String>, int>(hashCode: (set) {
      return Object.hash(set.toString(), null);
    }, equals: (val1, val2) {
      if (val1.containsAll(val2) && val2.containsAll(val1)) {
        return true;
      } else {
        return false;
      }
    });
    String temp;
    var iterator = tabTransaction.values.iterator;

    while (iterator.moveNext()) {
      var iteratorSet = iterator.current.iterator;
      List<String> freq = [];
      while (iteratorSet.moveNext()) {
        temp = iteratorSet.current;
        if (tabL1.contains(temp) == true) {
          freq.add(temp);
        }
      }
      for (var i = 0; i < freq.length; i++) {
        for (var j = i + 1; j < freq.length; j++) {
          HashSet<String> C2 = HashSet<String>();
          C2.add(freq[i]);
          C2.add(freq[j]);
          if (bucket[C2] != null) {
            bucket[C2] = bucket[C2]! + 1;
          } else {
            bucket[C2] = 0;
          }
        }
      }
    }
    var itr = bucket.keys.iterator;
    while (itr.moveNext()) {
      if (bucket[itr.current]! >= supMin) {
        tabC2.add(itr.current);
      }
    }
    // print('C2: $tabC2');
    return tabC2;
  }

  List<HashSet<String>> generateC2(List<String> tabL1) {
    List<HashSet<String>> tabC2 = [];
    for (var i = 0; i < tabL1.length; i++) {
      for (var j = i + 1; j < tabL1.length; j++) {
        HashSet<String> C2 = HashSet<String>();
        C2.add(tabL1[i]);
        C2.add(tabL1[j]);
        tabC2.add(C2);
      }
    }
    // print('C2: $tabC2');
    return tabC2;
  }

  List<HashSet<String>> generateCk(List<HashSet<String>> tab) {
    List<HashSet<String>> tabCk = [];
    var count = 0;
    for (var i = 0; i < tab.length; i++) {
      for (var j = i + 1; j < tab.length; j++) {
        if (Utility.isJoinable(tab[i], tab[j]) == true) {
          HashSet<String> Ck = HashSet<String>();
          Ck.addAll(tab[i]);
          Ck.addAll(tab[j]);
          if (Utility.contains(tabCk, Ck) == false) {
            tabCk.add(Ck);
            //print('enter');
          }
          count++;
        }
      }
    }
    if (count == 0) {
      ableToGenerateCk = false;
    }
    return tabCk;
  }

  List<HashSet<String>> generateLk(
      HashMap<int, HashSet<String>> tabTransaction, List<HashSet<String>> tab) {
    int sup = 0;
    List<HashSet<String>> tabLk = [];
    // int count = 0;
    for (var i = 0; i < tab.length; i++) {
      var iterator = tabTransaction.values.iterator;
      while (iterator.moveNext()) {
        if (iterator.current.containsAll(tab[i]) == true) {
          sup++;
        }
      }

      if (sup >= supMin) {
        tabLk.add(tab[i]);
        // count++;
      }
      sup = 0;
    }
    if (tabLk.isEmpty) {
      ableToGenerateLk = false;
    }
    return tabLk;
  }
}

class Item {
  final int id;
  final String name;
  final int frequency;
  Item(this.id, {required this.name, required this.frequency});
}
