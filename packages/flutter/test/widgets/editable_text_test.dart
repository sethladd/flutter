// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'semantics_tester.dart';

void main() {
  final TextEditingController controller = new TextEditingController();
  final FocusNode focusNode = new FocusNode();
  final FocusScopeNode focusScopeNode = new FocusScopeNode();
  final TextStyle textStyle = const TextStyle();
  final Color cursorColor = const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  testWidgets('has expected defaults', (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        )));

    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.maxLines, equals(1));
    expect(editableText.obscureText, isFalse);
    expect(editableText.autocorrect, isTrue);
  });

  testWidgets('text keyboard is requested when maxLines is default',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: new EditableText(
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ))));
    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.maxLines, equals(1));
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType'],
        equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.done'));
  });

  testWidgets('multiline keyboard is requested when set explicitly',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: new EditableText(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              style: textStyle,
              cursorColor: cursorColor,
            ))));

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType'], equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs['inputAction'], equals('TextInputAction.newline'));
  });

  testWidgets('Correct keyboard is requested when set explicitly and maxLines > 1',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: new EditableText(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              maxLines: 3,
              style: textStyle,
              cursorColor: cursorColor,
            ))));

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType'], equals('TextInputType.phone'));
    expect(tester.testTextInput.setClientArgs['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('multiline keyboard is requested when set implicitly',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: new EditableText(
              controller: controller,
              focusNode: focusNode,
              maxLines: 3, // Sets multiline keyboard implicitly.
              style: textStyle,
              cursorColor: cursorColor,
            ))));

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType'], equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs['inputAction'], equals('TextInputAction.newline'));
  });

  testWidgets('single line inputs have correct default keyboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: new EditableText(
              controller: controller,
              focusNode: focusNode,
              maxLines: 1, // Sets text keyboard implicitly.
              style: textStyle,
              cursorColor: cursorColor,
            ))));

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType'], equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('Fires onChanged when text changes via TextSelectionOverlay', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey = new GlobalKey<EditableTextState>();

    String changedValue;
    final Widget widget = new MaterialApp(
      home: new EditableText(
        key: editableTextKey,
        controller: new TextEditingController(),
        focusNode: new FocusNode(),
        style: new Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onChanged: (String value) {
          changedValue = value;
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = 'Dobunezumi mitai ni utsukushiku naritai';
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{ 'text': clipboardContent };
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    await tester.pump();

    await tester.tap(find.text('PASTE'));
    await tester.pump();

    expect(changedValue, clipboardContent);
  });

  testWidgets('Changing controller updates EditableText', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey = new GlobalKey<EditableTextState>();
    final TextEditingController controller1 = new TextEditingController(text: 'Wibble');
    final TextEditingController controller2 = new TextEditingController(text: 'Wobble');
    TextEditingController currentController = controller1;
    StateSetter setState;

    Widget builder() {
      return new StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return new Directionality(
            textDirection: TextDirection.ltr,
            child: new Center(
              child: new Material(
                child: new EditableText(
                  key: editableTextKey,
                  controller: currentController,
                  focusNode: new FocusNode(),
                  style: new Typography(platform: TargetPlatform.android).black.subhead,
                  cursorColor: Colors.blue,
                  selectionControls: materialTextSelectionControls,
                  keyboardType: TextInputType.text,
                  onChanged: (String value) { },
                ),
              ),
            ),
          );
        },
      );
    }
    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(EditableText));

    // Verify TextInput.setEditingState is fired with updated text when controller is replaced.
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) {
      log.add(methodCall);
    });
    setState(() {
      currentController = controller2;
    });
    await tester.pump();

    expect(log, hasLength(1));
    expect(log.single, isMethodCall(
          'TextInput.setEditingState',
          arguments: const <String, dynamic>{
            'text': 'Wobble',
            'selectionBase': -1,
            'selectionExtent': -1,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': -1,
            'composingExtent': -1,
          },
    ));
  });

  testWidgets('EditableText identifies as text field (w/ focus) in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: new EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(flags: <SemanticsFlags>[SemanticsFlags.isTextField]));

    await tester.tap(find.byType(EditableText));
    await tester.idle();
    await tester.pump();

    expect(semantics, includesNodeWith(flags: <SemanticsFlags>[SemanticsFlags.isTextField, SemanticsFlags.isFocused]));
  });

  testWidgets('EditableText includes text as value in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    const String value1 = 'EditableText content';

    controller.text = value1;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new FocusScope(
          node: focusScopeNode,
          child: new EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlags>[SemanticsFlags.isTextField],
      value: value1,
    ));

    const String value2 = 'Changed the EditableText content';
    controller.text = value2;
    await tester.idle();
    await tester.pump();

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlags>[SemanticsFlags.isTextField],
      value: value2,
    ));
  });

  testWidgets('changing selection with keyboard does not show handles', (WidgetTester tester) async {
    const String value1 = 'Hello World';

    controller.text = value1;

    await tester.pumpWidget(new MaterialApp(
      home: new EditableText(
        controller: controller,
        selectionControls: materialTextSelectionControls,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    // Simulate selection change via tap to show handles.
    final RenderEditable render = tester.allRenderObjects.firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    render.onSelectionChanged(const TextSelection.collapsed(offset: 4), render, SelectionChangedCause.tap);

    await tester.pumpAndSettle();
    final EditableTextState textState = tester.state(find.byType(EditableText));

    expect(textState.selectionOverlay.handlesAreVisible, isTrue);
    expect(textState.selectionOverlay.textEditingValue.selection, const TextSelection.collapsed(offset: 4));

    // Simulate selection change via keyboard and expect handles to disappear.
    render.onSelectionChanged(const TextSelection.collapsed(offset: 10), render, SelectionChangedCause.keyboard);
    await tester.pumpAndSettle();

    expect(textState.selectionOverlay.handlesAreVisible, isFalse);
    expect(textState.selectionOverlay.textEditingValue.selection, const TextSelection.collapsed(offset: 10));
  });

  testWidgets('exposes correct cursor movement semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    controller.text = 'test';

    await tester.pumpWidget(new MaterialApp(
      home: new EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(semantics, includesNodeWith(
      value: 'test',
    ));

    controller.selection = new TextSelection.collapsed(offset: controller.text.length);
    await tester.pumpAndSettle();

    // At end, can only go backwards.
    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorBackwardByCharacter,
      ],
    ));

    controller.selection = new TextSelection.collapsed(offset: controller.text.length - 2);
    await tester.pumpAndSettle();

    // Somewhere in the middle, can go in both directions.
    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorBackwardByCharacter,
        SemanticsAction.moveCursorForwardByCharacter,
      ],
    ));

    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pumpAndSettle();

    // At beginning, can only go forward.
    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorForwardByCharacter,
      ],
    ));

    semantics.dispose();
  });

  testWidgets('can move cursor with a11y means', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    controller.text = 'test';
    controller.selection = new TextSelection.collapsed(offset: controller.text.length);

    await tester.pumpWidget(new MaterialApp(
      home: new EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorBackwardByCharacter,
      ],
    ));

    final RenderEditable render = tester.allRenderObjects.firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    final int semanticsId = render.debugSemantics.id;

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 4);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId, SemanticsAction.moveCursorBackwardByCharacter);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 3);
    expect(controller.selection.extentOffset, 3);

    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorBackwardByCharacter,
        SemanticsAction.moveCursorForwardByCharacter,
      ],
    ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId, SemanticsAction.moveCursorBackwardByCharacter);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId, SemanticsAction.moveCursorBackwardByCharacter);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId, SemanticsAction.moveCursorBackwardByCharacter);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 0);

    await tester.pumpAndSettle();
    expect(semantics, includesNodeWith(
      value: 'test',
      actions: <SemanticsAction>[
        SemanticsAction.moveCursorForwardByCharacter,
      ],
    ));

    semantics.dispose();
  });
}
