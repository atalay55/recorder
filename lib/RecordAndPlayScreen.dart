

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';

import 'package:permission_handler/permission_handler.dart';

class RecordAndPlayScreen extends StatefulWidget {
  const RecordAndPlayScreen({Key? key}) : super(key: key);

  @override
  State<RecordAndPlayScreen> createState() => _RecordAndPlayScreenState();
}

class _RecordAndPlayScreenState extends State<RecordAndPlayScreen> {
  final recorder = FlutterSoundRecorder();
  final player = AudioPlayer();
  late String path;
  bool isPlaying =false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isRecorderReady=false;
   int playCount=0 ;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initRecorder();

    player.onPlayerStateChanged.listen((event) {
      setState(() {
          isPlaying=event==PlayerState.playing;

      });
    });

    player.onDurationChanged.listen((event) {
      setState(() {
        duration=event;
      });
    });
    player.onPositionChanged.listen((event) {
      setState(() {
        position =event;
      });
    });

  }

  @override
  void dispose() {
    recorder.closeRecorder();
    player.dispose();
    super.dispose();
  }
  Future initRecorder()async{
    final status = await Permission.microphone.request();
    if(status != PermissionStatus.granted){
      throw "asdasdas";
    }
    await recorder.openRecorder();
    isRecorderReady=true;
    recorder.setSubscriptionDuration(Duration(milliseconds: 500));
  }
    Future record() async{
    if(!isRecorderReady) return;
      await recorder.startRecorder(toFile: 'audio');
    }


  Future play(String path) async{
    await player.play(UrlSource(path));

  }
  Future stop() async{
    if(!isRecorderReady) return;
    final String? path = await recorder.stopRecorder();
    if (path != null) {
      this.path= path;
      print("recorder Audio: $path");
    } else {
      print("recorder Audio path is null");
    }
  }



  void playAudioFile() async {

    while (playCount > 0) {
      await play(path);
      await playCount--;
      await player.onPlayerComplete.first;
    }
    await player.stop();
  }


  String formatTime(int time) {
    String twoDigits(int time) => time.toString().padLeft(2, '0');

    final twoDigitsMinutes = twoDigits((time ~/ 60) % 60);
    final twoDigitsSeconds = twoDigits(time % 60);

    return "$twoDigitsMinutes:$twoDigitsSeconds";
  }



  void _selectFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );

    if (result != null) {
      setState(() {
        path =   result.files.single.path!;
      });
    }

    await player.stop();
    await play(path);


  }



  var nameSurnameCont = TextEditingController();
  @override
  Widget build(BuildContext context){


    var width = MediaQuery.of(context).size.shortestSide;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [


              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Kayıt ",style: TextStyle(color: Colors.white ,fontSize: width/20),),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<RecordingDisposition>(
                    stream: recorder.onProgress,
                    builder: (context,snapshot){
                      final duration=snapshot.hasData?
                      snapshot.data!.duration:
                      Duration.zero;



                      return Text('${formatTime(duration.inSeconds)}',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white
                        ),);
                    }),
              ),
              Padding(
                padding:  EdgeInsets.symmetric(vertical: width/8.0),
                child: ElevatedButton(onPressed: () async{
                  if(recorder.isRecording){

                    await stop();
                  }else{
                    await record();
                  }
                  setState(() {

                  });
                },
                    child: Icon(
                      recorder.isRecording? Icons.stop : Icons.mic,
                      size: width/9 ,

                    ),
                    style: ButtonStyle( shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        )),minimumSize: MaterialStateProperty.all(const Size(80, 80)))),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: width / 6),
                child: TextFormField(
                  style: TextStyle(color: Colors.white),
                  controller: nameSurnameCont,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 2, color: Colors.purpleAccent),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 4, color: Colors.green),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    labelText: "Döngü Sayısını Giriniz",
                    labelStyle: TextStyle(fontSize: 18, color: Colors.white),
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Döngü sayısını girin';
                    }
                    return null;
                  },
            // Odaklanma özelliği eklendi
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("kalan döngü sayısı $playCount", style: TextStyle(color: Colors.white,fontSize: width/25),),
              ),



              Padding(
                padding:  EdgeInsets.symmetric(vertical: width/10.0),
                child: Slider(
                  min: 0,
                  max: duration.inSeconds.toDouble(),
                  value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                  onChanged: (value) async {
                    final newPosition = Duration(seconds: value.toInt());
                    await player.seek(newPosition);
                    await player.resume();
                    setState(() {
                      position = newPosition;
                    });
                  },
                ),

              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatTime((position.inSeconds)),style: TextStyle(color: Colors.white),),
                    Text(formatTime((duration.inSeconds-position.inSeconds)),style: TextStyle(color: Colors.white),),

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Padding(
                      padding:  EdgeInsets.only(top: width/10.0),
                      child: ElevatedButton(onPressed: () async{
                           _selectFiles();

                           setState(() {

                           });
                }, child: Text("Muzik dosyası seç"),
                      style: ButtonStyle( shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        )),maximumSize: MaterialStateProperty.all(const Size(110, 65)),
                          minimumSize: MaterialStateProperty.all(const Size(100, 40)))

                    )),
                   CircleAvatar(
                     radius: 35,
                     child: IconButton(
                       icon: Icon(
                           isPlaying? Icons.pause: Icons.play_arrow
                       ),iconSize: 50,
                       onPressed: () async{
                         await recorder.stopRecorder();
                         if(!isPlaying) {
                           await play(path);
                           await recorder.stopRecorder();
                         }else if(isPlaying){
                           await player.pause();
                         }else{
                           await player.resume();
                         }
                       },
                     ),
                   ),
                   Column(

                     children: [
                       ElevatedButton(
                         onPressed: ()async {
                           await recorder.stopRecorder();

                           playCount = int.parse(nameSurnameCont.text);
                           nameSurnameCont.text="";
                             setState(() {


                               playAudioFile();
                             });
                         },
                         child: Text("Seri Çal"),
                         style: ButtonStyle(
                           shape: MaterialStateProperty.all(
                             RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(30),
                             ),
                           ),
                           minimumSize: MaterialStateProperty.all(const Size(100, 40)),
                         ),
                       ),


                     ],
                   ),

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

