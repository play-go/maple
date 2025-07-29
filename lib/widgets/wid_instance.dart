// ignore_for_file: must_be_immutable, prefer_typing_uninitialized_variables, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fl;
// import 'dart:io' show Directory, Platform, File;

class Instance extends StatefulWidget {
  String name;
  fl.AccentColor color;
  Map pickedins;
  Map inst;
  var topickid;
  Image? icon;

  Instance(
    this.name,
    this.color,
    this.inst,
    this.pickedins,
    this.topickid, {
    this.icon,
    super.key,
  });

  @override
  _InstanceState createState() => _InstanceState();
}

class _InstanceState extends State<Instance> {
  bool checked = false;

  @override
  void initState() {
    super.initState();
    checked = widget.pickedins == widget.inst;
  }

  @override
  Widget build(BuildContext context) {
    checked = widget.pickedins == widget.inst;
    return fl.Button(
      style: fl.ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          checked ? widget.color.lighter : null,
        ),
      ),
      onPressed: () {
        widget.topickid(widget.inst);
      },
      child: Column(
        children: [
          widget.icon == null
              ? SizedBox(
                width: 50,
                height: 50,
                child: fl.Card(
                  backgroundColor: fl.Colors.grey,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(widget.name[0]),
                  ),
                ),
              )
              : SizedBox(
                width: 50,
                height: 50,
                child: fl.Card(
                  padding: fl.EdgeInsets.all(2),
                  backgroundColor: fl.Colors.grey,
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.icon,
                  ),
                ),
              ),
          Text(widget.name, overflow: fl.TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
