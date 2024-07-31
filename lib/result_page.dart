import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  
  ResultPage({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analysis Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Result: ${result['predicted_class']}'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Provide Feedback'),
              onPressed: () => _showFeedbackDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Feedback'),
          content: Text('Is the result satisfactory?'),
          actions: [
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendFeedback(context, result['predicted_class'], "True");
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                _showCorrectAnswerDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCorrectAnswerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Correct Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please select the correct answer:'),
              SizedBox(height: 10),
              ...[
                'Plastic', 'Glass', 'Metal', 'Organic', 
                'Hygienic', 'Hazardous', 'Paper','Bulky'
              ].map((category) => ElevatedButton(
                child: Text(category),
                onPressed: () => _sendFeedback(context, category, "False"),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendFeedback(BuildContext context, String feedback, String isSatisfactory) async {
    
    //Navigator.of(context).pop();

    var uri = Uri.parse('https://me-central2-data-dev-412106.cloudfunctions.net/waste_bq');
    var filename = result['filename'];
    var response = await http.post(
      uri,
      body: json.encode({
        'filename': filename,
        'user_feedback': isSatisfactory,
        'correct_prediction': feedback,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback sent successfully')),
      ); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send feedback')),
      );
    }

    // Reset the application to the start
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}