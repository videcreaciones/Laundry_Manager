Set-Content -Path "README.md" -Encoding UTF8 -Value @'
# 👔 Laundry Manager

Aplicación móvil Android para gestionar el ciclo de vida de prendas enviadas a lavandería. Permite registrar prendas, rastrear su estado y confirmar su devolución, con persistencia local y sin necesidad de conexión a internet.

## ✨ Funcionalidades

- Registrar prendas con nombre, propietario, foto y notas
- Ciclo de estados: **Guardada → Lavando → Devuelta → Guardada** (reutilizable)
- Cambio de estado con un solo toque
- Foto opcional desde la galería
- Persistencia local con Hive (los datos no se pierden al cerrar la app)
- Sin publicidad, sin internet requerido

## 🏗️ Arquitectura

Clean Architecture en 3 capas estrictas:
```
lib/
├── domain/        # Reglas de negocio puras (sin Flutter ni Hive)
│   ├── entities/
│   ├── usecases/
│   ├── repositories/
│   └── value_objects/
├── data/          # Persistencia con Hive
│   ├── models/
│   ├── mappers/
│   ├── datasources/
│   └── repositories/
└── presentation/  # UI con Flutter y Riverpod
    ├── providers/
    ├── screens/
    ├── widgets/
    └── router/
```

## 🛠️ Stack técnico

| Tecnología | Uso |
|---|---|
| Flutter 3.41 | Framework UI |
| Riverpod 3.x | Gestión de estado |
| Hive | Persistencia local |
| fpdart | Result pattern (Either) |
| go_router | Navegación |
| image_picker | Selección de fotos |

## 🧪 Testing

66 tests unitarios y de integración cubriendo el 100% de las reglas de negocio:
```bash
flutter test test/domain/ test/data/ --reporter expanded
```

## 🚀 Ejecutar el proyecto
```bash
flutter pub get
flutter run
```

## 📋 Reglas de negocio

- **RN-01:** Solo avance secuencial de estado (sin saltos ni retrocesos, ciclo infinito)
- **RN-02:** No se puede eliminar una prenda en estado LAVANDO
- **RN-03:** La foto es opcional — si falla la selección, la prenda se guarda sin imagen
- **RN-04:** Nombre y propietario son campos requeridos
- **RN-05:** Los cambios persisten inmediatamente (sin "guardar manual")
'@
```
