# تطبيق الماء - هيكل المشروع

## نظرة عامة
تم إعادة تنظيم المشروع باستخدام طريقة **Block Structure** لتحسين التنظيم والقراءة والصيانة.

## هيكل المجلدات

### 📁 `/blocks`
إدارة حالة التطبيق والعمليات الأساسية

- **`app_block.dart`** - إدارة الحالة العامة للتطبيق
- **`auth_block.dart`** - إدارة المصادقة والمستخدمين
- **`water_tracker_block.dart`** - تتبع شرب الماء
- **`cart_block.dart`** - إدارة سلة التسوق
- **`orders_block.dart`** - إدارة الطلبات

### 📁 `/screens`
شاشات التطبيق الرئيسية

- **`home_screen.dart`** - الشاشة الرئيسية
- **`auth_screen.dart`** - شاشة المصادقة
- **`product_catalog.dart`** - كتالوج المنتجات
- **`checkout_screen.dart`** - شاشة الدفع
- **`orders_screen.dart`** - شاشة الطلبات
- **`map_screen.dart`** - شاشة الخريطة
- **`user_dashboard.dart`** - لوحة تحكم المستخدم
- **`health_tracker.dart`** - تتبع الصحة
- **`splash_screen.dart`** - شاشة البداية

### 📁 `/widgets`
العناصر القابلة لإعادة الاستخدام

### 📁 `/models`
نماذج البيانات

- **`user_model.dart`** - نموذج المستخدم

### 📁 `/services`
خدمات التطبيق (API, Storage, etc.)

### 📁 `/utils`
الدوال المساعدة

- **`helpers.dart`** - دوال مساعدة عامة

### 📁 `/constants`
ثوابت التطبيق

- **`app_constants.dart`** - ثوابت التطبيق العامة

## مزايا هذا الهيكل

### 🎯 **تنظيم واضح**
- فصل المسؤوليات
- سهولة العثور على الملفات
- هيكل منطقي

### 🔄 **قابلية الصيانة**
- سهولة التحديث
- إصلاح الأخطاء بسرعة
- إضافة ميزات جديدة

### 📚 **قابلية القراءة**
- كود منظم
- تعليقات واضحة
- أسماء ملفات معبرة

### 🚀 **قابلية التوسع**
- إضافة blocks جديدة
- إضافة screens جديدة
- إضافة models جديدة

## كيفية الاستخدام

### استيراد Blocks
```dart
import 'package:water_user/blocks/index.dart';
```

### استيراد Models
```dart
import 'package:water_user/models/index.dart';
```

### استيراد Constants
```dart
import 'package:water_user/constants/index.dart';
```

### استيراد Utils
```dart
import 'package:water_user/utils/index.dart';
```

## أفضل الممارسات

1. **استخدم Blocks** لإدارة الحالة
2. **استخدم Models** لتعريف البيانات
3. **استخدم Constants** للقيم الثابتة
4. **استخدم Utils** للدوال المساعدة
5. **حافظ على التنظيم** في كل مجلد

## التطوير المستقبلي

- إضافة **Services** للـ API
- إضافة **Tests** للاختبارات
- إضافة **Localization** للترجمة
- إضافة **Themes** للتصميم 