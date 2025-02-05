# moca_flutter_example

## Before first time build
Execute these steps before editing example project in Android Studio and XCode:
```
    cd example
    flutter pub get
    flutter build apk --config-only
    pod repo update
    flutter build ios --config-only
```


The --config-only flag tells the Flutter tool to run only the configuration phase of the build process. In other words, Flutter will generate (or update) the build configuration files (and any other necessary intermediate configuration artifacts) without actually compiling or packaging the app. This can be useful when you want to verify or inspect the configuration that would be used for a full build without waiting for a full build to complete.



