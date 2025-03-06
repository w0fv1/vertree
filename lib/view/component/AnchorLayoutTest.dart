import 'package:flutter/material.dart';
import 'package:vertree/view/component/AnchorLayout.dart';

class AnchorLayoutTest extends StatefulWidget {
  const AnchorLayoutTest({super.key});

  @override
  State<AnchorLayoutTest> createState() => _AnchorLayoutTestState();
}

class _AnchorLayoutTestState extends State<AnchorLayoutTest> {

  @override
  Widget build(BuildContext context) {
    return AnchorLayout(
      child: Container(height: 200, width: 200, color: Colors.lightBlue),
      top: buildPoint(),
      bottom: buildPoint(),
      left: buildPoint(),
      right: buildPoint(),
    );
  }

  Widget buildPoint() {
    return Container(width: 20, height: 20, color: Colors.red);
  }
}
