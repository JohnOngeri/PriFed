import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double w(BuildContext context, double percentage) => MediaQuery.of(context).size.width * percentage;
  static double h(BuildContext context, double percentage) => MediaQuery.of(context).size.height * percentage;
  static EdgeInsets pad(BuildContext context, double p) => EdgeInsets.all(w(context, p));
  static double radius(BuildContext context, double p) => w(context, p);
}