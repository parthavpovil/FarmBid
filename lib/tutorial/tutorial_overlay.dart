import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const TutorialOverlay({
    Key? key,
    required this.steps,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    
    // Calculate dialog position
    final dialogWidth = 250.0;
    final dialogHeight = 150.0;
    
    // Get the circle's position
    final circlePosition = Offset(
      widget.steps[currentStep].position.dx + (widget.steps[currentStep].offset?.dx ?? 0),
      widget.steps[currentStep].position.dy + (widget.steps[currentStep].offset?.dy ?? 0),
    );
    
    // Calculate initial dialog position (below and to the right of the circle)
    double dialogLeft = circlePosition.dx + 20;
    double dialogTop = circlePosition.dy + widget.steps[currentStep].size.height + 20;
    
    // Adjust only the dialog position to keep it on screen
    if (dialogLeft + dialogWidth > screenSize.width) {
      dialogLeft = circlePosition.dx - dialogWidth - 20;
    }
    if (dialogLeft < 0) {
      dialogLeft = 20;
    }
    
    if (dialogTop + dialogHeight > screenSize.height) {
      dialogTop = circlePosition.dy - dialogHeight - 20;
    }
    if (dialogTop < 0) {
      dialogTop = circlePosition.dy + widget.steps[currentStep].size.height + 20;
    }

    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: _nextStep,
            child: Container(
              color: Colors.black54,
            ),
          ),
        ),
        
        // Highlight circle (positioned exactly where specified)
        Positioned(
          left: circlePosition.dx,
          top: circlePosition.dy,
          child: Container(
            width: widget.steps[currentStep].size.width,
            height: widget.steps[currentStep].size.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        
        // Tutorial dialog box (adjusted to stay on screen)
        Positioned(
          left: dialogLeft,
          top: dialogTop,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: screenSize.width - 40,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.steps[currentStep].title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.steps[currentStep].description,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentStep + 1}/${widget.steps.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      widget.onComplete();
    }
  }
}

class TutorialStep {
  final String title;
  final String description;
  final Offset position;
  final Size size;
  final Offset? offset;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.position,
    required this.size,
    this.offset,
  });
}