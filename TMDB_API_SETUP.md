# 🔑 إعداد مفتاح TMDB API

## خطوات الحصول على مفتاح TMDB API:

### 1. إنشاء حساب TMDB
- اذهب إلى [https://www.themoviedb.org/](https://www.themoviedb.org/)
- قم بإنشاء حساب جديد أو تسجيل الدخول

### 2. طلب مفتاح API
- اذهب إلى إعدادات الحساب
- اختر "API" من القائمة الجانبية
- اطلب مفتاح API جديد
- اختر "Developer" كنوع الاستخدام
- املأ المعلومات المطلوبة

### 3. الحصول على Access Token
- بعد الموافقة على طلبك، ستحصل على:
  - API Key (v3 auth)
  - Access Token (v4 auth) - **هذا ما نحتاجه**

## 📍 أين تضع مفتاح API:

### الملف: `lib/constants/app_constants.dart`
```dart
static const String tmdbAccessToken = 'YOUR_TMDB_ACCESS_TOKEN_HERE';
```

### استبدل النص التالي:
```dart
// استبدل هذا:
static const String tmdbAccessToken = 'YOUR_TMDB_ACCESS_TOKEN_HERE';

// بمفتاحك الفعلي:
static const String tmdbAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJ...'; // مفتاحك الفعلي
```

## ⚠️ ملاحظات مهمة:

1. **استخدم Access Token وليس API Key**
   - التطبيق يستخدم Bearer Token authentication
   - Access Token يبدأ بـ `eyJ...`

2. **لا تشارك مفتاحك**
   - لا تضع المفتاح في GitHub أو أي مكان عام
   - احتفظ بنسخة احتياطية آمنة

3. **اختبار المفتاح**
   - بعد إضافة المفتاح، قم بتشغيل التطبيق
   - تأكد من ظهور الأفلام والمسلسلات

## 🔧 اختبار سريع:
```bash
# اختبر المفتاح باستخدام curl
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     "https://api.themoviedb.org/3/movie/popular"
```

إذا حصلت على استجابة JSON مع قائمة أفلام، فالمفتاح يعمل بشكل صحيح!

## 📱 بعد إضافة المفتاح:
1. احفظ الملف
2. أعد تشغيل التطبيق
3. ستظهر الأفلام والمسلسلات الحقيقية من TMDB
4. جميع الميزات ستعمل بشكل كامل