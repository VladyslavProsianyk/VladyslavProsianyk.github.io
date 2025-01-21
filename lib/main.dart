import 'dart:ui';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                // constraints: const BoxConstraints(minWidth: 48),
                // height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(
                  child: Icon(e, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();
  late int? _hoveredIndex;
  late double _baseTranslationY;

  @override
  void initState() {
    super.initState();
    _hoveredIndex = null;
    _baseTranslationY = 0.0;
  }

  double _getItemScale(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: 1,
      maxValue: 1.5,
      nonHoveredMaxValue: 1.2,
    );
  }

  double _getTranslationY(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: _baseTranslationY,
      maxValue: -22,
      nonHoveredMaxValue: -14,
    );
  }

  double _getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    if (_hoveredIndex == null) {
      return baseValue;
    }

    final difference = (_hoveredIndex! - index).abs();
    final itemsAffected = _items.length;

    if (difference == 0) {
      propertyValue = maxValue;
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;
    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        padding: const EdgeInsets.all(4),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.all(8),
          itemCount: _items.length,
          proxyDecorator: (child, index, _) {
            final itemSize = 48 * _getItemScale(index);
            return Align(
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 300,
                ),
                transform: Matrix4.identity()
                  ..translate(
                    0.0,
                    _getTranslationY(index),
                    0.0,
                  ),
                alignment: AlignmentDirectional.center,
                height: itemSize,
                width: itemSize,
                child: widget.builder(
                  _items[index],
                ),
              ),
            );
          },
          itemBuilder: (context, index) {
            return ReorderableDragStartListener(
              key: ValueKey(_items[index]),
              index: index,
              child: AnimatedItem(
                itemSize:  48 * _getItemScale(index),
                translationY: _getTranslationY(index),
                onHoverEnter: () => _onHoverEnter(index),
                onHoverExit: () => _onHoverExit(),
                child: widget.builder(
                  _items[index],
                ),
              ),
            );
          },
          buildDefaultDragHandles: false,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex--;
              }

              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
              _hoveredIndex = newIndex;
            });
          },
        ),
      ),
    );
  }

  void _onHoverExit() {
    setState(() {
      _hoveredIndex = null;
    });
  }

  void _onHoverEnter(int index) {
    setState(() {
      _hoveredIndex = index;
    });
  }
}

class AnimatedItem extends StatelessWidget {
  const AnimatedItem({
    super.key,
    required this.itemSize,
    required this.translationY,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.child,
  });

  final double itemSize;
  final double translationY;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: MouseRegion(
        onExit: (_) => onHoverExit(),
        onEnter: (_) => onHoverEnter(),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 300,
          ),
          transform: Matrix4.identity()
            ..translate(
              0.0,
              translationY,
              0.0,
            ),
          alignment: AlignmentDirectional.center,
          margin: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          height: itemSize,
          width: itemSize,
          child: child,
        ),
      ),
    );
  }
}