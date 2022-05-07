import 'dart:collection';

class Association {
  late double confMin;
  List<Rule> tabRule = [];

  Association(int confMin) {
    this.confMin = confMin / 100;
  }

  void generatePrimaryRule(
      HashMap<int, HashSet<String>> tabTransaction, HashSet<String> LkSet) {
    print('generatePrimaryRule: $confMin');

    List<String> tab = [];
    var conf1 = 0.0, conf2 = 0.0;
    for (var item in LkSet) {
      tab.add(item);
    }

    for (var i = 0; i < tab.length; i++) {
      HashSet<String> itemSet1 = HashSet<String>();
      itemSet1.add(tab[i]);
      for (var j = i + 1; j < tab.length; j++) {
        HashSet<String> itemSet2 = HashSet<String>();
        itemSet2.add(tab[j]);

        if (!match(antecedant: itemSet1, consequent: itemSet2)) {
          conf1 = calculateConf(tabTransaction, itemSet1, itemSet2);
        }
        if (!match(antecedant: itemSet2, consequent: itemSet1)) {
          conf2 = calculateConf(tabTransaction, itemSet2, itemSet1);
        }
        if (conf1 >= confMin) {
          var rule = Rule(
              antecedant: itemSet1, consequent: itemSet2, confidence: conf1);
          tabRule.add(rule);
        }

        if (conf2 >= confMin) {
          var rule = Rule(
              antecedant: itemSet2, consequent: itemSet1, confidence: conf2);

          tabRule.add(rule);
        }
      }
    }
  }

  double calculateConf(HashMap<int, HashSet<String>> tabTransaction,
      HashSet<String> antecedant, HashSet<String> consequent) {
    var supAntecedant = calculateSupport(tabTransaction, antecedant);
    var supItemSet = 0;
    HashSet<String> itemSet = HashSet<String>();
    itemSet.addAll(antecedant);
    itemSet.addAll(consequent);
    supItemSet = calculateSupport(tabTransaction, itemSet);
    return supItemSet / supAntecedant;
  }

  int calculateSupport(
      HashMap<int, HashSet<String>> tabTransaction, HashSet<String> itemSet) {
    var sup = 0;
    var iterator = tabTransaction.values.iterator;
    while (iterator.moveNext()) {
      if (iterator.current.containsAll(itemSet) == true) {
        sup++;
      }
    }
    return sup;
  }

  List<Rule> generateBaseRule(
      HashMap<int, HashSet<String>> tabTransaction, HashSet<String> LkSet) {
    double conf = 0.0;

    List<Rule> tabRule = [];
    List tab = <String>[];
    for (var item in LkSet) {
      tab.add(item);
    }

    for (var i = tab.length - 1; i >= 0; i--) {
      HashSet<String> consequent = HashSet<String>();
      HashSet<String> antecedent = HashSet<String>();
      consequent.add(tab[i]);
      for (var j = 0; j < tab.length; j++) {
        if (j == i) {
          continue;
        }
        antecedent.add(tab[j]);
      }
      if (!match(antecedant: antecedent, consequent: consequent)) {
        conf = calculateConf(tabTransaction, antecedent, consequent);
      }

      if (conf >= confMin) {
        var rule = Rule(
            antecedant: antecedent, consequent: consequent, confidence: conf);

        tabRule.add(rule);
      }
    }
    return tabRule;
  }

  void generateRules(
      HashMap<int, HashSet<String>> tabTransaction, List<Rule> tabRule) {
    Queue queueRule = Queue<Rule>();
    for (var i = 0; i < tabRule.length; i++) {
      queueRule.add(tabRule[i]);
    }

    while (queueRule.isEmpty == false) {
      Rule temp = queueRule.removeFirst();
      if (temp.antecedant.length >= 2) {
        var tab =
            generateNewRule(tabTransaction, temp.antecedant, temp.consequent);
        if (tab != null) {
          for (var i = 0; i < tab.length; i++) {
            queueRule.add(tab[i]);
          }
        }
      }
      this.tabRule.add(temp);
    }
  }

