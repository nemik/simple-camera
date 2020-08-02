import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData iconData;
  final Color color;
  final Color iconColor;
  final double size;
  final double iconSize;

  const CircleButton({Key key, this.onTap, this.iconData, this.color, this.iconColor, this.size = 60, this.iconSize = 27}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //double size = 50.0;

    return new InkResponse(
      onTap: onTap,
      child: new Container(
        width: size,
        height: size,
        decoration: new BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: new Icon(
          iconData,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}