import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //定义蓝牙实例
  final FlutterBluePlus flutterBlue = FlutterBluePlus(); // 修改这里，不再使用 instance
  //定义蓝牙状态
  bool isBlueOn = false;
  bool hasPermission = false;
  //蓝牙设备的列表
  List<BluetoothDevice> blueList = [];

  late StreamSubscription<List<ScanResult>> subscription;
  @override
  void initState() {
    super.initState();
    requestPermission();
    startBluetooth();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void startBluetooth() async {
    // 首先，检查硬件是否支持蓝牙
    //注意：平台是在第一次调用任何FlutterBluePlus方法时初始化的。
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    // 监听蓝牙是否开启
    // 注意：对于iOS，初始状态通常为BluetoothAdapterState.unknown
    // 注意：如果您有权限问题，您将被困在BluetoothAdapterState.unauthorized
    var subscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState state) async {
      if (state == BluetoothAdapterState.on) {
        print("蓝牙已打开");
        setState(() {
          this.isBlueOn = true;
          startScanning();
          //     this.requestPermission();
        });
      } else {
        print("请打开蓝牙");

        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        }
        setState(() {
          this.isBlueOn = false;
          this.blueList = [];
        });
      }
    });
    // 清理：取消订阅
    FlutterBluePlus.cancelWhenScanComplete(subscription);
  }

  void startScanning() async {
    // 监听扫描结果
    // 注意：“onScanResults”仅返回实时扫描结果，即在扫描过程中。使用
    // “scanResults”（如果要实时扫描结果）*或*上一次扫描的结果。

    // 开始扫描w/超时
    // 可选：使用“stopScan（）”替代超时
    await FlutterBluePlus.startScan(
        // withServices: [Guid("180D")], // 匹配任何指定的服务
        // withNames: ["HC-04BLE"], // *或*任何指定的名称
        // withNames: ['HC-04BLE',"*"],
        timeout: Duration(seconds: 2));

    subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // 最后发现的设备
          print("找到了设备---------------");
          print(
              '${r.device.remoteId}: "${r.advertisementData.advName}" found! rssi:${r.rssi}');
          if (r.device.advName.length > 2) {
            setState(() {
              if (this.blueList.indexOf(r.device) == -1) {
                this.blueList.add(r.device);
              }
            });
          }
        } else {
          print("没有找到设备");
        }
      },
      onError: (e) => print(e),
    );

    // 清理：取消订阅
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // 等待扫描停止
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    print("所有设备");
    print(this.blueList);
  }

  // 动态申请权限
  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      bool allGranted = statuses.values.every((status) => status.isGranted);
      if (allGranted) {
        print("权限已授予");
      } else {
        print("需要蓝牙和位置权限");
        // 提示用户需要权限
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("权限请求"),
              content: Text("应用需要蓝牙和位置权限才能正常工作。"),
              actions: <Widget>[
                TextButton(
                  child: Text("确定"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: this.blueList.length > 0
          ? Column(
              children: this.blueList.map((device) {
                return ListTile(
                  title: Text("${device.advName}       ${device.remoteId}"),
                  onTap: () {
                    Navigator.pushNamed(context, '/blue',
                        arguments: {"device": device});
                  },
                );
              }).toList(),
            )
          : this.isBlueOn
              ? Container(
                  child: this.hasPermission ? Text("没有扫描到设备") : Text("没有蓝牙权限"),
                )
              : Text("没有打开蓝牙"),
    );
  }
}
