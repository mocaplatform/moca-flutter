package com.moca.example;

import io.flutter.app.FlutterApplication;
import io.flutter.view.FlutterMain;
import com.innoquant.moca.MOCA;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
    }

}