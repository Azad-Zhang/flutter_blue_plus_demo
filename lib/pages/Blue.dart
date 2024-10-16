import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluePage extends StatefulWidget {
  final Map arguments;
  BluePage({Key? key, required this.arguments}) : super(key: key);

  @override
  State<BluePage> createState() => _BluePageState();
}

class _BluePageState extends State<BluePage> {
  //获取设备
  late BluetoothDevice device;
  //获取设备连接的状态
  String deviceState = "";
  // //判断页面是否销毁
  bool isDesponse = false;
  //获取读写的特征值
  late BluetoothCharacteristic mCharacteristic;

  @override
  void initState() {
    super.initState();
    //获取设备
    this.device = widget.arguments["device"];
    print("蓝牙交互页面");
    print(this.device);

    //连接到设备
    startConnection();
  }

  @override
  void dispose() {
    isDesponse = true;
    // 断开与设备的连接
    device.disconnect();
    super.dispose();
  }

  void startConnection() async {
    // 连接到设备
    await device.connect();
    // 监听蓝牙状态
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (isDesponse == false) {
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            deviceState = "连接成功";
          });
          //发现服务
          this.discoverServices();
        } else if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            deviceState = "disconnected...";
          });
        }
      }
    });

//    清除：断开连接时取消订阅
//   - [delayed] 此选项仅适用于“connectionState”订阅。
//      当“true”时，我们会在稍有延迟后取消。这确保了`connectionState`
//     监听器接收到“断开连接”事件。
//   - [next] 如果为true，则仅在*下一次*断开连接时取消该流，
//     而不是电流断开。如果您设置订阅，这将非常有用
//     连接之前。
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

// 取消以防止重复侦听器
    // subscription.cancel();
  }

  discoverServices() async {
    //注意：每次重新连接后都必须调用discoverServices！
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // 打印服务的完整 UUID
      String fullUuid = getFullUuid(service.uuid.toString());
      print("Full UUID: $fullUuid");
      //厂商发给我们的可以读写的 UUID 0000ffe0-0000-1000-8000-00805f9b34fb
      if (fullUuid == "0000ffe0-0000-1000-8000-00805f9b34fb") {
        print("获取服务成功-----------------");
        // Reads all characteristics
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          print("-------------c.uuid的特征值----------------");
          print(getFullUuid(c.uuid.toString()));
          if (getFullUuid(c.uuid.toString()) ==
              "0000ffe1-0000-1000-8000-00805f9b34fb") {
            print("获取特征值成功-----------------");
            setState(() {
              mCharacteristic = c;
            });

            dataCallbackBle();
          }

          // if (c.properties.read) {
          //     List<int> value = await c.read();
          //     print(value);
          // }
        }
      }
    });
  }

  //读取蓝牙模块传过来的数据
  void dataCallbackBle() async {
    final subscription = this.mCharacteristic.onValueReceived.listen((value) {
      // onValueReceived is updated:
      //   - anytime read() is called
      //   - anytime a notification arrives (if subscribed)
      print("打印特征码-----------------");
      print(value);
      print(String.fromCharCodes(value));
    });

    //开启订阅
    await this.mCharacteristic.setNotifyValue(true);
    device.cancelWhenDisconnected(subscription);
  }

  String getFullUuid(String shortUuid) {
    // 蓝牙规范中的基本 UUID
    const String baseUuid = '0000xxxx-0000-1000-8000-00805f9b34fb';
    if (shortUuid.length == 4) {
      // 替换 baseUuid 中的 "xxxx" 为短 UUID
      return baseUuid.replaceFirst('xxxx', shortUuid);
    } else {
      return shortUuid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deviceState)),
      body: Container(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () async {
                  final command = "abcde";
                  final convertedCommand = AsciiEncoder().convert(command);

                  await this.mCharacteristic.write(convertedCommand);
                },
                child: Text("发送消息"))
          ],
        ),
      ),
    );
  }
}