  List<Rule>? generateNewRule(HashMap<int, HashSet<String>> tabTransaction,
      HashSet<String> antecedant, HashSet<String> consequent) {
    var rep = false;
    List<Rule> tabRule = [];
    var conf = 0.0;

    List tab = <String>[];
    for (var item in antecedant) {
      tab.add(item);
    }

    for (var i = tab.length - 1; i >= 0; i--) {
      HashSet<String> ant = HashSet<String>();
      HashSet<String> con = HashSet<String>();
      con.add(tab[i]);
      con.addAll(consequent);
      for (var j = 0; j < tab.length; j++) {
        if (j == i) {
          continue;
        }
        ant.add(tab[j]);
      }
      if (!match(antecedant: ant, consequent: con)) {
        conf = calculateConf(tabTransaction, ant, con);
      }
      if (conf >= confMin) {
        rep = true;
        var rule = Rule(antecedant: ant, confidence: conf, consequent: con);
        tabRule.add(rule);
      }
    }

    if (rep == false) {
      return null;
    } else {
      return tabRule;
    }
  }

  void generateAssociationRule(HashMap<int, HashSet<String>> tabTransaction,
      List<HashSet<String>> tabLk) {
    if (tabLk.isNotEmpty) {
      for (var Lk in tabLk) {
        // print('ih: $Lk');
        generatePrimaryRule(tabTransaction, Lk);

        print('ao: $tabRule');
        // print('bb');
        var tabRuleBase = generateBaseRule(tabTransaction, Lk);
        print('$tabRuleBase');
        generateRules(tabTransaction, tabRuleBase);
      }
    } else {
      print('Lk empty');
    }
    unique();
  }

  bool match(
      {required HashSet<String> antecedant,
      required HashSet<String> consequent}) {
    for (var rule in tabRule) {
      if (rule.antecedant.containsAll(antecedant) &&
          antecedant.containsAll(rule.antecedant) &&
          rule.consequent.containsAll(consequent) &&
          consequent.containsAll(rule.consequent)) {
        return true;
      }
    }
    return false;
  }

  void unique() {
    // HashSet<String> a1 = HashSet<String>();
    // a1.add('a');
    // HashSet<String> b1 = HashSet<String>();
    // b1.add('b');
    // HashSet<String> c1 = HashSet<String>();
    // c1.add('a');
    // HashSet<String> d1 = HashSet<String>();
    // d1.add('b');
    // Rule a = Rule(antecedant: a1, consequent: b1, conf: 0.5);
    // Rule b = Rule(antecedant: c1, consequent: d1, conf: 0.5);

    // Set<Rule> r = {};
    // r.add(a);
    // r.add(b);
    List<Rule> temp = [];
    bool match = false;
    for (int i = 0; i < tabRule.length; i++) {
      // print('qq: ${tabRule[i]}');
      for (int j = i + 1; j < tabRule.length; j++) {
        if (tabRule[i] == tabRule[j]) {
          match = true;
          break;
        }
      }
      if (!match) temp.add(tabRule[i]);
      match = false;
    }
    tabRule = temp;
    // print(
    //     'unique ,${tabRule[tabRule.length - 1]}, ${tabRule[tabRule.length - 2]}, ${temp.length}');
  }
}

class Rule {
  HashSet<String> antecedant;
  HashSet<String> consequent;
  double confidence;
  Rule(
      {required this.antecedant,
      required this.consequent,
      required this.confidence});
  @override
  String toString() {
    return '$antecedant -----> $consequent  conf $confidence';
  }

  @override
  bool operator ==(dynamic other) {
    return other is Rule &&
        other.antecedant.containsAll(antecedant) &&
        antecedant.containsAll(other.antecedant) &&
        other.consequent.containsAll(consequent) &&
        consequent.containsAll(other.consequent);
  }

  @override
  int get hashCode => Object.hash(antecedant, consequent);
}
