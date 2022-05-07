import 'dart:collection';
import 'dart:core';

class Utility {
  static HashMap<int, HashSet<String>> extractData(List<List<String>> data) {
    HashMap<int, HashSet<String>> tabTransaction =
        HashMap<int, HashSet<String>>();
    int key = 0;
    // print('ou: ${data.length}');
    for (var list in data) {
      HashSet<String> transaction = HashSet<String>();
      transaction.addAll(list);
      tabTransaction[key] = transaction;
      key++;
      // transaction.clear();
    }

    return tabTransaction;
  }

  static List<String> extractItem(
      HashMap<int, HashSet<String>> tabTransaction) {
    String temp;
    var tabItem = <String>[];
    var iterator = tabTransaction.values.iterator;
    while (iterator.moveNext()) {
      var iteratorSet = iterator.current.iterator;
      while (iteratorSet.moveNext()) {
        temp = iteratorSet.current;
        if (tabItem.contains(temp) == false) {
          tabItem.add(temp);
        }
      }
    }
    print('items: $tabItem');
    return tabItem;
  }

  static bool isJoinable(HashSet<String> set1, HashSet<String> set2) {
    var count = 0;
    if (set1.length == set2.length) {
      var iterator = set1.iterator;
      while (iterator.moveNext()) {
        if (set2.contains(iterator.current) == true) {
          count++;
        }
      }
      if (count == set1.length - 1) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  static bool contains(List<HashSet<String>> tab, HashSet<String> set) {
    for (var i = 0; i < tab.length; i++) {
      if (tab[i].containsAll(set) == true) {
        return true;
      }
    }
    return false;
  }
}
