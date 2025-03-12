Remove-Item -Recurse -Force .\build
Remove-Item -Recurse -Force .\.dart_tool
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter upgrade