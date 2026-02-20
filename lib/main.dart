import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TerminalScreen(),
    );
  }
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal terminal;
  late final TerminalController controller;

  final List<String> _history = [];
  int _historyIndex = -1;

  String _buffer = '';
  int _cursor = 0;

  bool _ctrl = false;
  bool _alt = false;
  bool _shift = false;

  @override
  void initState() {
    super.initState();

    terminal = Terminal(maxLines: 10000);
    controller = TerminalController();

    terminal.write('Xconn Mobile Terminal\r\n');
    _prompt();

    terminal.onOutput = _handleInput;
  }

  // ================= PROMPT =================

  void _prompt() {
    terminal.write('asim@mobile:~ ');
  }

  // ================= INPUT =================

  void _handleInput(String data) {
    // CTRL+C
    if (_ctrl && data.toLowerCase() == 'c') {
      terminal.write('^C\r\n');
      _resetLine();
      _prompt();
      _resetMods();
      return;
    }

    // ENTER
    if (data == '\r') {
      terminal.write('\r\n');

      if (_buffer.isNotEmpty) {
        _history.add(_buffer);
        terminal.write('command not found: $_buffer\r\n');
      }

      _resetLine();
      _prompt();
      return;
    }

    // BACKSPACE
    if (data == '\x7f') {
      if (_cursor > 0) {
        _buffer = _buffer.substring(0, _cursor - 1) +
            _buffer.substring(_cursor);
        _cursor--;
        _redrawLine();
      }
      return;
    }

    // ARROWS (history)
    if (data == '\x1b[A') {
      _historyUp();
      return;
    }
    if (data == '\x1b[B') {
      _historyDown();
      return;
    }

    // LEFT / RIGHT
    if (data == '\x1b[D') {
      if (_cursor > 0) {
        terminal.write('\x1b[D');
        _cursor--;
      }
      return;
    }
    if (data == '\x1b[C') {
      if (_cursor < _buffer.length) {
        terminal.write('\x1b[C');
        _cursor++;
      }
      return;
    }

    // NORMAL CHAR
    _buffer =
        _buffer.substring(0, _cursor) + data + _buffer.substring(_cursor);
    _cursor++;
    _redrawLine();
  }

  // ================= LINE MGMT =================

  void _resetLine() {
    _buffer = '';
    _cursor = 0;
    _historyIndex = _history.length;
  }

  void _redrawLine() {
    terminal.write('\r');
    _prompt();
    terminal.write(_buffer);

    // move cursor back if needed
    final back = _buffer.length - _cursor;
    if (back > 0) {
      terminal.write('\x1b[${back}D');
    }
  }

  // ================= HISTORY =================

  void _historyUp() {
    if (_history.isEmpty) return;
    if (_historyIndex > 0) _historyIndex--;

    _buffer = _history[_historyIndex];
    _cursor = _buffer.length;
    _redrawLine();
  }

  void _historyDown() {
    if (_history.isEmpty) return;
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _buffer = _history[_historyIndex];
    } else {
      _resetLine();
    }
    _cursor = _buffer.length;
    _redrawLine();
  }

  // ================= MODIFIERS =================

  void _resetMods() {
    setState(() {
      _ctrl = _alt = _shift = false;
    });
  }

  void _sendKey(TerminalKey key) {
    terminal.keyInput(key, ctrl: _ctrl, alt: _alt, shift: _shift);
    if (_ctrl || _alt) _resetMods();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TerminalView(
                terminal,
                controller: controller,
                autofocus: true,
              ),
            ),

            // ===== MODIFIERS =====
            _bar([
              _toggle('Ctrl', _ctrl, () => setState(() => _ctrl = !_ctrl)),
              _toggle('Alt', _alt, () => setState(() => _alt = !_alt)),
              _toggle('Shift', _shift, () => setState(() => _shift = !_shift)),
              _key('Esc', () => _sendKey(TerminalKey.escape)),
              _key('Tab', () => _sendKey(TerminalKey.tab)),
            ]),

            // ===== NAV =====
            _bar([
              _key('Home', () => _sendKey(TerminalKey.home)),
              _key('End', () => _sendKey(TerminalKey.end)),
              _key('↑', () => _sendKey(TerminalKey.arrowUp)),
              _key('↓', () => _sendKey(TerminalKey.arrowDown)),
              _key('←', () => _sendKey(TerminalKey.arrowLeft)),
              _key('→', () => _sendKey(TerminalKey.arrowRight)),
              _key('Del', () => _sendKey(TerminalKey.delete)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _bar(List<Widget> children) => Container(
    color: const Color(0xFF1A1A1A),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    ),
  );

  Widget _key(String t, VoidCallback f) => _btn(t, Colors.grey[800]!, f);

  Widget _toggle(String t, bool a, VoidCallback f) =>
      _btn(t, a ? Colors.blue : Colors.grey[800]!, f);

  Widget _btn(String t, Color c, VoidCallback f) => Material(
    color: c,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(t, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
}
