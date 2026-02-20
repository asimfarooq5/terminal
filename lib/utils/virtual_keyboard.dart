import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class VirtualKeyboardView extends StatelessWidget {
  const VirtualKeyboardView(this.keyboard, {super.key});

  final VirtualKeyboard keyboard;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboard,
      builder: (context, child) => ToggleButtons(
        children: const [Text('Ctrl'), Text('Alt'), Text('Shift')],
        isSelected: [keyboard.ctrl, keyboard.alt, keyboard.shift],
        onPressed: (index) {
          switch (index) {
            case 0:
              keyboard.ctrl = !keyboard.ctrl;
              break;
            case 1:
              keyboard.alt = !keyboard.alt;
              break;
            case 2:
              keyboard.shift = !keyboard.shift;
              break;
          }
        },
      ),
    );
  }
}

class VirtualKeyboard extends ChangeNotifier {
  bool _ctrl = false;
  bool _shift = false;
  bool _alt = false;

  bool get ctrl => _ctrl;
  bool get shift => _shift;
  bool get alt => _alt;

  set ctrl(bool value) {
    if (_ctrl != value) {
      _ctrl = value;
      notifyListeners();
    }
  }

  set shift(bool value) {
    if (_shift != value) {
      _shift = value;
      notifyListeners();
    }
  }

  set alt(bool value) {
    if (_alt != value) {
      _alt = value;
      notifyListeners();
    }
  }
}