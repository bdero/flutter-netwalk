import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:netwalk/netwalk_controller.dart';

import 'netwalk_renderbox.dart';

class NetwalkWidget extends LeafRenderObjectWidget {
  final NetwalkController _controller;

  NetwalkWidget(this._controller, {Key? key}) : super(key: key);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      child: NetwalkRenderBox(this._controller),
      additionalConstraints: const BoxConstraints.expand(),
    );
  }
}
