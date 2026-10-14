import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Учебное пособие по подготовке спортсмена',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ProfileGate(),
    );
  }
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  bool? _profileExists;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');

    if (mounted) {
      setState(() => _profileExists = name != null && name.isNotEmpty);
    }
  }

  Future<void> _saveProfile({
    required String name,
    required String gender,
    required DateTime birthDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_gender', gender);
    await prefs.setString('profile_birth_date', birthDate.toIso8601String());

    if (mounted) {
      setState(() => _profileExists = true);
    }
  }

  Future<void> _editProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = DateTime.tryParse(
      prefs.getString('profile_birth_date') ?? '',
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialName: prefs.getString('profile_name') ?? '',
          initialGender: prefs.getString('profile_gender'),
          initialBirthDate: savedDate,
          onSave: _saveProfile,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileExists == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_profileExists!) {
      return ProfileScreen(onSave: _saveProfile);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Учебное пособие по подготовке спортсмена'),
        actions: [
          IconButton(
            tooltip: 'Личный кабинет',
            icon: const Icon(Icons.account_circle),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: ExerciseGuide(
        key: ValueKey(
          '${_profileExists}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onSave,
    this.initialName = '',
    this.initialGender,
    this.initialBirthDate,
  });

  final String initialName;
  final String? initialGender;
  final DateTime? initialBirthDate;

  final Future<void> Function({
  required String name,
  required String gender,
  required DateTime birthDate,
  }) onSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  String? _gender;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gender = widget.initialGender;
    _birthDate = widget.initialBirthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Выберите дату рождения',
    );

    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите пол и дату рождения')),
      );
      return;
    }

    setState(() => _saving = true);

    await widget.onSave(
      name: _nameController.text.trim(),
      gender: _gender!,
      birthDate: _birthDate!,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    // При редактировании закрывает экран профиля.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Личный кабинет')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.account_circle, size: 72),
                  const SizedBox(height: 12),
                  Text(
                    'Заполните профиль',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Пол',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),
                      DropdownMenuItem(value: 'Женский', child: Text('Женский')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (value) =>
                    value == null ? 'Выберите пол' : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _birthDate == null
                          ? 'Выбрать дату рождения'
                          : 'Дата рождения: ${_formatDate(_birthDate!)}',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Сохранить и продолжить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseGuide extends StatefulWidget {
  const ExerciseGuide({Key? key}) : super(key: key);

  @override
  _ExerciseGuideState createState() => _ExerciseGuideState();
}

class _ExerciseGuideState extends State<ExerciseGuide> {
  String _currentSection = 'main';
  String? _profileGender;
  DateTime? _profileBirthDate;

  void _showSection(String section) {
    setState(() {
      _currentSection = section;
    });
  }

  List<TextEditingController> _createResultRow([List<String>? values]) {
    return List.generate(
      7,
          (index) => TextEditingController(
        text: values != null && index < values.length ? values[index] : '',
      ),
    );
  }

  void _addResultRow() {
    setState(() {
      _resultRows.add(_createResultRow());
    });
    _saveResults();
  }

  Future<void> _selectResultDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      controller.text =
      '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
      await _saveResults();
    }
  }

  @override
  void dispose() {
    for (final row in _resultRows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  bool _resultsLoaded = false;

  String _calculateRowSum(List<TextEditingController> row) {
    final values = [row[2].text, row[4].text, row[6].text];

    final sum = values.fold<double>(0, (total, value) {
      // Поддерживает ввод как целых, так и дробных чисел с запятой.
      final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
      return total + (parsed ?? 0);
    });

    return sum == sum.roundToDouble()
        ? sum.toInt().toString()
        : sum.toStringAsFixed(2);
  }

  Future<void> _loadProfileForQualification() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _profileGender = prefs.getString('profile_gender');
      _profileBirthDate = DateTime.tryParse(
        prefs.getString('profile_birth_date') ?? '',
      );
    });
  }

  int? _profileAge() {
    final birthDate = _profileBirthDate;
    if (birthDate == null) return null;

    final today = DateTime.now();
    var age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  String _qualificationLevel(int sum) {
    final age = _profileAge();
    final gender = _profileGender;

    if (age == null || age < 0) return '—';

    int third;
    int second;
    int first;
    int highest;

    if (gender == 'Мужской') {
      if (age < 25) {
        third = 190;
        second = 200;
        first = 210;
        highest = 230;
      } else if (age <= 29) {
        third = 180;
        second = 190;
        first = 200;
        highest = 220;
      } else if (age <= 34) {
        third = 170;
        second = 180;
        first = 190;
        highest = 210;
      } else if (age <= 39) {
        third = 150;
        second = 160;
        first = 170;
        highest = 190;
      } else if (age <= 44) {
        third = 130;
        second = 140;
        first = 150;
        highest = 160;
      } else if (age <= 49) {
        third = 100;
        second = 110;
        first = 120;
        highest = 130;
      } else {
        return '—';
      }
    } else if (gender == 'Женский') {
      if (age < 25) {
        third = 80;
        second = 85;
        first = 90;
        highest = 95;
      } else if (age <= 29) {
        third = 70;
        second = 75;
        first = 80;
        highest = 85;
      } else if (age <= 34) {
        third = 60;
        second = 65;
        first = 70;
        highest = 75;
      } else if (age <= 39) {
        third = 50;
        second = 55;
        first = 60;
        highest = 65;
      } else if (age <= 44) {
        third = 40;
        second = 45;
        first = 50;
        highest = 55;
      } else {
        return '—';
      }
    } else {
      return '—';
    }

    if (sum >= highest) return 'высший';
    if (sum >= first) return 'первый';
    if (sum >= second) return 'второй';
    if (sum >= third) return 'третий';
    return '—';
  }

  Widget _buildExerciseDropdown({
    required TextEditingController controller,
    required int first,
    required int last,
  }) {
    final currentValue = int.tryParse(controller.text);
    final value = currentValue != null &&
        currentValue >= first &&
        currentValue <= last
        ? currentValue
        : null;

    return DropdownButton<int>(
      value: value,
      hint: const Text('№'),
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: [
        for (var number = first; number <= last; number++)
          DropdownMenuItem(
            value: number,
            child: Text('$number'),
          ),
      ],
      onChanged: (number) {
        if (number == null) return;
        setState(() {
          controller.text = number.toString();
        });
        _saveResults();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _powerText = rootBundle.loadString('assets/txt/power.txt');
    _speedText = rootBundle.loadString('assets/txt/speed.txt');
    _enduranceText = rootBundle.loadString('assets/txt/endurance.txt');

    _loadResults();
    _loadProfileForQualification();
  }

  Future<void> _loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exercise_results');

    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;

      for (final item in decoded) {
        final values = List<String>.from(item as List);
        _resultRows.add(_createResultRow(values));
      }
    }

    if (_resultRows.isEmpty) {
      _resultRows.add(_createResultRow());
      await _saveResults();
    }

    if (mounted) {
      setState(() {
        _resultsLoaded = true;
      });
    }
  }

  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _resultRows
        .map((row) => row.map((controller) => controller.text).toList())
        .toList();

    await prefs.setString('exercise_results', jsonEncode(data));
  }

  late final Future<String> _powerText;
  late final Future<String> _speedText;
  late final Future<String> _enduranceText;

  final List<List<TextEditingController>> _resultRows = [];

  // Данные для таблиц
  final List<List<String>> tableData1 = [
    ['Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы'],
    ['50', '100', '40', '80', '30', '60', '20', '40', '10', '18'],
    ['49', '98', '39', '78', '29', '58', '19', '38', '9', '16'],
    ['48', '96', '38', '76', '28', '56', '18', '36', '8', '14'],
    ['47', '94', '37', '74', '27', '54', '17', '34', '7', '12'],
    ['46', '92', '36', '72', '26', '52', '16', '32', '6', '10'],
    ['45', '90', '35', '70', '25', '50', '15', '30', '5', '8'],
    ['44', '88', '34', '68', '24', '48', '14', '27', '4', '6'],
    ['43', '86', '33', '66', '23', '46', '13', '24', '3', '4'],
    ['42', '84', '32', '64', '22', '44', '12', '22', '2', '2'],
    ['41', '82', '31', '62', '21', '42', '11', '20', '1', '1'],
  ];
  final List<List<String>> tableData2 = [
    ['Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы'],
    ['60', '100', '48', '64', '36', '36', '24', '24', '12', '12'],
    ['59', '97', '47', '61', '35', '35', '23', '23', '11', '11'],
    ['58', '94', '46', '58', '34', '34', '22', '22', '10', '10'],
    ['57', '91', '45', '55', '33', '33', '21', '21', '9', '9'],
    ['56', '88', '44', '52', '32', '32', '20', '20', '8', '8'],
    ['55', '85', '43', '49', '31', '31', '19', '19', '7', '7'],
    ['54', '82', '42', '46', '30', '30', '18', '18', '6', '6'],
    ['53', '79', '41', '43', '29', '29', '17', '17', '5', '5'],
    ['52', '76', '40', '40', '28', '28', '16', '16', '4', '4'],
    ['51', '73', '39', '39', '27', '27', '15', '15', '3', '3'],
    ['50', '70', '38', '38', '26', '26', '14', '14', '2', '2'],
    ['49', '67', '37', '37', '25', '25', '13', '13', '-', '-'],
  ];
  final List<List<String>> tableData3 = [
    ['Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы', 'Количество раз', 'Баллы'],
    ['25', '100', '20', '80', '15', '70', '10', '50', '5', '30'],
    ['24', '95', '19', '78', '14', '66', '9', '46', '4', '26'],
    ['23', '91', '18', '76', '13', '62', '8', '42', '3', '22'],
    ['22', '87', '17', '74', '12', '58', '7', '38', '2', '16'],
    ['21', '83', '16', '72', '11', '54', '6', '34', '1', '8'],
  ];
  final List<List<String>> tableData17 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['7,8', '8,0', '100', '8,9', '9,1', '65', '9,8', '10,2', '24', '10,9', '11,3', '11'],
    ['7,9', '8,1', '98', '9,0', '9,2', '60', '9,9', '10,3', '21', '11,1', '11,4', '10'],
    ['8,0', '8,2', '96', '9,1', '9,3', '55', '10,0', '10,4', '20', '11,1', '11,5', '9'],
    ['8,1', '8,3', '94', '9,2', '9,4', '50', '10,1', '10,5', '19', '11,2', '11,6', '8'],
    ['8,2', '8,4', '92', '9,3', '9,5', '45', '10,2', '10,6', '18', '11,3', '11,7', '7'],
    ['8,3', '8,5', '90', '-', '9,6', '41', '10,3', '10,7', '17', '11,4', '11,8', '6'],
    ['8,4', '8,6', '87', '9,4', '9,7', '40', '10,4', '10,8', '16', '11,5', '11,9', '5'],
    ['8,5', '8,7', '84', '9,5', '9,8', '35', '10,5', '10,9', '15', '11,6', '12,0', '4'],
    ['8,6', '8,8', '80', '-', '9,9', '32', '10,6', '11,0', '14', '11,7', '12,1', '3'],
    ['8,7', '8,9', '75', '9,6', '10,0', '30', '10,7', '11,1', '13', '11,8', '12,2', '2'],
    ['8,8', '9,0', '70', '9,7', '10,1', '27', '10,8', '11,2', '12', '-', '-', '-'],
  ];
  final List<List<String>> tableData18 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['12,0', '13,0', '100', '13,6', '14,4', '64', '14,8', '15,6', '36', '17,1', '17,8', '18'],
    ['12,1', '13,1', '98', '13,7', '-', '61', '14,9', '15,7', '35', '17,3', '18,0', '17'],
    ['12,2', '13,2', '96', '-', '14,5', '60', '15,0', '15,8', '34', '17,5', '18,2', '16'],
    ['12,3', '13,3', '94', '13,8', '-', '58', '15,1', '15,9', '33', '17,6', '18,4', '15'],
    ['12,4', '13,4', '92', '-', '14,6', '56', '15,2', '16,0', '32', '17,7', '18,6', '14'],
    ['12,5', '13,5', '90', '13,9', '-', '55', '15,3', '16,1', '31', '17,8', '18,8', '13'],
    ['12,6', '13,6', '88', '14,0', '14,7', '52', '15,4', '16,2', '30', '18,0', '19,0', '12'],
    ['12,7', '13,7', '86', '14,1', '-', '50', '15,5', '16,3', '29', '18,1', '19,1', '11'],
    ['12,8', '13,8', '84', '14,2', '14,8', '48', '15,6', '16,4', '28', '18,2', '19,2', '10'],
    ['12,9', '13,9', '82', '14,3', '-', '46', '15,7', '16,5', '27', '18,3', '19,3', '9'],
    ['13,0', '14,0', '80', '-', '14,9', '45', '15,8', '16,6', '26', '18,4', '19,4', '8'],
    ['13,1', '-', '78', '14,4', '-', '44', '15,9', '16,7', '25', '18,6', '19,6', '7'],
    ['13,2', '14,1', '76', '14,5', '15,0', '42', '16,0', '16,8', '24', '18,8', '19,8', '6'],
    ['13,3', '-', '73', '-', '15,1', '41', '16,1', '16,9', '23', '19,0', '20,0', '5'],
    ['-', '14,2', '72', '14,6', '15,2', '40', '16,3', '17,0', '22', '19,2', '20,2', '4'],
    ['13,4', '-', '70', '-', '15,3', '39', '16,5', '17,2', '21', '19,4', '20,4', '3'],
    ['-', '14,3', '68', '14,7', '15,4', '38', '16,7', '17,4', '20', '19,6', '20,6', '2'],
    ['13,5', '-', '67', '-', '15,5', '37', '16,9', '17,6', '19', '-', '-', '-'],
  ];
  final List<List<String>> tableData19 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['24,0', '25,0', '100', '-', '27,5', '75', '27,0', '30,0', '50', '-', '33,0', '25'],
    ['24,1', '25,1', '99', '26,2', '27,6', '74', '-', '30,1', '49', '-', '33,2', '24'],
    ['24,2', '25,2', '98', '-', '27,7', '73', '-', '30,2', '48', '27,9', '33,4', '23'],
    ['24,3', '25,3', '97', '-', '27,8', '72', '27,1', '30,3', '47', '28,0', '33,6', '22'],
    ['24,4', '25,4', '96', '26,3', '27,9', '71', '-', '30,4', '46', '28,4', '33,8', '21'],
    ['24,5', '25,5', '95', '-', '28,0', '70', '-', '30,5', '45', '28,8', '34,0', '20'],
    ['24,6', '25,6', '94', '-', '28,1', '69', '27,2', '30,6', '44', '29,2', '34,1', '19'],
    ['24,7', '25,7', '93', '26,4', '28,2', '68', '-', '30,7', '43', '29,6', '34,2', '18'],
    ['24,8', '25,8', '92', '-', '28,3', '67', '-', '30,8', '42', '30,0', '34,3', '17'],
    ['24,9', '25,9', '91', '-', '28,4', '66', '27,3', '30,9', '41', '30,4', '34,4', '16'],
    ['25,0', '26,0', '90', '26,5', '28,5', '65', '-', '31,0', '40', '30,8', '34,5', '15'],
    ['25,1', '26,1', '89', '-', '28,6', '64', '-', '31,1', '39', '31,2', '34,6', '14'],
    ['25,2', '26,2', '88', '-', '28,7', '63', '27,4', '31,2', '38', '31,6', '34,7', '13'],
    ['25,3', '26,3', '87', '26,6', '28,8', '62', '-', '31,3', '37', '32,0', '34,8', '12'],
    ['25,4', '26,4', '86', '-', '28,9', '61', '-', '31,4', '36', '32,4', '34,9', '11'],
    ['25,5', '26,5', '85', '-', '29,0', '60', '27,5', '31,5', '35', '32,8', '35,0', '10'],
    ['25,6', '26,6', '84', '26,7', '29,1', '59', '-', '31,6', '34', '33,2', '35,2', '9'],
    ['25,7', '26,7', '83', '-', '29,2', '58', '-', '31,7', '33', '33,6', '35,4', '8'],
    ['25,8', '26,8', '82', '-', '29,3', '57', '27,6', '31,8', '32', '33,7', '35,5', '7'],
    ['25,9', '26,9', '81', '26,8', '29,4', '56', '-', '31,9', '31', '33,8', '35,6', '6'],
    ['26,0', '27,0', '80', '-', '29,5', '55', '-', '32,0', '30', '33,9', '35,7', '5'],
    ['-', '27,1', '79', '-', '29,6', '54', '27,7', '32,2', '29', '34,0', '35,8', '4'],
    ['-', '27,2', '78', '26,9', '29,7', '53', '-', '32,4', '28', '34,1', '35,9', '3'],
    ['26,1', '27,3', '77', '-', '29,8', '52', '-', '32,6', '27', '34,2', '36,0', '2'],
    ['-', '27,4', '76', '-', '29,9', '51', '27,8', '32,8', '26', '-', '-', '-'],
  ];
  final List<List<String>> tableData23 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['1 мин 00 с', '1 мин 04 с', '100', '1 мин 17 с', '1 мин 21 с', '37', '1 мин 36 с', '1 мин 44 с', '16'],
    ['1 мин 01 с', '1 мин 05 с', '97', '1 мин 18 с', '1 мин 22 с', '35', '1 мин 38 с', '1 мин 46 с', '15'],
    ['1 мин 02 с', '1 мин 06 с', '93', '1 мин 19 с', '1 мин 23 с', '33', '1 мин 40 с', '1 мин 48 с', '14'],
    ['1 мин 03 с', '1 мин 07 с', '89', '1 мин 20 с', '1 мин 24 с', '31', '1 мин 42 с', '1 мин 50 с', '13'],
    ['1 мин 04 с', '1 мин 08 с', '83', '1 мин 21 с', '1 мин 25 с', '29', '1 мин 44 с', '1 мин 52 с', '12'],
    ['1 мин 05 с', '1 мин 09 с', '80', '1 мин 22 с', '1 мин 26 с', '28', '1 мин 46 с', '1 мин 54 с', '11'],
    ['1 мин 06 с', '1 мин 10 с', '76', '1 мин 23 с', '1 мин 27 с', '27', '1 мин 47 с', '1 мин 56 с', '10'],
    ['1 мин 07 с', '1 мин 11 с', '69', '1 мин 24 с', '1 мин 28 с', '26', '1 мин 48 с', '1 мин 58 с', '9'],
    ['1 мин 08 с', '1 мин 12 с', '64', '1 мин 25 с', '1 мин 29 с', '25', '1 мин 49 с', '2 мин 00 с', '8'],
    ['1 мин 09 с', '1 мин 13 с', '59', '1 мин 26 с', '1 мин 30 с', '24', '1 мин 50 с', '2 мин 02 с', '7'],
    ['1 мин 10 с', '1 мин 14 с', '55', '1 мин 27 с', '1 мин 31 с', '23', '1 мин 51 с', '2 мин 04 с', '6'],
    ['1 мин 11 с', '1 мин 15 с', '51', '1 мин 28 с', '1 мин 32 с', '22', '1 мин 52 с', '2 мин 06 с', '5'],
    ['1 мин 12 с', '1 мин 16 с', '48', '1 мин 29 с', '1 мин 33 с', '21', '1 мин 53 с', '2 мин 08 с', '4'],
    ['1 мин 13 с', '1 мин 17 с', '45', '1 мин 30 с', '1 мин 36 с', '20', '1 мин 54 с', '2 мин 10 с', '3'],
    ['1 мин 14 с', '1 мин 18 с', '43', '1 мин 31 с', '1 мин 38 с', '19', '1 мин 55 с', '2 мин 12 с', '2'],
    ['1 мин 15 с', '1 мин 19 с', '41', '1 мин 32 с', '1 мин 40 с', '18', '-', '-', '-'],
    ['1 мин 16 с', '1 мин 20 с', '39', '1 мин 34 с', '1 мин 42 с', '17', '-', '-', '-'],
  ];
  final List<List<String>> tableData24 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['3 мин 15 с', '3 мин 25 с', '100', '3 мин 41 с', '3 мин 53 с', '57', '4 мин 05 с', '4 мин 42 с', '29'],
    ['3 мин 16 с', '3 мин 26 с', '99', '-', '3 мин 54 с', '56', '4 мин 10 с', '4 мин 44 с', '28'],
    ['3 мин 17 с', '3 мин 27 с', '98', '3 мин 42 с', '3 мин 55 с', '55', '4 мин 15 с', '4 мин 46 с', '27'],
    ['3 мин 18 с', '3 мин 28 с', '97', '-', '3 мин 56 с', '54', '4 мин 20 с', '4 мин 48 с', '26'],
    ['3 мин 19 с', '3 мин 29 с', '96', '3 мин 43 с', '3 мин 57 с', '53', '4 мин 25 с', '4 мин 50 с', '25'],
    ['3 мин 20 с', '3 мин 30 с', '95', '-', '3 мин 58 с', '52', '4 мин 30 с', '4 мин 55 с', '24'],
    ['3 мин 21 с', '3 мин 31 с', '94', '3 мин 44 с', '3 мин 59 с', '51', '4 мин 35 с', '5 мин 00 с', '23'],
    ['3 мин 22 с', '3 мин 32 с', '93', '-', '4 мин 00 с', '50', '4 мин 40 с', '5 мин 05 с', '22'],
    ['3 мин 23 с', '3 мин 33 с', '92', '3 мин 45 с', '4 мин 02 с', '49', '4 мин 45 с', '5 мин 10 с', '21'],
    ['3 мин 24 с', '3 мин 34 с', '91', '-', '4 мин 04 с', '48', '4 мин 50 с', '5 мин 15 с', '20'],
    ['3 мин 25 с', '3 мин 35 с', '89', '3 мин 46 с', '4 мин 06 с', '47', '4 мин 55 с', '5 мин 20 с', '19'],
    ['3 мин 26 с', '3 мин 36 с', '87', '-', '4 мин 08 с', '46', '5 мин 00 с', '5 мин 25 с', '18'],
    ['3 мин 27 с', '3 мин 37 с', '85', '3 мин 47 с', '4 мин 10 с', '45', '5 мин 10 с', '5 мин 30 с', '17'],
    ['3 мин 28 с', '3 мин 38 с', '83', '-', '4 мин 12 с', '44', '5 мин 15 с', '5 мин 35 с', '16'],
    ['3 мин 29 с', '3 мин 39 с', '81', '3 мин 48 с', '4 мин 14 с', '43', '5 мин 20 с', '5 мин 40 с', '15'],
    ['3 мин 30 с', '3 мин 40 с', '79', '-', '4 мин 16 с', '42', '5 мин 25 с', '5 мин 45 с', '14'],
    ['3 мин 31 с', '3 мин 41 с', '77', '3 мин 49 с', '4 мин 18 с', '41', '5 мин 30 с', '5 мин 50 с', '13'],
    ['3 мин 32 с', '3 мин 42 с', '75', '3 мин 50 с', '4 мин 20 с', '40', '5 мин 35 с', '5 мин 55 с', '12'],
    ['3 мин 33 с', '3 мин 43 с', '73', '3 мин 51 с', '4 мин 22 с', '39', '5 мин 40 с', '6 мин 00 с', '11'],
    ['3 мин 34 с', '3 мин 44 с', '71', '3 мин 52 с', '4 мин 24 с', '38', '5 мин 45 с', '6 мин 05 с', '10'],
    ['3 мин 35 с', '3 мин 45 с', '69', '3 мин 53 с', '4 мин 26 с', '37', '5 мин 50 с', '6 мин 10 с', '9'],
    ['3 мин 36 с', '3 мин 46 с', '67', '3 мин 54 с', '4 мин 28 с', '36', '5 мин 55 с', '6 мин 15 с', '8'],
    ['3 мин 37 с', '3 мин 47 с', '65', '3 мин 55 с', '4 мин 30 с', '35', '6 мин 00 с', '6 мин 20 с', '7'],
    ['3 мин 38 с', '3 мин 48 с', '63', '3 мин 56 с', '4 мин 32 с', '34', '6 мин 05 с', '6 мин 25 с', '6'],
    ['3 мин 39 с', '3 мин 49 с', '61', '3 мин 57 с', '4 мин 34 с', '33', '6 мин 10 с', '6 мин 30 с', '5'],
    ['-', '3 мин 50 с', '60', '3 мин 58 с', '4 мин 36 с', '32', '6 мин 15 с', '6 мин 40 с', '4'],
    ['3 мин 40 с', '3 мин 51 с', '59', '3 мин 59 с', '4 мин 38 с', '31', '6 мин 20 с', '6 мин 50 с', '3'],
    ['-', '3 мин 52 с', '58', '4 мин 00 с', '4 мин 40 с', '30', '6 мин 25 с', '7 мин 00 с', '2'],
  ];
  final List<List<String>> tableData25 = [
    ['До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы', 'До 35 лет', '35 лет и старше', 'Баллы'],
    ['10 мин 30 с', '12 мин 00 с', '100', '12 мин 12 с', '13 мин 32 с', '67', '14 мин 24 с', '16 мин 10 с', '34'],
    ['10 мин 32 с', '12 мин 02 с', '99', '12 мин 16 с', '13 мин 36 с', '66', '14 мин 28 с', '16 мин 15 с', '33'],
    ['10 мин 34 с', '12 мин 04 с', '98', '12 мин 20 с', '13 мин 40 с', '65', '14 мин 32 с', '16 мин 20 с', '32'],
    ['10 мин 36 с', '12 мин 06 с', '97', '12 мин 24 с', '13 мин 44 с', '64', '14 мин 36 с', '16 мин 25 с', '31'],
    ['10 мин 38 с', '12 мин 08 с', '96', '12 мин 28 с', '13 мин 48 с', '63', '14 мин 40 с', '16 мин 30 с', '30'],
    ['10 мин 40 с', '12 мин 10 с', '95', '12 мин 32 с', '13 мин 52 с', '62', '14 мин 44 с', '16 мин 35 с', '29'],
    ['10 мин 42 с', '12 мин 12 с', '94', '12 мин 36 с', '13 мин 56 с', '61', '14 мин 48 с', '16 мин 40 с', '28'],
    ['10 мин 44 с', '12 мин 14 с', '93', '12 мин 40 с', '14 мин 00 с', '60', '14 мин 52 с', '16 мин 45 с', '27'],
    ['10 мин 46 с', '12 мин 16 с', '92', '12 мин 44 с', '14 мин 05 с', '59', '14 мин 56 с', '16 мин 50 с', '26'],
    ['10 мин 48 с', '12 мин 18 с', '91', '12 мин 48 с', '14 мин 10 с', '58', '15 мин 00 с', '16 мин 55 с', '25'],
    ['10 мин 50 с', '12 мин 20 с', '90', '12 мин 52 с', '14 мин 15 с', '57', '15 мин 04 с', '17 мин 00 с', '24'],
    ['10 мин 52 с', '12 мин 22 с', '89', '12 мин 56 с', '14 мин 20 с', '56', '15 мин 08 с', '17 мин 05 с', '23'],
    ['10 мин 54 с', '12 мин 24 с', '88', '13 мин 00 с', '14 мин 25 с', '55', '15 мин 12 с', '17 мин 10 с', '22'],
    ['10 мин 56 с', '12 мин 26 с', '87', '13 мин 04 с', '14 мин 30 с', '54', '15 мин 16 с', '17 мин 20 с', '21'],
    ['10 мин 58 с', '12 мин 28 с', '86', '13 мин 08 с', '14 мин 35 с', '53', '15 мин 20 с', '17 мин 30 с', '20'],
    ['11 мин 00 с', '12 мин 30 с', '85', '13 мин 12 с', '14 мин 40 с', '52', '15 мин 24 с', '17 мин 40 с', '19'],
    ['11 мин 04 с', '12 мин 32 с', '84', '13 мин 16 с', '14 мин 45 с', '51', '15 мин 28 с', '17 мин 50 с', '18'],
    ['11 мин 08 с', '12 мин 34 с', '83', '13 мин 20 с', '14 мин 50 с', '50', '15 мин 32 с', '18 мин 00 с', '17'],
    ['11 мин 12 с', '12 мин 36 с', '82', '13 мин 24 с', '14 мин 55 с', '49', '15 мин 36 с', '18 мин 10 с', '16'],
    ['11 мин 16 с', '12 мин 38 с', '81', '13 мин 28 с', '15 мин 00 с', '48', '15 мин 40 с', '18 мин 20 с', '15'],
    ['11 мин 20 с', '12 мин 40 с', '80', '13 мин 32 с', '15 мин 05 с', '47', '15 мин 44 с', '18 мин 30 с', '14'],
    ['11 мин 24 с', '12 мин 44 с', '79', '13 мин 36 с', '15 мин 10 с', '46', '15 мин 48 с', '18 мин 40 с', '13'],
    ['11 мин 28 с', '12 мин 48 с', '78', '13 мин 40 с', '15 мин 15 с', '45', '15 мин 52 с', '18 мин 50 с', '12'],
    ['11 мин 32 с', '12 мин 52 с', '77', '13 мин 44 с', '15 мин 20 с', '44', '15 мин 56 с', '19 мин 00 с', '11'],
    ['11 мин 36 с', '12 мин 56 с', '76', '13 мин 48 с', '15 мин 25 с', '43', '16 мин 00 с', '19 мин 10 с', '10'],
    ['11 мин 40 с', '13 мин 00 с', '75', '13 мин 52 с', '15 мин 30 с', '42', '16 мин 10 с', '19 мин 20 с', '9'],
    ['11 мин 44 с', '13 мин 04 с', '74', '13 мин 56 с', '15 мин 35 с', '41', '16 мин 20 с', '19 мин 30 с', '8'],
    ['11 мин 48 с', '13 мин 08 с', '73', '14 мин 00 с', '15 мин 40 с', '40', '16 мин 30 с', '19 мин 40 с', '7'],
    ['11 мин 52 с', '13 мин 12 с', '72', '14 мин 04 с', '15 мин 45 с', '39', '16 мин 35 с', '19 мин 50 с', '6'],
    ['11 мин 56 с', '13 мин 16 с', '71', '14 мин 08 с', '15 мин 50 с', '38', '16 мин 40 с', '20 мин 00 с', '5'],
    ['12 мин 00 с', '13 мин 20 с', '70', '14 мин 12 с', '15 мин 55 с', '37', '16 мин 45 с', '20 мин 10 с', '4'],
    ['12 мин 04 с', '13 мин 24 с', '69', '14 мин 16 с', '16 мин 00 с', '36', '16 мин 50 с', '20 мин 20 с', '3'],
    ['12 мин 08 с', '13 мин 28 с', '68', '14 мин 20 с', '16 мин 05 с', '35', '16 мин 55 с', '20 мин 30 с', '2'],
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentSection.startsWith('muscle')) {
      final number = int.tryParse(_currentSection.substring(6));
      final exercises = number == null ? null : _muscleExercises[number];

      if (number != null && exercises != null) {
        return _buildExerciseSection(
          groupNumber: number,
          exercises: exercises,
        );
      }
    }

    switch (_currentSection) {
      case 'main':
        return _buildMainContent();
      case 'warmup':
        return _buildWarmupSection();
      case 'physical':
        return _buildPhysicalSection();
      case 'grade':
        return _buildGradeSection();
      case 'results':
        return _buildResultsSection();
      case 'power':
        return _buildPowerCard();
      case 'speed':
        return _buildSpeedCard();
      case 'endurance':
        return _buildEnduranceCard();
      case 'muscle':
        return _buildMuscleCard();
      case 'u1':
        return _buildU1Section();
      case 'u2':
        return _buildU2Section();
      case 'u3':
        return _buildU3Section();
      case 'u17':
        return _buildU17Section();
      case 'u18':
        return _buildU18Section();
      case 'u19':
        return _buildU19Section();
      case 'u23':
        return _buildU23Section();
      case 'u24':
        return _buildU24Section();
      case 'u25':
        return _buildU25Section();
      default:
        return _buildMainContent();
    }
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Общие положения
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Общие положения наставления по физической подготовке в Вооруженных Силах Российской Федерации',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/images/image1.jpg',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Порядок организации физической подготовки военнослужащих Вооруженных Сил Российской Федерации и требования по уровню физической подготовки граждан Российской Федерации, поступающих на военную службу по контракту определяет наставление по физической подготовке в Вооруженных Силах Российской Федерации',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showSection('warmup'),
                    child: Text(
                      'Подробнее',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Теоретический и практический материал
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Теоретический и практический материал по физической подготовке',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/images/image7.jpg',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),

                  // Теория по силе
                  GestureDetector(
                    onTap: () => _showSection('power'),
                    child: Text(
                      'Теоретический материал по развитию физического качества "Сила"',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Теория по быстроте
                  GestureDetector(
                    onTap: () => _showSection('speed'),
                    child: Text(
                      'Теоретический материал по развитию физического качества "Быстрота"',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Теория по выносливости
                  GestureDetector(
                    onTap: () => _showSection('endurance'),
                    child: Text(
                      'Теоретический материал по развитию физического качества "Выносливость"',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Практический материал
                  GestureDetector(
                    onTap: () => _showSection('muscle'),
                    child: Text(
                      'Упражнения, направленные на развитие различных групп мышц',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Физические упражнения
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Физические упражнения для оценки уровня физической подготовленности военнослужащих',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/images/image2.jpg',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'В процессе физической подготовки применяются физические упражнения, направленные на развитие физических качеств у военнослужащих (силы, быстроты, выносливости, ловкости), а также на формирование и совершенствование военно-прикладных двигательных навыков (в ускоренном передвижении, преодолении препятствий, военно-прикладном плавании, рукопашном бое, выполнении специальных приемов и действий).',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showSection('physical'),
                    child: Text(
                      'Перечень физических упражнений',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Оценка
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оценка уровня физической подготовленности военнослужащих',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/images/image3.jpg',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Оценка и квалификационный уровень физической подготовленности военнослужащего определяются по сумме баллов, набранных им за выполнение физических упражнений, с учетом минимального количества баллов в каждом упражнении',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showSection('grade'),
                    child: Text(
                      'Таблица оценки уровня физической подготовленности военнослужащих',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //Мои результаты
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Мои результаты выполнения нормативов'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSection('results'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupSection() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Общие положения',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/image1.jpg',
                  height: 500,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Наставление по физической подготовке в Вооруженных Силах Российской Федерации определяет:\n\n'
                      'порядок организации физической подготовки военнослужащих Вооруженных Сил Российской Федерации, в том числе требования к уровню физической подготовленности военнослужащих;\n\n'
                      'требования по уровню физической подготовки граждан Российской Федерации (иностранных граждан), поступающих на военную службу по контракту.\n\n'
                      'Граждане, поступающие в военные профессиональные образовательные организации и военные образовательные организации высшего образования, должны соответствовать требованиям, установленным для граждан, поступающих на военную службу по контракту.\n\n'
                      'Физическая подготовка военнослужащих в Вооруженных Силах Российской Федерации направлена на развитие физических качеств, формирование военно-прикладных двигательных навыков военнослужащих с учетом их военно-профессиональной деятельности, пола, возраста.\n\n'
                      'Физическая подготовка проводится как в мирное, так и в военное время.\n\n'
                      'Основными элементами системы физической подготовки являются: цель, задачи, организация, объект, субъект, результат физической подготовки.\n\n'
                      'Целью физической подготовки является успешное выполнение военнослужащими своих служебных обязанностей.\n\n'
                      'Задачами физической подготовки являются: развитие физических качеств у военнослужащих; формирование и совершенствование у военнослужащих военно-прикладных двигательных навыков; получение теоретических знаний и формирование методических умений военнослужащих для проведения мероприятий физической подготовки.\n\n'
                      'Объектами физической подготовки являются военнослужащие, занимающиеся физической подготовкой.\n\n'
                      'Субъектами физической подготовки являются должностные лица, осуществляющие организацию и проведение физической подготовки с военнослужащими.\n\n'
                      'Результатом физической подготовки является достигнутый уровень физической подготовленности военнослужащих, который определяется степенью развития физических качеств, сформированности военно-прикладных двигательных навыков, а также достигнутый уровень теоретических знаний и методических умений.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => _showSection('main'),
                child: const Text('Назад'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _exerciseLink(String title, String section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showSection(section),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _exerciseGroup(String title, List<int> numbers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        for (final number in numbers)
          _exerciseLink('Упражнение № $number', 'u$number'),
      ],
    );
  }

  Widget _buildPhysicalSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Физические упражнения',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/image2.jpg',
                    height: 500,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                  _exerciseGroup(
                    'Физические упражнения, направленные на развитие физического качества "Сила":',
                    [1, 2, 3, /*4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16*/],
                  ),
                  _exerciseGroup(
                    'Физические упражнения, направленные на развитие физического качества "Быстрота":',
                    [17, 18, 19],
                  ),
                  _exerciseGroup(
                    'Физические упражнения, направленные на развитие физического качества "Выносливость":',
                    [23, 24, 25],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () => _showSection('main'),
              child: const Text('Назад'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Таблица оценки уровня физической подготовленности военнослужащих',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Image.asset(
            'assets/images/table.jpg',
            height: 1800,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _showSection('main'),
            child: Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (!_resultsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Результаты выполнения нормативов',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addResultRow,
              icon: const Icon(Icons.add),
              label: const Text('Добавить запись'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Дата')),
                    DataColumn(label: Text('Сила\n№ упражнения')),
                    DataColumn(label: Text('Сила\nРезультат')),
                    DataColumn(label: Text('Быстрота\n№ упражнения')),
                    DataColumn(label: Text('Быстрота\nРезультат')),
                    DataColumn(label: Text('Выносливость\n№ упражнения')),
                    DataColumn(label: Text('Выносливость\nРезультат')),
                    DataColumn(label: Text('Сумма баллов')),
                    DataColumn(label: Text('Квалификационный уровень')),
                    DataColumn(label: Text('')), // колонка удаления
                  ],
                  rows: List.generate(_resultRows.length, (rowIndex) {
                    final row = _resultRows[rowIndex];

                    return DataRow(
                      cells: [
                        // 1. Дата
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: row[0],
                              readOnly: true,
                              onTap: () => _selectResultDate(row[0]),
                              decoration: const InputDecoration(
                                hintText: 'Выберите дату',
                                suffixIcon: Icon(Icons.calendar_today),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),

                        // 2. Упражнение на силу: 1–16
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: _buildExerciseDropdown(
                              controller: row[1],
                              first: 1,
                              last: 16,
                            ),
                          ),
                        ),

                        // 3. Результат по силе
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: row[2],
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _saveResults();
                              },
                              decoration: const InputDecoration(
                                hintText: 'Баллы',
                                isDense: true,
                              ),
                            ),
                          ),
                        ),

                        // 4. Упражнение на быстроту: 17–22
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: _buildExerciseDropdown(
                              controller: row[3],
                              first: 17,
                              last: 22,
                            ),
                          ),
                        ),

                        // 5. Результат по быстроте
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: row[4],
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _saveResults();
                              },
                              decoration: const InputDecoration(
                                hintText: 'Баллы',
                                isDense: true,
                              ),
                            ),
                          ),
                        ),

                        // 6. Упражнение на выносливость: 23–29
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: _buildExerciseDropdown(
                              controller: row[5],
                              first: 23,
                              last: 29,
                            ),
                          ),
                        ),

                        // 7. Результат по выносливости
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: row[6],
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _saveResults();
                              },
                              decoration: const InputDecoration(
                                hintText: 'Баллы',
                                isDense: true,
                              ),
                            ),
                          ),
                        ),

                        // 8. Сумма результатов из колонок 3, 5 и 7
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: Text(
                              _calculateRowSum(row),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // 9. Квалификационный уровень
                        DataCell(
                          SizedBox(
                            width: 160,
                            child: Text(
                              _qualificationLevel(
                                double.tryParse(_calculateRowSum(row))?.round() ?? 0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Удаление строки
                        DataCell(
                          IconButton(
                            tooltip: 'Удалить запись',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                for (final controller in row) {
                                  controller.dispose();
                                }
                                _resultRows.removeAt(rowIndex);
                              });
                              _saveResults();
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _showSection('main'),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerCard() {
    return FutureBuilder<String>(
      future: _powerText,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          //debugPrint('Ошибка загрузки asset: ${snapshot.error}');
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Не удалось загрузить assets/txt/power.txt'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Теоретический материал по развитию физического качества "Сила"',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showSection('main'),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedCard() {
    return FutureBuilder<String>(
      future: _speedText,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          //debugPrint('Ошибка загрузки asset: ${snapshot.error}');
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Не удалось загрузить assets/txt/speed.txt'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Теоретический материал по развитию физического качества "Быстрота"',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showSection('main'),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnduranceCard() {
    return FutureBuilder<String>(
      future: _enduranceText,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          //debugPrint('Ошибка загрузки asset: ${snapshot.error}');
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Не удалось загрузить assets/txt/endurance.txt'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Теоретический материал по развитию физического качества "Выносливость"',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showSection('main'),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMuscleCard() {
    final sections = [
      'muscle1', 'muscle2', 'muscle3',
      'muscle4', 'muscle5', 'muscle6',
      'muscle7', 'muscle8', 'muscle9',
      'muscle10', 'muscle11', 'muscle12',
    ];
    final labels = [
      'Трапециевидная мышца', 'Дельтовидные мышцы', 'Грудные мышцы',
      'Бицепс', 'Трицепс', 'Широчайшие мышцы спины',
      'Косые мышцы живота', 'Прямая мышца живота', 'Длинные мышцы спины',
      'Квадрицепс', 'Бицепс бедра', 'Икроножные мышцы',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => InkWell(
                onTap: () => _showSection(sections[index]),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/images/muscle${index + 1}.jpg',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: Colors.black12,
                              child: Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () => _showSection('main'),
              child: const Text('Назад'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDescription(String description) {
    final lines = description.split('\n');
    final muscleHeaderIndex =
    lines.indexWhere((line) => line.trim() == 'Задействованные мышцы:');

    final title = lines.isNotEmpty ? lines.first : '';
    final instructionEnd = muscleHeaderIndex == -1
        ? lines.length
        : muscleHeaderIndex;

    final instructions = lines
        .skip(1)
        .take(instructionEnd - 1)
        .join('\n');

    final muscles = muscleHeaderIndex == -1
        ? ''
        : lines.skip(muscleHeaderIndex).join('\n');

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(
            text: '$title\n',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (instructions.trim().isNotEmpty)
            TextSpan(text: '$instructions\n'),
          if (muscles.isNotEmpty)
            TextSpan(
              text: muscles,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  final Map<int, List<String>> _muscleExercises = {
    1: [
      //Упражнение 1-1
      'Тяга гантели в наклоне\n\n'
          '1. Встань, поставив стопы на ширине таза, и возьми по гантели нейтральным хватом.\n'
          '2. Согни колени и отведи таз назад, сохраняя позвоночник в нейтральном положении.\n'
          '3. Свободно опусти обе руки под плечи и напряги пресс перед тягой.\n'
          '4. На выдохе потяни обе гантели к бокам, отводя локти назад.\n'
          '5. Под контролем опусти обе гантели, пока руки не выпрямятся под плечами.\n'
          '6. Повторяй движение обеими руками одновременно и плавно, не ускоряя темп намеренно.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 15%\n'
          'Широчайшие - 40%\n'
          'Трапеции - 20%\n'
          'Бицепсы - 20%\n'
          'Предплечья - 5%',

      //Упражнение 1-2
      'Тяга гантели одной рукой в наклоне на скамье\n\n'
          '1. Упрись нерабочей рукой и коленом в плоскую скамью, устойчивый стул или край стола.\n'
          '2. Поставь стопу со стороны рабочей руки на пол, выпрями спину и расположи корпус примерно параллельно полу.\n'
          '3. Держи гантель под рабочим плечом, направив ладонь внутрь.\n'
          '4. Потяни гантель к боку, пока локоть не окажется немного позади корпуса.\n'
          '5. Под контролем опусти гантель до полного выпрямления рабочей руки.\n'
          '6. Выполни заданное количество повторений одной рукой, затем поменяй сторону опоры и рабочую руку.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 15%\n'
          'Широчайшие - 45%\n'
          'Трапеции - 20%\n'
          'Бицепсы - 15%\n'
          'Предплечья - 5%',

      //Упражнение 1-3
      'Тяга сидя в блоке\n\n'
          '1. Установи нужный вес и прикрепи рукоять для тяги узким хватом к нижнему блоку.\n'
          '2. Сядь лицом к блоку, поставь стопы на упоры и слегка согни колени.\n'
          '3. Возьмись за рукоять ладонями друг к другу, выпрями спину и расправь руки.\n'
          '4. Отведи оба локтя назад вдоль корпуса, подтягивая рукоять к животу.\n'
          '5. Медленно выпрями руки, позволяя лопаткам плавно уйти вперёд, но не округляй спину.\n'
          '6. Выполни заданное количество повторений, сохраняя корпус неподвижным во время каждой тяги.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 10%\n'
          'Широчайшие - 45%\n'
          'Трапеции - 25%\n'
          'Бицепсы - 15%\n'
          'Предплечья - 5%',

      //Упражнение 1-4
      'Тяга в тренажере сидя\n\n'
          '1. Установи вес и высоту сиденья так, чтобы валик поддерживал середину груди.\n'
          '2. Сядь прямо, прижавшись грудью к упору, и поставь обе стопы на платформы тренажёра.\n'
          '3. Возьмись за горизонтальные рукояти хватом сверху, полностью выпрямив руки.\n'
          '4. Одновременно потяни обе рукояти к корпусу, отводя локти назад.\n'
          '5. Медленно верни рукояти, пока руки не выпрямятся, не отрывая грудь от упора.\n'
          '6. Выполни заданное число повторений, двигая обеими руками одновременно.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 20%\n'
          'Широчайшие - 35%\n'
          'Трапеции - 25%\n'
          'Бицепсы - 15%\n'
          'Предплечья - 5%',

      //Упражнение 1-5
      'Тяга штанги в наклоне\n\n'
          '1. Возьмитесь за гриф прямым хватом чуть шире ног, поставив стопы на ширине тазобедренных суставов.\n'
          '2. Слегка согните колени и отведите таз назад, сохраняя спину в нейтральном положении.\n'
          '3. Напрягите пресс и свободно опустите обе руки под плечами.\n'
          '4. Выдохните и отведите оба локтя назад, подтягивая гриф к животу.\n'
          '5. Под контролем опустите гриф до полного выпрямления локтей, не поднимая корпус.\n'
          '6. Выполните заданное количество повторений, сохраняя устойчивое положение в наклоне.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 15%\n'
          'Широчайшие - 40%\n'
          'Трапеции - 25%\n'
          'Бицепсы - 15%\n'
          'Предплечья - 5%',
    ],
    2: [
      //Упражнение 2-2
      'Жим Арнольда с гантелями сидя\n\n'
          '1. Сядь на вертикальное сиденье или стул со спинкой, поставь стопы на пол.\n'
          '2. Прижми спину к спинке и держи обе гантели перед плечами.\n'
          '3. Поверни ладони к себе, согнув локти и расположив их под гантелями.\n'
          '4. Одновременно выжми обе гантели вверх, разводя локти и поворачивая ладони вперёд.\n'
          '5. Медленно опусти обе гантели, выполняя вращение в обратную сторону, пока ладони снова не окажутся обращены к тебе на уровне плеч.\n'
          '6. Выполни заданное количество повторений, всё время сохраняя спину прижатой к опоре.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 70%\n'
          'Пресс - 5%\n'
          'Трицепсы - 25%',

      //Упражнение 2-3
      'Подъём гантелей через стороны перед собой\n\n'
          '1. Встань, поставив стопы на ширину таза, и держи две гантели по бокам ладонями внутрь.\n'
          '2. На протяжении всего движения слегка сгибай руки в локтях.\n'
          '3. Подними обе руки через стороны примерно до уровня плеч.\n'
          '4. На этой высоте плавно переведи обе руки вперёд, пока кисти не окажутся на одной линии с плечами.\n'
          '5. Медленно опусти обе гантели перед бёдрами.\n'
          '6. Верни руки к бокам и повтори всю последовательность.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 80%\n'
          'Грудь - 10%\n'
          'Пресс - 10%',

      //Упражнение 2-4
      'Подъем гантелей перед собой\n\n'
          '1. Встаньте прямо, поставив стопы на ширине таза, и возьмите по гантели в каждую руку.\n'
          '2. Держите гантели перед бёдрами, направив ладони внутрь и слегка согнув локти.\n'
          '3. Поднимайте обе руки вперёд одновременно, пока кисти не окажутся примерно на уровне плеч.\n'
          '4. Медленно опускайте обе гантели к бёдрам, сохраняя тот же небольшой сгиб в локтях.\n'
          '5. Выполните заданное количество повторений, удерживая корпус вертикально.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 80%\n'
          'Грудь - 15%\n'
          'Предплечья - 5%',

      //Упражнение 2-5
      'Отжимания "Щука"\n\n'
          '1. Поставь ладони на ширине плеч, а передние части стоп на ширине таза.\n'
          '2. Высоко подними таз, оставляя ноги почти прямыми, а пятки приподнятыми.\n'
          '3. Одновременно согни локти и опускай голову к полу немного перед ладонями.\n'
          '4. На выдохе оттолкнись обеими ладонями и выпрями руки.\n'
          '5. Повторяй движение, удерживая таз высоко и не касаясь головой пола.\n\n'
          'Задействованные мышцы:\n'
          'Плечи - 55%\n'
          'Грудь - 25%\n'
          'Пресс - 5%\n'
          'Трицепсы - 15%',
    ],
    3: [
      //Упражнение 3-1
      'Жим штанги лежа\n\n'
          '1. Лягте на горизонтальную скамью, опираясь головой, спиной и тазом; стопы поставьте на пол.\n'
          '2. Возьмитесь за гриф прямым хватом, расположив руки шире плеч.\n'
          '3. Сведите лопатки и удерживайте гриф над грудью на выпрямленных руках.\n'
          '4. Вдохните и медленно опустите гриф к середине груди.\n'
          '5. Выдохните и одновременно выжмите гриф обеими руками до полного выпрямления локтей.\n'
          '6. Выполните заданное количество повторений, контролируя каждую фазу опускания и жима.\n\n'
          'Задействованные мышцы:\n'
          'Грудь - 65%\n'
          'Плечи - 15%\n'
          'Трицепсы - 20%',

      //Упражнение3-2
      'Разведение гантелей лежа\n\n'
          '1. Лягте спиной на горизонтальную скамью, поставив обе стопы на пол.\n'
          '2. Прижмите голову и спину к скамье. Держите две гантели над грудью, направив ладони друг к другу.\n'
          '3. Слегка согнув локти, опускайте обе гантели в стороны по широкой дуге.\n'
          '4. Остановитесь, когда плечи окажутся на уровне корпуса, или раньше, если почувствуете напряжение в плечах.\n'
          '5. Сведите обе гантели над грудью по той же дуге, выдыхая при подъёме.\n'
          '6. Выполните заданное количество повторений, сохраняя одинаковый сгиб в локтях.\n\n'
          'Задействованные мышцы:\n'
          'Грудь - 80%\n'
          'Бицепсы - 5%\n'
          'Плечи - 15%',

      //Упражнение 3-3
      'Разведение рук в тренажере "Бабочка"\n\n'
          '1. Отрегулируй сиденье так, чтобы локти находились немного ниже уровня плеч.\n'
          '2. Сядь, прижав спину к спинке, и поставь стопы на пол.\n'
          '3. Прижми вертикальные предплечья к мягким упорам и возьмись за верхние рукояти.\n'
          '4. Сведи обе мягкие подушки перед грудью, сохраняя локти согнутыми.\n'
          '5. Медленно разведи руки, пока не почувствуешь комфортное растяжение груди.\n'
          '6. Выполни заданное количество повторений, двигая обеими руками одновременно.\n\n'
          'Задействованные мышцы:\n'
          'Грудь - 85%\n'
          'Плечи - 15%',
    ],
    4: [
      //Упражнение 4-1
      'Сгибание рук с гантелями на концентрацию\n\n'
          '1. Сядь на горизонтальную скамью или устойчивый стул, поставь стопы на пол и разведи ноги.\n'
          '2. Наклонись вперёд, прижав рабочую руку к внутренней стороне бедра, а противоположную руку положи на другое бедро.\n'
          '3. Возьми гантель нижним хватом; рабочая рука почти выпрямлена, ладонь смотрит вперёд.\n'
          '4. Подними гантель к плечу, не отрывая плечо от бедра.\n'
          '5. Медленно опусти гантель, почти полностью выпрямив локоть.\n'
          '6. Выполни заданное количество повторений этой рукой, затем смени сторону.\n\n'
          'Задействованные мышцы:\n'
          'Бицепсы - 85%\n'
          'Предплечья - 15%',

      //Упражнение4-2
      'Сгибание рук на бицепс на скамье Скотта\n\n'
          '1. Отрегулируй сиденье так, чтобы обе плечевые части рук полностью лежали на наклонной подушке.\n'
          '2. Сядь, поставь стопы на пол и возьмись за обе рукояти нижним хватом.\n'
          '3. Согни руки, приближая обе рукояти к плечам, не отрывая плечевые части рук от подушки.\n'
          '4. Медленно опусти рукояти почти до полного выпрямления локтей, не форсируя нижнюю точку.\n'
          '5. Повтори заданное количество раз, двигая обеими руками одновременно.\n\n'
          'Задействованные мышцы:\n'
          'Бицепсы - 85%\n'
          'Предплечья - 15%',

      //Упражнение 4-3
      'Подъем штанги на бицепс\n\n'
          '1. Встань, поставив стопы на ширине тазобедренных суставов, и возьми прямую штангу хватом снизу на ширине плеч.\n'
          '2. Начни с грифа у бёдер, расположив плечи вдоль корпуса.\n'
          '3. Одновременно согни оба локтя и подними штангу, не выводя плечи вперёд.\n'
          '4. Остановись, когда выше поднять штангу уже нельзя без подъёма локтей.\n'
          '5. Опусти штангу к бёдрам до полного выпрямления локтей и повтори движение.\n\n'
          'Задействованные мышцы:\n'
          'Бицепсы - 85%\n'
          'Предплечья - 15%',
    ],
    5: [
      //Упражнение 5-1
      'Отжимание троса вниз (прямой гриф)\n\n'
          '1. Прикрепи прямой гриф к верхнему блоку и выбери рабочий вес.\n'
          '2. Встань лицом к тренажёру и возьмись за гриф хватом сверху, расположив руки примерно на ширине плеч.\n'
          '3. Поставь стопы на ширине таза и слегка наклони корпус вперёд.\n'
          '4. Прижми плечи к корпусу и начни с согнутыми локтями.\n'
          '5. Одновременно разогни оба локтя, опуская гриф, не двигая плечами.\n'
          '6. Медленно согни локти, вернувшись в исходное положение, затем повтори заданное количество раз.\n\n'
          'Задействованные мышцы:\n'
          'Трицепсы - 100%',

      //Упражнение 5-2
      'Разгибание рук с гантелями сидя\n\n'
          '1. Сядьте прямо на скамью или устойчивый стул, поставив обе стопы на пол.\n'
          '2. Охватите обеими руками один конец гантели и надёжно зафиксируйте хват.\n'
          '3. Поднимите гантель над головой, выпрямив руки и расположив плечи рядом с ушами.\n'
          '4. Одновременно согните локти и опустите гантель за голову в комфортной амплитуде.\n'
          '5. Выпрямите локти и поднимите гантель над головой, не двигая плечами.\n'
          '6. Выполните запланированное количество повторений, медленно и подконтрольно опуская гантель.\n\n'
          'Задействованные мышцы:\n'
          'Трицепсы - 100%',

      //Упражнение 5-3
      'Французский жим со штангой "Сколл Крашер"\n\n'
          '1. Лягте на спину на горизонтальную скамью и поставьте стопы на пол.\n'
          '2. Удерживайте штангу над плечами на прямых руках хватом сверху, расположив руки на ширине плеч.\n'
          '3. Удерживая плечи неподвижными, одновременно согните оба локтя.\n'
          '4. Подконтрольно опустите штангу ко лбу, остановив её до касаниям.\n'
          '5. Выпрямите оба локтя и верните штангу над плечи, затем повторите.\n\n'
          'Задействованные мышцы:\n'
          'Трицепсы - 90%\n'
          'Плечи - 5%\n'
          'Грудь - 5%',
    ],
    6: [
      //Упражнение 6-1
      'Тяга верхнего блока к груди\n\n'
          '1. Установи вес на блоке до того, как сядешь на ровную скамью или устойчивый стул.\n'
          '2. Сядь лицом к тренажёру, поставь стопы на пол и возьми гриф хватом сверху чуть шире плеч.\n'
          '3. Держи корпус прямо, слегка отклонившись назад, а руки выпрями над головой.\n'
          '4. На выдохе одновременно потяни оба локтя вниз, направляя гриф к верхней части груди.\n'
          '5. Медленно позволь грифу подняться, пока руки не выпрямятся, не отрываясь от сиденья.\n'
          '6. Выполни заданное количество повторений, сохраняя корпус неподвижным.\n\n'
          'Задействованные мышцы:\n'
          'Широчайшие - 55%\n'
          'Бицепсы - 20%\n'
          'Предплечья - 5%\n'
          'Плечи - 10%\n'
          'Трапеция - 10%',

      //Упражнение 6-2
      'Тяга гантели в наклоне\n\n'
          '1. Встань, поставив стопы на ширине таза, и возьми по гантели нейтральным хватом.\n'
          '2. Согни колени и отведи таз назад, сохраняя позвоночник в нейтральном положении.\n'
          '3. Свободно опусти обе руки под плечи и напряги пресс перед тягой.\n'
          '4. На выдохе потяни обе гантели к бокам, отводя локти назад.\n'
          '5. Под контролем опусти обе гантели, пока руки не выпрямятся под плечами.\n'
          '6. Повторяй движение обеими руками одновременно и плавно, не ускоряя темп намеренно.\n\n'
          'Задействованные мышцы:\n'
          'Широчайшие - 40%\n'
          'Плечи - 15%\n'
          'Трапеция - 20%\n'
          'Бицепсы - 20%\n'
          'Предплечья - 5%',

      //Упражнение 6-3
      'Подтягивание\n\n'
          '1. Возьмись за перекладину для подтягиваний хватом сверху, расположив руки немного шире плеч.\n'
          '2. Повисни на прямых руках, не касаясь стопами пола.\n'
          '3. На выдохе подтягивайся обеими руками, пока подбородок не окажется выше перекладины.\n'
          '4. Под контролем опусти тело до полного выпрямления локтей.\n'
          '5. Сделай нужное число повторений, не касаясь стопами пола.\n\n'
          'Задействованные мышцы:\n'
          'Широчайшие - 55%\n'
          'Бицепсы - 20%\n'
          'Предплечья - 5%\n'
          'Плечи - 10%\n'
          'Трапеция - 10%',
    ],
    7: [
      //Упражнение 7-1
      'Боковая планка\n\n'
          '1. Ляг на бок на полу, выпрями ноги и положи стопы одну на другую.\n'
          '2. Поставь нижний локоть под плечом, опираясь предплечьем на пол.\n'
          '3. Подними таз, чтобы голова, таз и лодыжки образовали прямую линию.\n'
          '4. Удерживай положение заданное время и ровно дыши.\n'
          '5. Подконтрольно опусти таз, затем смени сторону и повтори удержание.\n\n'
          'Задействованные мышцы:\n'
          'Пресс - 60%\n'
          'Ягодицы - 30%\n'
          'Квадрицепсы - 10%',
    ],
    8: [
      //Упражнение 8-1
      'Обратные скручивания\n\n'
          '1. Ляг на спину, положи руки вдоль корпуса, а ладони на пол.\n'
          '2. Подними обе стопы, согнув колени, и расположи колени над тазом.\n'
          '3. На выдохе подкрути таз к рёбрам, пока копчик не оторвётся от пола.\n'
          '4. Медленно опусти таз на пол, сохраняя колени согнутыми.\n'
          '5. Повторяй движение обеими ногами вместе, всё время удерживая стопы поднятыми.\n\n'
          'Задействованные мышцы:\n'
          'Пресс - 100%',
    ],
    9: [
      //Упражнение 9-1
      'Румынская тяга со штангой\n\n'
          '1. Встань, поставив стопы на ширине таза, и удерживай штангу у бёдер хватом сверху.\n'
          '2. Слегка согни колени и напряги живот перед началом опускания.\n'
          '3. Отведи таз назад, держи штангу близко к ногам и сохраняй спину нейтральной.\n'
          '4. Опускай штангу к голеням только настолько, насколько можешь отвести таз назад.\n'
          '5. На выдохе надави обеими стопами в пол и подай таз вперёд, выпрямляясь.\n'
          '6. Встань прямо, не отклоняясь назад, и повтори с тем же лёгким сгибанием коленей.\n\n'
          'Задействованные мышцы:\n'
          'Широчайшие - 10%\n'
          'Ягодицы - 35%\n'
          'Квадрицепсы - 5%\n'
          'Бицепсы бедра - 45%\n'
          'Икры - 5%',
    ],
    10: [
      //Упражнение 10-1
      'Гоблет-приседание с гантелью\n\n'
          '1. Возьми верхний конец вертикальной гантели обеими руками и держи её у груди.\n'
          '2. Поставь стопы примерно на ширине плеч, слегка разверни носки наружу и прижми пятки к полу.\n'
          '3. Напряги живот, затем согни колени и тазобедренные суставы, опускаясь между ног.\n'
          '4. Опустись примерно до параллели бёдер с полом или на комфортную для тебя глубину.\n'
          '5. На выдохе оттолкнись обеими стопами и выпрями ноги, вставая.\n'
          '6. Восстанови дыхание, удерживая гантель у груди, затем повтори.\n\n'
          'Задействованные мышцы:\n'
          'Квадрицепсы - 50%\n'
          'Ягодицы - 45%\n'
          'Икры - 5%',
    ],
    11: [
      //Упражнение 11-1
      'Махи гирей\n\n'
          '1. Встань, поставив стопы на ширине плеч, и положи гирю немного перед собой.\n'
          '2. Отведи таз назад, слегка согни колени и сохрани нейтральное положение позвоночника, взявшись за рукоять сверху обеими руками.\n'
          '3. Наклони гирю к себе и протолкни её высоко между бёдрами.\n'
          '4. Резко подай таз вперёд и на выдохе направь гирю до уровня груди, сохраняя руки длинными.\n'
          '5. Позволь гире опуститься и снова отведи таз назад, направляя её высоко между бёдрами.\n'
          '6. Сделай нужное количество повторений, затем отведи таз назад и поставь гирю на пол.\n\n'
          'Задействованные мышцы:\n'
          'Бицепсы бедра - 35%\n'
          'Ягодицы - 40%\n'
          'Плечи - 5%\n'
          'Квадрицепсы - 5%\n'
          'Пресс - 10%\n'
          'Икры - 5%',
    ],
    12: [
      //Упражнение 12-1
      'Подъём на носки с гантелями стоя на ступеньке\n\n'
          '1. Встань на устойчивую ступеньку, лестницу или невысокую тумбу, взяв по гантели в каждую руку.\n'
          '2. Поставь передние части обеих стоп на край, оставив пятки без опоры.\n'
          '3. Выпрями корпус, держи колени почти прямыми, руки опусти по сторонам, ладони направь к бёдрам.\n'
          '4. Оттолкнись передними частями стоп и подними обе пятки вместе настолько высоко, насколько комфортно.\n'
          '5. Медленно опусти обе пятки ниже края, пока не почувствуешь комфортную растяжку икроножных мышц.\n'
          '6. Выполни заданное количество повторений, считая одновременный подъём пяток за одно повторение.\n\n'
          'Задействованные мышцы:\n'
          'Икры - 100%',
    ],
  };

  Widget _buildExerciseSection({
    required int groupNumber,
    required List<String> exercises,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset(
                        'assets/images/ex$groupNumber-${index + 1}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildExerciseDescription(exercises[index]),
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _showSection('muscle'),
                child: const Text('Назад'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormSection({
    required int number,
    required String title,
    required String image,
    required String description,
    required List<List<String>> table,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Упражнение №$number. $title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  image,
                  height: 500,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text(
                  'Таблица перевода результата выполнения упражнения '
                      '№$number в баллы',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTable(table),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => _showSection('physical'),
                child: const Text('Назад'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildU1Section() => _buildNormSection(
    number: 1,
    title: 'Сгибание и разгибание рук в упоре лежа',
    image: 'assets/images/image2.jpg',
    description: 'Упор лежа (руки и тело прямые, ноги вместе), согнуть руки до касания грудью пола (или технического приспособления высотой не более 5 см), разгибая руки, принять упор лежа.\n\n'
        'Положение упора лежа фиксировать не менее 1 секунды (продолжить движение после объявления счета).\n\n'
        'Разводить ноги, сгибание тела и ног, отдых в положении упора лежа на согнутых руках не допускается.\n\n'
        'Упражнение выполняется в спортивной форме одежды по команде «К выполнению упражнения ПРИСТУПИТЬ».\n\n'
        'При нарушении условий выполнения упражнения повторение не засчитывается, подается команда «НЕ СЧИТАТЬ».',
    table: tableData1,
  );

  Widget _buildU2Section() => _buildNormSection(
    number: 2,
    title: 'Наклон туловища вперед',
    image: 'assets/images/image4.jpg',
    description: 'Лежа на спине с согнутыми ногами (руки за голову, пальцы в «замок», ноги согнуты, ступни прижаты к полу, лопатки касаются пола), наклонить туловище вперед до касания локтями коленей и возвратиться в положение лежа на спине с согнутыми ногами (продолжить движение после объявления счета).\n\n'
        'Упражнение выполняется в течение одной минуты.\n\n'
        'Разрешается фиксировать ноги за голеностопы руками партнера.\n\n'
        'Отрыв ступней от опорной поверхности (пола) не допускается.\n\n'
        'Упражнение выполняется в спортивной форме одежды по команде «К выполнению упражнения ПРИСТУПИТЬ».\n\n'
        'При нарушении условий выполнения упражнения повторение не засчитывается, подается команда «НЕ СЧИТАТЬ».',
    table: tableData2,
  );

  Widget _buildU3Section() => _buildNormSection(
    number: 3,
    title: 'Подтягивание на перекладине',
    image: 'assets/images/image5.jpg',
    description: 'Вис на перекладине (хват сверху, руки и тело прямые, ноги вместе, положение тела неподвижное), сгибая руки, подтянуться (подбородок выше грифа перекладины), разгибая руки, опуститься в вис.\n\n'
        'Положение виса фиксируется не менее 1 секунды (продолжить движение после объявления счета).\n\n'
        'Разрешается разводить ноги до ширины плеч и незначительно сгибать в тазобедренных и коленных суставах.\n\n'
        'Выполнение упражнения рывком и махом не допускается.\n\n'
        'Упражнение выполняется в спортивной форме одежды по команде "К СНАРЯДУ".\n\n'
        'При нарушении условий выполнения упражнения, повторение не засчитывается, подается команда "НЕ СЧИТАТЬ".',
    table: tableData3,
  );

  Widget _buildU17Section() => _buildNormSection(
    number: 17,
    title: 'Бег на 60 м',
    image: 'assets/images/image6.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды с высокого старта по беговой дорожке стадиона или ровной площадке с любым пригодным покрытием. По команде "НА СТАРТ" подойти к стартовой линии, поставить одну ногу вперед, не наступая на линию, другую отставить назад. По команде "ВНИМАНИЕ" принять неподвижное положение старта. По команде "МАРШ!" начать бег.\n\n'
        'Пересечение соседней дорожки, создание помехи другому военнослужащему, начало бега раньше команды "МАРШ!" (фальстарт) не допускаются.\n\n'
        'При нарушении условий выполнения упражнений предоставляется вторая попытка, при повторном нарушении упражнение считается невыполненным.',
    table: tableData17,
  );

  Widget _buildU18Section() => _buildNormSection(
    number: 18,
    title: 'Бег га 100 м',
    image: 'assets/images/image7.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды с высокого старта по беговой дорожке стадиона или ровной площадке с любым пригодным покрытием. По команде "НА СТАРТ" подойти к стартовой линии, поставить одну ногу вперед, не наступая на линию, другую отставить назад. По команде "ВНИМАНИЕ" принять неподвижное положение старта. По команде "МАРШ!" начать бег.\n\n'
        'Пересечение соседней дорожки, создание помехи другому военнослужащему, начало бега раньше команды "МАРШ!" (фальстарт) не допускаются.\n\n'
        'При нарушении условий выполнения упражнений предоставляется вторая попытка, при повторном нарушении упражнение считается невыполненным.',
    table: tableData18,
  );

  Widget _buildU19Section() => _buildNormSection(
    number: 19,
    title: 'Челночный бег 10 x 10 м',
    image: 'assets/images/image8.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды на ровной площадке с размеченными линиями старта и поворота. Ширина линии старта и поворота входит в отрезок 10 м. По команде "НА СТАРТ" подойти к стартовой линии, поставить одну ногу вперед, не наступая на линию, другую отставить назад. По команде "ВНИМАНИЕ" принять неподвижное положение старта. По команде "МАРШ" пробежать 10 м, заступить за линию поворота ногой, развернутся, пробежать девять отрезков.\n\n'
        'Пересечение соседней дорожки, создание помехи другому военнослужащему, начало бега раньше команды "МАРШ!" (фальстарт), использование в качестве опоры при старте, развороте, каких-либо естественных и искусственных предметов, неровностей, выступающих над поверхностью дорожки, не допускаются.\n\n'
        'При нарушении условий выполнения упражнения предоставляется вторая попытка, при повторном нарушении норматив считается невыполненным.',
    table: tableData19,
  );

  Widget _buildU23Section() => _buildNormSection(
    number: 23,
    title: 'Бег на 400 м',
    image: 'assets/images/image9.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды с высокого старта по беговой дорожке стадиона или ровной площадке с любым пригодным покрытием. По команде "НА СТАРТ" подойти к стартовой линии, поставить одну ногу вперед, не наступая на линию, другую отставить назад. По команде "ВНИМАНИЕ" принять неподвижное положение старта. По команде "МАРШ!" начать бег.\n\n'
        'Создание помех другому военнослужащему, начало бега раньше команды "МАРШ!" (фальстарт) не допускаются.',
    table: tableData23,
  );

  Widget _buildU24Section() => _buildNormSection(
    number: 24,
    title: 'Бег на 1 км',
    image: 'assets/images/image10.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды на беговой дорожке стадиона или ровной дороге вне стадиона с общего старта, по команде "НА СТАРТ" подойти к стартовой линии, по команде "МАРШ" начать бег. \n\n'
        'Старт и финиш, как правило, оборудуются в одном месте. При выполнении упражнений на беговой дорожке стадиона старт и финиш производится в соответствии с разметкой стадиона.',
    table: tableData24,
  );

  Widget _buildU25Section() => _buildNormSection(
    number: 25,
    title: 'Бег на 3 км',
    image: 'assets/images/image11.jpg',
    description: 'Упражнение выполняется в спортивной форме одежды на беговой дорожке стадиона или ровной дороге вне стадиона с общего старта, по команде "НА СТАРТ" подойти к стартовой линии, по команде "МАРШ" начать бег. \n\n'
        'Старт и финиш, как правило, оборудуются в одном месте. При выполнении упражнений на беговой дорожке стадиона старт и финиш производится в соответствии с разметкой стадиона.',
    table: tableData25,
  );

  Widget _buildTable(List<List<String>> data) {
    return Table(
      border: TableBorder.all(color: Colors.black),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final row in data)
          TableRow(
            children: [
              for (final cell in row)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(cell, textAlign: TextAlign.center),
                ),
            ],
          ),
      ],
    );
  }
}