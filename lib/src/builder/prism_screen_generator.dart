import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/prism_screen.dart';

Builder prismScreenSharedPartBuilder() =>
    SharedPartBuilder([_PrismScreenGenerator()], 'prism_router');

class _PrismScreenGenerator extends GeneratorForAnnotation<PrismScreen> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@PrismScreen can only be applied to classes.',
        element: element,
      );
    }

    final widgetName = element.displayName;
    final pageName = annotation.read('name').stringValue;
    final tags = _readTags(annotation);
    final path = annotation.peek('path')?.literalValue as String?;
    final isInitial =
        annotation.peek('initial')?.literalValue as bool? ?? false;

    final constructor = _resolveConstructor(element);
    final params = constructor?.parameters ?? <ParameterElement>[];
    final pageClassName = '_\$${widgetName}PrismPage';

    final fields = params
        .where((p) => !_isKeyParameter(p))
        .map(
          (p) =>
              '  final ${p.type.getDisplayString(withNullability: true)} ${p.name};',
        )
        .join('\n');

    final ctorSignature = _constructorSignature(params);
    final widgetArgs = _widgetInvocation(params);
    final argumentMap = _argumentsMap(params);
    final pageBuilderFromArgs = _pageBuilderFromArgs(pageClassName, params);
    final fromWidget = _fromWidget(pageClassName, params);
    final defaultPage = _defaultPage(pageClassName, params);

    return '''
class $pageClassName extends PrismPage {
  const $pageClassName($ctorSignature)
      : ${_fieldInitializers(params)}
        super(
          name: '$pageName',
          tags: ${_tagsLiteral(tags)},
          child: $widgetName($widgetArgs),
          arguments: $argumentMap,
          key: key,
        );

$fields

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) =>
      $pageClassName(${_constructorFromArguments(params)});
}

// Registers $widgetName with the PrismScreenRegistry.
final _\$${widgetName}PrismRegistration = PrismScreenRegistry.register<$widgetName>(
  PrismGeneratedScreen<$widgetName>(
    name: '$pageName',
    tags: ${_tagsLiteral(tags)},
    path: ${path == null ? 'null' : "'$path'"},
    initial: $isInitial,
    pageBuilder: $pageBuilderFromArgs,
    fromWidget: $fromWidget,
    defaultPage: $defaultPage,
  ),
);
''';
  }

  ConstructorElement? _resolveConstructor(ClassElement element) {
    if (element.constructors.isEmpty) return null;
    return element.unnamedConstructor ?? element.constructors.first;
  }

  bool _isKeyParameter(ParameterElement element) =>
      element.name == 'key' &&
      element.type.getDisplayString(withNullability: false) == 'Key';

  String _constructorSignature(List<ParameterElement> params) {
    final positional = params.where((p) => p.isPositional).toList();
    final named = params.where((p) => p.isNamed).toList();
    final hasKey = params.any(_isKeyParameter);

    final buffer = StringBuffer();
    if (positional.isNotEmpty) {
      buffer.write(
        positional
            .map((p) {
              final type = p.type.getDisplayString(withNullability: true);
              return '$type ${p.name}';
            })
            .join(', '),
      );
    }
    if (named.isNotEmpty || !hasKey) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('{');
      if (named.isNotEmpty) {
        buffer.write(
          named
              .map((p) {
                final type = p.type.getDisplayString(withNullability: true);
                final requiredKeyword = p.isRequired ? 'required ' : '';
                final defaultValue =
                    p.defaultValueCode != null
                        ? ' = ${p.defaultValueCode}'
                        : '';
                return '$requiredKeyword$type ${p.name}$defaultValue';
              })
              .join(', '),
        );
      }
      if (!hasKey) {
        if (named.isNotEmpty) buffer.write(', ');
        buffer.write('Key? key');
      }
      buffer.write('}');
    }

    if (buffer.isEmpty) {
      return '{Key? key}';
    }
    return buffer.toString();
  }

  String _widgetInvocation(List<ParameterElement> params) {
    final positional = params.where((p) => p.isPositional).toList();
    final named = params.where((p) => p.isNamed).toList();
    final hasKey = params.any(_isKeyParameter);

    if (params.isEmpty) return '';
    final buffer = StringBuffer();
    if (positional.isNotEmpty) {
      buffer.write(positional.map((p) => p.name).join(', '));
      if (named.isNotEmpty) buffer.write(', ');
    }
    if (named.isNotEmpty) {
      buffer.write(named.map((p) => '${p.name}: ${p.name}').join(', '));
    }
    if (hasKey) {
      if (named.isEmpty) {
        if (positional.isNotEmpty) buffer.write(', ');
        buffer.write('key: key');
      } else {
        buffer.write(', key: key');
      }
    }
    return buffer.toString();
  }

  String _argumentsMap(List<ParameterElement> params) {
    final filtered = params.where((p) => !_isKeyParameter(p)).toList();
    if (filtered.isEmpty) return 'const <String, Object?>{}';
    final entries = filtered.map((p) => "'${p.name}': ${p.name}").join(', ');
    return '<String, Object?>{$entries}';
  }

  String _fieldInitializers(List<ParameterElement> params) {
    final filtered = params.where((p) => !_isKeyParameter(p)).toList();
    if (filtered.isEmpty) return '';
    return filtered.map((p) => '${p.name} = ${p.name}').join(', ') + ',';
  }

  String _constructorFromArguments(List<ParameterElement> params) {
    if (params.isEmpty) return '';
    final positional = params.where((p) => p.isPositional).toList();
    final named = params.where((p) => p.isNamed).toList();
    final args = <String>[];
    for (final p in positional) {
      args.add(_argumentRead(p));
    }
    if (named.isNotEmpty) {
      args.add('{${named.map((p) => _argumentPair(p)).join(', ')}}');
    }
    return args.join(', ');
  }

  String _argumentRead(ParameterElement param) {
    final value = _argumentValue(param);
    return value;
  }

  String _argumentPair(ParameterElement param) =>
      '${param.name}: ${_argumentValue(param)}';

  String _argumentValue(ParameterElement param) {
    final name = param.name;
    final type = param.type;
    final defaultValue = param.defaultValueCode;
    final typeStr = type.getDisplayString(withNullability: true);
    final base = "arguments['$name']";
    final fallback =
        defaultValue ?? (_isNullable(type) ? 'null' : _fallbackFor(type));
    if (param.isRequired && defaultValue == null && !_isNullable(type)) {
      return '$base as $typeStr';
    }
    return '($base as $typeStr?) ?? $fallback';
  }

  bool _isNullable(DartType type) =>
      type.nullabilitySuffix != NullabilitySuffix.none;

  String _fallbackFor(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    switch (typeName) {
      case 'String':
        return "''";
      case 'int':
      case 'double':
      case 'num':
        return '0';
      case 'bool':
        return 'false';
      default:
        return 'null';
    }
  }

  String _pageBuilderFromArgs(
    String pageClass,
    List<ParameterElement> params,
  ) => '(arguments) => $pageClass(${_constructorFromArguments(params)})';

  String _fromWidget(String pageClass, List<ParameterElement> params) {
    final positional = params.where((p) => p.isPositional).toList();
    final named = params.where((p) => p.isNamed).toList();
    final hasKey = params.any(_isKeyParameter);
    final buffer = StringBuffer();
    for (final p in positional) {
      buffer.write('screen.${p.name}, ');
    }
    if (named.isNotEmpty) {
      buffer.write('{');
      final namedEntries = named
          .map((p) => '${p.name}: screen.${p.name}')
          .join(', ');
      buffer.write(namedEntries);
      if (!hasKey) {
        if (named.isNotEmpty) buffer.write(', ');
        buffer.write('key: screen.key');
      }
      buffer.write('}');
    } else {
      buffer.write('{key: screen.key}');
    }
    final args = buffer.toString().trim();
    return '(screen) => $pageClass($args)';
  }

  String _defaultPage(String pageClass, List<ParameterElement> params) {
    final hasRequired = params.any(
      (p) => p.isRequired && p.defaultValueCode == null && !_isKeyParameter(p),
    );
    if (hasRequired) return 'null';
    return '() => $pageClass()';
  }

  Set<String>? _readTags(ConstantReader annotation) {
    final field = annotation.peek('tags');
    if (field == null || field.isNull) return null;
    final list =
        field.listValue.map((e) => e.toStringValue()).whereType<String>();
    final tags = list.where((e) => e.isNotEmpty).toSet();
    return tags.isEmpty ? null : tags;
  }

  String _tagsLiteral(Set<String>? tags) {
    if (tags == null) return 'null';
    final items = tags.map((t) => "'$t'").join(', ');
    return '{${items.isEmpty ? '' : items}}';
  }
}
