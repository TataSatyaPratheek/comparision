
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ComparisonGameStateProvider with ChangeNotifier {
  int currentLevel = 1;
  int score = 0;
  int correctAnswers = 0;
  List<num> targetOrder = [];
  List<num> numberCards = [];
  List<num?> placedNumbers = [];
  Random random = Random();
  late Timer _timer;
  int timeLeft = 30;
  String feedbackMessage = "";

  ComparisonGameStateProvider() {
    _timer = Timer(const Duration(seconds: 1), () {});
    loadLevel(currentLevel);
  }

  void loadLevel(int level) {
    _timer.cancel();

    targetOrder.clear();
    numberCards.clear();
    placedNumbers = List<num?>.filled(5, null);
    feedbackMessage = "";

    final Set<num> uniqueNumbers = {};
    while (uniqueNumbers.length < 5) {
      num number;
      if (level % 2 == 1) {
        number = double.parse(
            (random.nextDouble() * 2000 - 1000).toStringAsFixed(2));
      } else {
        number = random.nextInt(2001) - 1000;
      }
      uniqueNumbers.add(number);
    }

    targetOrder = uniqueNumbers.toList();
    numberCards = List<num>.from(targetOrder);

    targetOrder.sort();
    notifyListeners();

    timeLeft = 30 - ((level - 1) * 5);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        notifyListeners();
      } else {
        _timer.cancel();
        showTimeoutFeedback();
        loadLevel(currentLevel);
      }
    });
  }

  void checkPlacement(DragTargetDetails<num> details, num expectedNumber) {
    num number = details.data;
    if (number == expectedNumber) {
      score += 10;
      placedNumbers[targetOrder.indexOf(expectedNumber)] = number;
      correctAnswers++;
      notifyListeners();

      if (isLevelComplete()) {
        _timer.cancel();
        Future.delayed(const Duration(seconds: 3), nextLevel);
        showNextLevelFeedback();
      } else {
        showCorrectFeedback();
      }
    } else {
      showIncorrectFeedback();
    }
  }

  bool isLevelComplete() {
    return correctAnswers >= 5;
  }

  void nextLevel() {
    correctAnswers = 0;
    currentLevel++;
    if (currentLevel > 5) {
      currentLevel = 1;
    }
    loadLevel(currentLevel);
    notifyListeners();
  }

  void showCorrectFeedback() {
    feedbackMessage = "✅ Correct Answer!";
    notifyListeners();
  }

  void showNextLevelFeedback() {
    feedbackMessage = "🎉 Congratulations! Moving to next level.";
    notifyListeners();
  }

  void showTimeoutFeedback() {
    feedbackMessage = "⏰ Time's up! Restarting the level.";
    notifyListeners();
  }

  void showIncorrectFeedback() {
    feedbackMessage = "❌ Incorrect! Try again.";
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final gameState = context.watch<ComparisonGameStateProvider>();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardSize = screenWidth * 0.15;
    final dropZoneSize = screenWidth * 0.1;

    final double timerProgress =
    (gameState.timeLeft > 30) ? 0 : (30 - gameState.timeLeft) / 30;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Number Comparison Game'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Level and Score Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Level',
                    value: gameState.currentLevel.toString(),
                    color: Colors.blueAccent,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Score',
                    value: gameState.score.toString(),
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Instruction Text
              Text(
                'Drag and drop the numbers in ascending order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              // Feedback Message
              if (gameState.feedbackMessage.isNotEmpty)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    gameState.feedbackMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: _getFeedbackColor(gameState.feedbackMessage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // Timer Display
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: timerProgress,
                    backgroundColor: Colors.grey[800],
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.transparent),
                    strokeWidth: 8.0,
                  ),
                  Text(
                    '${gameState.timeLeft} sec',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress Indicator
              LinearProgressIndicator(
                value: gameState.correctAnswers / 5,
                backgroundColor: Colors.grey[700],
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 10,
              ),
              const SizedBox(height: 30),
              // Draggable Number Cards
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: gameState.numberCards.map((number) {
                  final isPlaced = gameState.placedNumbers.contains(number);
                  return DraggableCard(
                    number: number,
                    size: cardSize,
                    color: isPlaced
                        ? Colors.grey[500]!
                        : theme.colorScheme.secondary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              // Drop Zones
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: List.generate(
                  gameState.targetOrder.length,
                      (index) => DropZone(
                    expectedNumber: gameState.targetOrder[index],
                    size: dropZoneSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFeedbackColor(String message) {
    if (message.startsWith('✅') || message.startsWith('🎉')) {
      return Colors.greenAccent;
    } else if (message.startsWith('❌') || message.startsWith('⏰')) {
      return Colors.redAccent;
    }
    return Colors.white;
  }
}


class DraggableCard extends StatelessWidget {
  final num number;
  final double size;
  final Color color;

  const DraggableCard(
      {Key? key, required this.number, required this.size, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => Feedback.forTap(context),
      child: Draggable<num>(
        data: number,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: _buildCard(context, number, color, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildCard(context, number, Colors.grey, isDragging: false),
        ),
        child: _buildCard(context, number, color, isDragging: false),
      ),
    );
  }

  Widget _buildCard(BuildContext context, num number, Color color,
      {required bool isDragging}) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class DropZone extends StatelessWidget {
  final num expectedNumber;
  final double size;

  const DropZone(
      {Key? key, required this.expectedNumber, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState =
    Provider.of<ComparisonGameStateProvider>(context, listen: false);
    final theme = Theme.of(context);

    return DragTarget<num>(
      onAcceptWithDetails: (receivedNumber) {
        gameState.checkPlacement(receivedNumber, expectedNumber);
      },
      builder: (context, candidateData, rejectedData) {
        bool isPlaced = gameState.placedNumbers.contains(expectedNumber);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPlaced
                ? Colors.grey[700]
                : (candidateData.isNotEmpty
                ? theme.colorScheme.secondary.withOpacity(0.2)
                : theme.colorScheme.surface),
            border: Border.all(
              color: isPlaced
                  ? Colors.greenAccent
                  : (candidateData.isNotEmpty
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface.withOpacity(0.3)),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isPlaced ? expectedNumber.toString() : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPlaced
                    ? Colors.greenAccent
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        );
      },
    );
  }
}