import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/glass_morphism.dart';
import '../layout/performance_mode_manager.dart';

/// Visual switcher for performance modes with glassmorphic design
class PerformanceModeSwitcher extends StatefulWidget {
  final bool showLabels;
  final bool expandedView;
  final VoidCallback? onModeChanged;

  const PerformanceModeSwitcher({
    Key? key,
    this.showLabels = true,
    this.expandedView = false,
    this.onModeChanged,
  }) : super(key: key);

  @override
  State<PerformanceModeSwitcher> createState() => _PerformanceModeSwitcherState();
}

class _PerformanceModeSwitcherState extends State<PerformanceModeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PerformanceModeManager>(
      builder: (context, modeManager, child) {
        if (widget.expandedView) {
          return _buildExpandedView(context, modeManager);
        } else {
          return _buildCompactView(context, modeManager);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, PerformanceModeManager modeManager) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 280 : 60,
        height: 60,
        child: Stack(
          children: [
            // Glass background
            Positioned.fill(
              child: GlassMorphism(
                blur: 20,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _getModeColor(modeManager.currentMode).withOpacity(0.3),
                  width: 1.5,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        _getModeColor(modeManager.currentMode).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isExpanded
                  ? _buildExpandedContent(modeManager)
                  : _buildCollapsedContent(modeManager),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(PerformanceModeManager modeManager) {
    return Center(
      child: Icon(
        _getModeIcon(modeManager.currentMode),
        color: _getModeColor(modeManager.currentMode),
        size: 28,
      ),
    );
  }

  Widget _buildExpandedContent(PerformanceModeManager modeManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: PerformanceMode.values.map((mode) {
          final isSelected = mode == modeManager.currentMode;
          return _buildModeButton(
            mode: mode,
            isSelected: isSelected,
            onTap: () {
              modeManager.setMode(mode);
              widget.onModeChanged?.call();
              _toggleExpanded();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeButton({
    required PerformanceMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? _getModeColor(mode).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? _getModeColor(mode).withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            _getModeIcon(mode),
            color: isSelected
                ? _getModeColor(mode)
                : Colors.white.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView(BuildContext context, PerformanceModeManager modeManager) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Mode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: PerformanceMode.values.length,
            itemBuilder: (context, index) {
              final mode = PerformanceMode.values[index];
              final isSelected = mode == modeManager.currentMode;
              
              return _buildExpandedModeCard(
                mode: mode,
                isSelected: isSelected,
                onTap: () {
                  modeManager.setMode(mode);
                  widget.onModeChanged?.call();
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Info text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _getModeDescription(modeManager.currentMode),
              key: ValueKey(modeManager.currentMode),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getModeColor(modeManager.currentMode).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedModeCard({
    required PerformanceMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            // Glass background
            Positioned.fill(
              child: GlassMorphism(
                blur: 15,
                opacity: isSelected ? 0.15 : 0.05,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getModeColor(mode).withOpacity(isSelected ? 0.5 : 0.2),
                  width: 1.5,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [
                              _getModeColor(mode).withOpacity(0.2),
                              Colors.transparent,
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getModeIcon(mode),
                    color: isSelected
                        ? _getModeColor(mode)
                        : Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getModeName(mode),
                      style: TextStyle(
                        color: isSelected
                            ? _getModeColor(mode)
                            : Colors.white.withOpacity(0.7),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: _getModeColor(mode),
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return Icons.tune;
      case PerformanceMode.performance:
        return Icons.speed;
      case PerformanceMode.minimal:
        return Icons.remove_circle_outline;
      case PerformanceMode.visualizerOnly:
        return Icons.visibility;
    }
  }

  Color _getModeColor(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return Colors.cyan;
      case PerformanceMode.performance:
        return Colors.orange;
      case PerformanceMode.minimal:
        return Colors.purple;
      case PerformanceMode.visualizerOnly:
        return Colors.pink;
    }
  }

  String _getModeName(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return 'Normal';
      case PerformanceMode.performance:
        return 'Performance';
      case PerformanceMode.minimal:
        return 'Minimal';
      case PerformanceMode.visualizerOnly:
        return 'Visualizer';
    }
  }

  String _getModeDescription(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return 'Full UI with all controls visible';
      case PerformanceMode.performance:
        return 'Optimized for live performance with key controls';
      case PerformanceMode.minimal:
        return 'Essential controls only for focused work';
      case PerformanceMode.visualizerOnly:
        return 'Immersive visual experience with hidden UI';
    }
  }
}

/// Quick toggle button for performance mode
class PerformanceModeQuickToggle extends StatelessWidget {
  final VoidCallback? onToggle;

  const PerformanceModeQuickToggle({
    Key? key,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PerformanceModeManager>(
      builder: (context, modeManager, child) {
        return IconButton(
          icon: Icon(
            _getModeIcon(modeManager.currentMode),
            color: _getModeColor(modeManager.currentMode),
          ),
          onPressed: () {
            // Cycle through modes
            final currentIndex = PerformanceMode.values.indexOf(modeManager.currentMode);
            final nextIndex = (currentIndex + 1) % PerformanceMode.values.length;
            modeManager.setMode(PerformanceMode.values[nextIndex]);
            onToggle?.call();
          },
          tooltip: 'Performance Mode: ${_getModeName(modeManager.currentMode)}',
        );
      },
    );
  }

  IconData _getModeIcon(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return Icons.tune;
      case PerformanceMode.performance:
        return Icons.speed;
      case PerformanceMode.minimal:
        return Icons.remove_circle_outline;
      case PerformanceMode.visualizerOnly:
        return Icons.visibility;
    }
  }

  Color _getModeColor(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return Colors.cyan;
      case PerformanceMode.performance:
        return Colors.orange;
      case PerformanceMode.minimal:
        return Colors.purple;
      case PerformanceMode.visualizerOnly:
        return Colors.pink;
    }
  }

  String _getModeName(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        return 'Normal';
      case PerformanceMode.performance:
        return 'Performance';
      case PerformanceMode.minimal:
        return 'Minimal';
      case PerformanceMode.visualizerOnly:
        return 'Visualizer';
    }
  }
}