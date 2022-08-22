import 'package:flutter/material.dart';

class AppDialog extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? leftBtn;
  final Widget? rightBtn;
  final Widget? neutralBtn;

  const AppDialog({Key? key,
    required this.title,
    required this.child,
    required this.leftBtn,
    required this.rightBtn,
    this.neutralBtn})
      : super(key: key);

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Padding(
          padding: const EdgeInsets.only(left: 28.0, right: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.title,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.child,
              ),
              if (null != widget.neutralBtn) Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: widget.neutralBtn!)
                  ],
                ),
              ),
              if (null != widget.leftBtn && null != widget.rightBtn)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: widget.leftBtn!),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(child: widget.rightBtn!),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
