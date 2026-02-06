Prompt para la parte de ejercicios 1 y 2 - Cámara e imágenes:

Hazme una aplicación en Flutter y Dart que permita al usuario capturar imágenes mediante
la cámara del dispositivo. Cada vez que se capture una imagen, se debe mostrar un mensaje
de confirmación indicando dónde se ha guardado. La aplicación debe detectar si se está
ejecutando en un dispositivo móvil o en escritorio, y en móvil guardar las fotos en la
galería del teléfono (en un álbum llamado "CameraApp"), y en escritorio guardarlas en la
carpeta de Descargas. Debe solicitar los permisos necesarios de cámara y almacenamiento de
forma automática al iniciar. Usa las librerías camera, gal y permission_handler. La
interfaz debe mostrar el preview de la cámara en tiempo real, un botón para disparar la
foto, y un contador de fotos tomadas en la barra superior.

Prompt para tu parte ejercicios 3 y 4 - Navegación, foto y reproductor de música:

Partiendo de una aplicación Flutter que ya tiene una pantalla de cámara funcional,
necesito ampliarla con lo siguiente: Añade una barra de navegación inferior con tres
pestañas: Càmera, Foto y Música. La navigation bar superior debe cambiar el título según
la pantalla activa. La pantalla de Foto debe mostrar la última imagen capturada desde la
cámara, y tener un menú desplegable con una opción "Informació de la foto" que muestre el
nombre y la ruta del archivo en un diálogo. Si no hay foto, debe mostrar un placeholder.
La pantalla de Música debe ser un reproductor de audio que cargue un mp3 desde los assets,
con botones de play/pause, stop, avanzar y retroceder 10 segundos, una barra de progreso
interactiva que permita posicionarse en cualquier punto del audio, indicador de tiempo
actual y total, y un menú desplegable para cambiar la velocidad de reproducción (0.5x, 1x,
1.5x, 2x). Usa las librerías audioplayers y path_provider.


# Camera App - Aplicación Flutter

Aplicación Flutter que muestra la cámara en tiempo real y permite tomar capturas de pantalla.

## Características
- Vista de cámara en tiempo real
- Botón "Camera Shot" para tomar fotos
- Compatible con Android, iOS, Windows, macOS y Linux
- Las fotos se guardan automáticamente

## Instalación

### 1. Crear proyecto Flutter
```bash
flutter create camera_app
cd camera_app
```

### 2. Reemplazar archivos
- Copia `main.dart` a `lib/main.dart`
- Copia `pubspec.yaml` a la raíz del proyecto

### 3. Instalar dependencias
```bash
flutter pub get
```

### 4. Configuración por plataforma

#### Android (android/app/src/main/AndroidManifest.xml)
Añade estos permisos dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

También añade dentro de `<manifest>` antes de `<application>`:
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

#### iOS (ios/Runner/Info.plist)
Añade estas claves dentro del `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para tomar fotos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Esta aplicación necesita acceso al micrófono</string>
```

#### macOS (macos/Runner/DebugProfile.entitlements y Release.entitlements)
Añade:
```xml
<key>com.apple.security.device.camera</key>
<true/>
```

También en `macos/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para tomar fotos</string>
```

#### Windows
No requiere configuración adicional.

#### Linux
Asegúrate de tener instalado:
```bash
sudo apt-get install libcamera-dev
```

### 5. Ejecutar la aplicación

Para móvil (Android/iOS):
```bash
flutter run
```

Para escritorio:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Ubicación de las fotos

Las fotos se guardan en el directorio de documentos de la aplicación:
- **Android**: `/data/data/com.example.camera_app/app_flutter/`
- **iOS**: `Library/Application Support/`
- **Windows**: `AppData\Roaming\camera_app\`
- **macOS**: `Library/Application Support/camera_app/`
- **Linux**: `~/.local/share/camera_app/`

## Solución de problemas

Si tienes problemas con los permisos de cámara:
1. Asegúrate de haber configurado los permisos correctamente según tu plataforma
2. Desinstala y reinstala la aplicación
3. En dispositivos físicos, verifica que los permisos estén habilitados en la configuración del sistema

## Dependencias utilizadas
- `camera`: ^0.10.5+5 - Para acceso a la cámara
- `path_provider`: ^2.1.1 - Para obtener directorios del sistema
- `path`: ^1.8.3 - Para manipulación de rutas de archivos
