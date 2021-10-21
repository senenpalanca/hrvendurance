import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomAdvert extends StatelessWidget {
  const BottomAdvert({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 600,
      color: Colors.white54,
      alignment: Alignment.center,
      child: AnimatedSize(

        duration: Duration(milliseconds: 1150),
        curve: Curves.fastOutSlowIn,
        child: Container(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(

                //mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Sitúa la yema del dedo cubriendo totalmente la cámara pero sin presionar demasiado. Tapa también el flash con el dedo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10,),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      "https://images.squarespace-cdn.com/content/v1/5397da1ae4b0c0c130832759/1460100389675-GROLYC8RNTTA536ZDIOV/image-asset.png?format=500w",
                      height: 120.0,
                      width: 200.0,
                      fit: BoxFit.fitWidth,
                    ),
                  ),


                  SizedBox(height:40,),
                  Text("Relájate y respira hondo y pausado.",textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
