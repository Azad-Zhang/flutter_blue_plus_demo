// ignore_for_file: prefer_function_declarations_over_variables

import 'package:flutter/material.dart';
import '../pages/tabs/Tabs.dart';

import '../pages/Blue.dart';

//配置路由
final Map<String,Function> routes = {
  '/': (context) => Tabs(), 
   '/blue':(context,{arguments})=>BluePage(arguments:arguments),
};

//固定写法
var onGenerateRoute = (RouteSettings settings) {
  final String? name = settings.name;
  final Function? pageContentBuilder = routes[name];
  if (pageContentBuilder != null) {
    if (settings.arguments != null) {
      final Route route = MaterialPageRoute(
          builder: (context) =>
              pageContentBuilder(context, arguments: settings.arguments));
      return route;
    } else {
      final Route route =
          MaterialPageRoute(builder: (context) => pageContentBuilder(context));
      return route;
    }
  }
  return null;
};
