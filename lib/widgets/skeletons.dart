import 'package:flutter/material.dart';

class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonContainer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });
  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final shine = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: [base, shine, base],
          ),
        ),
      ),
    );
  }
}
class DashboardSkeleton extends StatelessWidget {  const DashboardSkeleton({super.key});  @override  Widget build(BuildContext context) {    return Padding(      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Row(            children: [              const Expanded(child: SkeletonContainer(height: 36)),              const SizedBox(width: 12),              const SkeletonContainer(width: 42, height: 42, borderRadius: 21),            ],          ),          const SizedBox(height: 24),          Row(            children: List.generate(4, (_) {              return const Expanded(                child: Padding(                  padding: EdgeInsets.symmetric(horizontal: 4),                  child: SkeletonContainer(height: 100, borderRadius: 12),                ),              );            }),          ),          const SizedBox(height: 24),          const SkeletonContainer(height: 30, width: 200),          const SizedBox(height: 12),          ...List.generate(5, (_) {            return const Padding(              padding: EdgeInsets.only(bottom: 8),              child: SkeletonContainer(height: 56, borderRadius: 8),            );          }),        ],      ),    );  }}
class InventorySkeleton extends StatelessWidget {  const InventorySkeleton({super.key});  @override  Widget build(BuildContext context) {    return Padding(      padding: const EdgeInsets.all(18),      child: Column(        children: [          Row(            children: [              const Expanded(child: SkeletonContainer(height: 44)),              const SizedBox(width: 12),              const SkeletonContainer(width: 120, height: 44),              const SizedBox(width: 8),              const SkeletonContainer(width: 44, height: 44),            ],          ),          const SizedBox(height: 24),          ...List.generate(8, (_) {            return const Padding(              padding: EdgeInsets.only(bottom: 6),              child: Row(                children: [                  Expanded(flex: 3, child: SkeletonContainer(height: 40)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 40)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 40)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 40)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 40)),                  SizedBox(width: 8),                  Expanded(flex: 2, child: SkeletonContainer(height: 40)),                ],              ),            );          }),        ],      ),    );  }}
class ReportsSkeleton extends StatelessWidget {  const ReportsSkeleton({super.key});  @override  Widget build(BuildContext context) {    return Padding(      padding: const EdgeInsets.all(18),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Row(            children: [              const SkeletonContainer(width: 120, height: 36),              SizedBox(width: 12),              SkeletonContainer(width: 120, height: 36),              const Spacer(),              const SkeletonContainer(width: 100, height: 36),            ],          ),          const SizedBox(height: 16),          Row(            children: List.generate(4, (_) {              return const Expanded(                child: Padding(                  padding: EdgeInsets.symmetric(horizontal: 4),                  child: SkeletonContainer(height: 90, borderRadius: 12),                ),              );            }),          ),          const SizedBox(height: 20),          const Row(            children: [              Expanded(child: SkeletonContainer(height: 200)),              SizedBox(width: 16),              Expanded(child: SkeletonContainer(height: 200)),            ],          ),          const SizedBox(height: 20),          ...List.generate(3, (_) {            return const Padding(              padding: EdgeInsets.only(bottom: 6),              child: Row(                children: [                  Expanded(flex: 2, child: SkeletonContainer(height: 32)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 32)),                  SizedBox(width: 8),                  Expanded(flex: 1, child: SkeletonContainer(height: 32)),                ],              ),            );          }),        ],      ),    );  }}