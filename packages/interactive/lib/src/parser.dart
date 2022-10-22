// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:interactive/src/workspace_code.dart';

class InputParser {
  static void parseAndApply(String rawCode, WorkspaceCode target) {
    final compilationUnit = _tryParse(
        rawCode, (parser, token) => parser.parseCompilationUnit(token));
    if (compilationUnit != null) {
      for (final declaration
          in compilationUnit.declarations.whereType<ClassDeclaration>()) {
        final name = declaration.declaredElement!.name;
        target.classCodeOfNameMap[name] = declaration.getCode(rawCode);
      }

      return;
    }

    // consider as raw code
    target.generatedMethodCodeBlock = rawCode;
  }
}

typedef ParserClosure<T extends AstNode> = T Function(
    Parser parser, Token token);

// ref: https://github.com/BlackHC/dart_repl/blob/ad568604f41be31fbc8d809d5e0cfa25a6cd5601/lib/src/cell_type.dart#L18
T? _tryParse<T extends AstNode>(String code, ParserClosure<T> parse) {
  final reader = CharSequenceReader(code);
  final errorListener = _LoggingErrorListener();
  final featureSet = FeatureSet.latestLanguageVersion();
  final scanner = Scanner(StringSource(code, ''), reader, errorListener)
    ..configureFeatures(
        featureSetForOverriding: featureSet, featureSet: featureSet);
  final token = scanner.tokenize();
  final parser = Parser(StringSource(code, ''), errorListener,
      featureSet: featureSet, lineInfo: LineInfo.fromContent(code));

  final result = parse(parser, token);

  if (errorListener.errorReported ||
      result.endToken.next?.type != TokenType.EOF) {
    return null;
  }

  return result;
}

// TODO change to gather it etc
class _LoggingErrorListener extends BooleanErrorListener {
  @override
  void onError(AnalysisError error) {
    super.onError(error);
    print('Error when parsing: $error');
  }
}

extension on AstNode {
  String getCode(String fullCode) =>
      fullCode.substring(offset, offset + length);
}
