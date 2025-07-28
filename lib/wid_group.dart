// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fl;
// import 'dart:io' show Directory, Platform, File;

class Group extends StatefulWidget {
  String name;
  List<Widget> listof;
  Group(this.name, this.listof, {super.key});

  @override
  _GroupState createState() => _GroupState();
}

class _GroupState extends State<Group> {
  bool opened = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        fl.Button(
          onPressed: () {
            setState(() => opened = !opened);
          },
          child: Row(
            spacing: 5,
            children: [
              opened
                  ? fl.Icon(fl.FluentIcons.remove)
                  : fl.Icon(fl.FluentIcons.add),
              fl.Text(widget.name),
            ],
          ),
        ),
        opened ? SizedBox(height: 5) : Container(),
        opened
            ? SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.start,

                spacing: 5,
                runSpacing: 3,
                children: widget.listof,
              ),
            )
            : Container(),
        SizedBox(height: 8),
      ],
    );
  }
}
