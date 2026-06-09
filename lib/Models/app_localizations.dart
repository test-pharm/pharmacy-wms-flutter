import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
 en, ar 
}

final ValueNotifier<AppLanguage> languageNotifier =    ValueNotifier(AppLanguage.en);
const _kLangKey = 'app_language';
Future<void> initLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kLangKey);
  if (saved == 'ar') {
    languageNotifier.value = AppLanguage.ar;
  
}
}


Future<void> saveLanguage(AppLanguage lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLangKey, lang.name);

}
extension LocalizationContext on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(languageNotifier.value);

  IconData get backIcon => tr.isArabic ? Icons.arrow_forward : Icons.arrow_back;
  IconData get forwardIcon => tr.isArabic ? Icons.arrow_back : Icons.arrow_forward;
  IconData get forwardIosIcon => tr.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios;
  IconData get chevronCollapseIcon => tr.isArabic ? Icons.chevron_right : Icons.chevron_left;
  IconData get chevronExpandIcon => tr.isArabic ? Icons.chevron_left : Icons.chevron_right;
}

class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations._(this.language);
  static AppLocalizations of(AppLanguage lang) =>      AppLocalizations._(lang);
  bool get isArabic => language == AppLanguage.ar;
  TextDirection get textDirection =>      isArabic ? TextDirection.rtl : TextDirection.ltr;
    String get appTitle => isArabic ? 'نظام إدارة المستودعات' : 'Pharmacy WMS';
  String get appSubtitle => isArabic ? 'نظام إدارة المستودعات الصيدلانية' : 'Pharmacy WMS';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get submit => isArabic ? 'إرسال' : 'Submit';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get search => isArabic ? 'بحث' : 'Search';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';
  String get required => isArabic ? 'مطلوب' : 'Required';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'نجاح' : 'Success';
  String get clear => isArabic ? 'مسح' : 'Clear';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get print => isArabic ? 'طباعة' : 'Print';
  String get export => isArabic ? 'تصدير' : 'Export';
  String get noData => isArabic ? 'لا توجد بيانات' : 'No data';
  String get unknownUser => isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get more => isArabic ? 'المزيد ->' : 'More ->';
    String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get inventory => isArabic ? 'المخزون' : 'Inventory';
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get toggleTheme => isArabic ? 'تبديل السمة' : 'Toggle theme';
  String get toggleLanguage => isArabic ? 'تبديل اللغة' : 'Toggle language';
  String get pharmaWarehouse => isArabic ? 'مستودع الصيدلية' : 'PharmaWarehouse';
    String get manager => isArabic ? 'مدير' : 'Manager';
  String get supervisor => isArabic ? 'مشرف' : 'Supervisor';
  String get warehouseManager => isArabic ? 'مدير المستودع' : 'Warehouse Manager';
  String get supervisorView => isArabic      ? 'عرض المشرف — للقراءة فقط.'      : 'Supervisor view — read-only.';
    String criticalAlerts(int count) => isArabic      ? '$count تنبيه${
count == 1 ? '' : 'ات'
} حرجة'      : '$count Critical Alert${
count == 1 ? '' : 's'
}';
  String expiredExpiringSoon(int count) => isArabic      ? '$count منتهي / قارب على الانتهاء'      : '$count expired / expiring soon';
  String lowStockItems(int count) => isArabic      ? '$count صنف${
count == 1 ? '' : 'أصناف'
} منخفض المخزون'      : '$count low-stock item${
count == 1 ? '' : 's'
}';
    String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get enterEmail => isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
  String get enterPassword => isArabic ? 'أدخل كلمة مرورك' : 'Enter your password';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'SIGN IN';
  String get createAccount => isArabic ? 'إنشاء حساب' : 'CREATE ACCOUNT';
  String get registerNewUser => isArabic ? 'تسجيل مستخدم جديد' : 'Register New User';
  String get alreadyHaveAccount => isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get loginFailed => isArabic ? 'فشل تسجيل الدخول' : 'Login failed';
  String get invalidEmail => isArabic ? 'أدخل بريدًا إلكترونيًا صالحًا' : 'Enter a valid email';
  String get enterYourEmail => isArabic ? 'من فضلك أدخل بريدك الإلكتروني' : 'Please enter your email';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get confirmPassword => isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get passwordsDoNotMatch => isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get atLeast6Chars => isArabic ? 'على الأقل 6 أحرف' : 'At least 6 characters';
  String get minSixChars => isArabic ? 'الحد الأدنى 6 أحرف' : 'Min. 6 characters';
  String get repeatPassword => isArabic ? 'أعد كتابة كلمتك المرور' : 'Repeat your password';
  String get validPhone => isArabic ? 'أدخل رقم هاتف صالحًا' : 'Enter a valid phone number';
  String get roleLabel => isArabic ? 'الدور' : 'Role';
  String get backToLogin => isArabic ? 'العودة لتسجيل الدخول' : 'Back to Login';
    String get warehouseOverview => isArabic ? 'نظرة عامة على المستودع' : 'Warehouse Overview';
  String get totalMaterials => isArabic ? 'إجمالي المواد' : 'Total Materials';
  String get nearingExpiry => isArabic ? 'قاربت على الانتهاء' : 'Nearing Expiry';
  String get lowStockItemsTitle => isArabic ? 'أصناف منخفضة المخزون' : 'Low Stock Items';
  String get criticalAlertsTitle => isArabic ? 'التنبيهات الحرجة' : 'Critical Alerts';
  String get recentMaterials => isArabic ? 'المواد الأخيرة' : 'Recent Materials';
  String get chartPlaceholder => isArabic ? 'مخطط بياني' : 'Chart Visualization Placeholder';
  String get noCriticalAlerts => isArabic ? 'لا توجد تنبيهات حرجة' : 'No critical alerts';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get noNotifications => isArabic ? 'لا توجد إشعارات' : 'No notifications';
  String get noActiveNotifications => isArabic ? 'لا توجد إشعارات نشطة' : 'No active notifications';
  String get markRead => isArabic ? 'تعيين كمقروء' : 'Mark Read';
  String get markAllRead => isArabic ? 'تعيين الكل كمقروء' : 'Mark All Read';
  String get searchHint => isArabic      ? 'ابحث عن مواد أو طلبات أو تقارير'      : 'Search for materials, orders, or reports';
    String get inventoryTitle => isArabic ? 'قائمة المخزون' : 'Inventory List';
  String get addMaterial => isArabic ? 'إضافة مادة' : 'Add Material';
  String get exportMaterial => isArabic ? 'صرف مادة' : 'Dispatch Material';
  String get materialName => isArabic ? 'اسم المادة' : 'Material Name';
  String get materialSku => isArabic ? 'رمز المادة (SKU)' : 'Material SKU';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';
  String get unit => isArabic ? 'الوحدة' : 'Unit';
  String get logNumber => isArabic ? 'رقم السجل' : 'Log Number';
  String get expiryDate => isArabic ? 'تاريخ الانتهاء' : 'Expiry Date';
  String get storageLocation => isArabic ? 'موقع التخزين' : 'Storage Location';
  String get supplier => isArabic ? 'المورد' : 'Supplier';
  String get recipient => isArabic ? 'المستلم' : 'Recipient';
  String get hintSupplierExample => isArabic ? 'مثال: المورد العالمي' : 'e.g. Global Supplier Co.';
  String get hintRecipientExample => isArabic ? 'مثال: أحمد محمد' : 'e.g. Ahmed Mohamed';
  String get category => isArabic ? 'الفئة' : 'Category';
  String get categoryId => isArabic ? 'معرف الفئة' : 'Category ID';
  String get status => isArabic ? 'الحالة' : 'Status';
  String get available => isArabic ? 'متاح' : 'Available';
  String get unavailable => isArabic ? 'غير متاح' : 'Unavailable';
  String get actions => isArabic ? 'الإجراءات' : 'Actions';
  String get filterByCategory => isArabic ? 'تصفية حسب الفئة' : 'Filter by category';
  String get allCategories => isArabic ? 'كل الفئات' : 'All Categories';
  String get confirmDelete => isArabic ? 'تأكيد الحذف' : 'Confirm Delete';
  String get deleteConfirmMsg => isArabic      ? 'هل أنت متأكد أنك تريد حذف هذه المادة؟'      : 'Are you sure you want to delete this material?';
  String get editProduct => isArabic ? 'تعديل المادة' : 'Edit Material';
  String get noProductsFound => isArabic ? 'لا توجد مواد' : 'No materials found';
  String get searchByNameOrSku => isArabic ? 'ابحث بالاسم أو الرمز' : 'Search by Name or SKU';
    String get statusGood => isArabic ? 'جيد' : 'Good';
  String get statusExpired => isArabic ? 'منتهي الصلاحية' : 'Expired';
  String get statusExpiringSoon => isArabic ? 'ينتهي قريبًا' : 'Expiring Soon';
  String get statusLowStock => isArabic ? 'مخزون منخفض' : 'Low Stock';
  String get statusUnknown => isArabic ? 'غير معروف' : 'Unknown';
    String get addMaterialTitle => isArabic ? 'إضافة مادة جديدة' : 'Add New Material';
  String get addMaterialSubtitle => isArabic      ? 'أضف مادة جديدة إلى مخزون المستودع.'      : 'Add a new material to the warehouse inventory.';
  String get isAvailable => isArabic ? 'متاح' : 'Is Available';
  String get positiveNumber => isArabic ? 'أدخل رقمًا موجبًا' : 'Enter a positive number';
  String get skuHint => isArabic ? 'مثال: MED-1001' : 'e.g. MED-1001';
  String get quantityHint => isArabic ? 'مثال: 100' : 'e.g. 100';
  String get unitHint => isArabic ? 'علبة / زجاجة / شريط' : 'box / bottle / strip';
  String get logHint => isArabic ? 'LOT-2026-01' : 'LOT-2026-01';
  String get locationHint => isArabic ? 'مثال: الرف A1' : 'e.g. Shelf A1';
  String get categoryIdHint => isArabic ? '1' : '1';
  String get selectDate => isArabic ? 'اختر تاريخًا' : 'Select date';
  String get addingProduct => isArabic ? 'جارٍ الإضافة...' : 'Adding...';
  String get productAdded => isArabic ? 'تمت إضافة المادة بنجاح' : 'Material added successfully';
    String get invoiceNumber => isArabic ? 'رقم الفاتورة' : 'Invoice Number';
  String get exportProductTitle => isArabic ? 'صرف مادة' : 'Dispatch Material';
  String get exportProductSubtitle => isArabic      ? 'سجّل مغادرة المادة من مخزون المستودع.'      : 'Record material leaving warehouse inventory.';
  String get exportProductBtn => isArabic ? 'صرف' : 'Dispatch';
  String get productNotFound => isArabic ? 'المادة غير موجودة في المخزون' : 'Material not found in inventory';
  String get outOfStock => isArabic ? 'هذا الصنف نفد من المخزون' : 'This item is already out of stock';
  String get exceedsStock => isArabic ? 'الكمية المُصدَّرة تتجاوز المخزون المتاح' : 'Dispatch quantity exceeds available stock';
  String get typeHintSearch => isArabic ? 'اكتب اسم المادة أو الرمز' : 'Type material name or SKU';
    String get requestExpiryEdit => isArabic ? 'طلب تعديل تاريخ الانتهاء' : 'Request Expiry Edit';
  String get product => isArabic ? 'المادة' : 'Material';
  String get sku => isArabic ? 'الرمز' : 'SKU';
  String get newExpiryDate => isArabic ? 'تاريخ الانتهاء الجديد' : 'New Expiry Date';
  String get requestEdit => isArabic ? 'طلب التعديل' : 'Request Edit';
    String get ordersTitle => isArabic ? 'سجل الطلبات' : 'Orders Log';
  String get pendingOrders => isArabic ? 'الطلبات المعلقة' : 'Pending Orders';
  String get noOrders => isArabic ? 'لا توجد طلبات' : 'No orders';
  String get orderType => isArabic ? 'نوع الطلب' : 'Order Type';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get createdBy => isArabic ? 'أنشئ بواسطة' : 'Created By';
  String get createdAt => isArabic ? 'تاريخ الإنشاء' : 'Created At';
  String get notes => isArabic ? 'ملاحظات' : 'Notes';
  String get approve => isArabic ? 'قبول' : 'Approve';
  String get reject => isArabic ? 'رفض' : 'Reject';
  String get orderTypeAdd => isArabic ? 'إضافة' : 'Add';
  String get orderTypeExport => isArabic ? 'صرف' : 'Dispatch';
  String get orderTypeEdit => isArabic ? 'تعديل' : 'Edit';
  String get orderTypeRefund => isArabic ? 'استرجاع' : 'Refund';
  String get orderStatusCompleted => isArabic ? 'مكتمل' : 'Completed';
  String get orderStatusPending => isArabic ? 'معلق' : 'Pending';
  String get orderStatusCanceled => isArabic ? 'ملغى' : 'Canceled';
  String get printOrders => isArabic ? 'طباعة الطلبات' : 'Print Orders';
  String get supervisorReadOnly => isArabic      ? 'عرض المشرف — للقراءة فقط. يمكنك طباعة الطلبات.'      : 'Supervisor view — read-only. You may print orders.';
    String get reportsTitle => isArabic ? 'التقارير' : 'Reports';
  String get printReport => isArabic ? 'طباعة التقرير' : 'Print Report';
  String get supervisorReportReadOnly => isArabic      ? 'عرض المشرف — للقراءة فقط. يمكنك طباعة التقارير.'      : 'Supervisor view — read-only. You may print reports.';
  String get totalStock => isArabic ? 'إجمالي المخزون' : 'Total Stock';
  String get expiredItems => isArabic ? 'أصناف منتهية الصلاحية' : 'Expired Items';
  String get expiringSoonItems => isArabic ? 'أصناف تنتهي قريبًا' : 'Expiring Soon Items';
  String get categoryBreakdown => isArabic ? 'توزيع الفئات' : 'Category Breakdown';
  String get stockByCategory => isArabic ? 'المخزون حسب الفئة' : 'Stock by Category';
  String get overview => isArabic ? 'نظرة عامة' : 'Overview';
  String get expiryAnalysis => isArabic ? 'تحليل تاريخ الصلاحية' : 'Expiry Analysis';
  String get statusDistribution => isArabic ? 'توزيع الحالة' : 'Status Distribution';
  String get categoriesLabel => isArabic ? 'فئات' : 'categories';
  String get analytics => isArabic ? 'تحليلات' : 'Analytics';
  String get expiryTimeline => isArabic ? 'الجدول الزمني لانتهاء الصلاحية' : 'Expiry Timeline';
    String get userInfo => isArabic ? 'معلومات المستخدم' : 'User Info';
  String get profileSettings => isArabic ? 'إعدادات الملف الشخصي' : 'Profile Settings';
  String get accountDetails => isArabic ? 'تفاصيل الحساب' : 'Account Details';
  String get changePassword => isArabic ? 'تغيير كلمة المرور' : 'Change Password';
  String get updateProfile => isArabic ? 'تحديث الملف الشخصي' : 'Update Profile';
  String get registerUser => isArabic ? 'تسجيل مستخدم' : 'Register User';
  String get registerAdmin => isArabic ? 'تسجيل مدير' : 'Register Admin';
  String get userList => isArabic ? 'قائمة المستخدمين' : 'User List';
    String get stocktake => isArabic ? 'الجرد' : 'Stocktake';
  String get stocktakeDesc => isArabic      ? 'توليد كشف الجرد للعد الفعلي للمخزون في المستودع.'      : 'Generate a stocktake sheet to physically count warehouse inventory.';
  String get totalItems => isArabic ? 'إجمالي الأصناف' : 'total items';
  String get storageLocationsLabel => isArabic ? 'مواقع تخزين' : 'storage locations';
  String get generateStocktake => isArabic ? 'توليد كشف الجرد' : 'Generate Stocktake Sheet';
  String get unspecified => isArabic ? 'غير محدد' : 'Unspecified';
  String get itemsLabel => isArabic ? 'أصناف' : 'items';
  String get skuPrefix => isArabic ? 'رمز: ' : 'SKU: ';
  String get qtyPrefix => isArabic ? 'الكمية: ' : 'Qty: ';
  String get stocktakeSheet => isArabic ? 'كشف الجرد' : 'Stocktake Sheet';
  String get pdfInstructions => isArabic      ? 'تعليمات: تجول في كل موقع، واحسب الكمية الفعلية، واكتبها في عمود "العدد الفعلي". سجل أي اختلافات.'      : 'Instructions: Walk through each location, count the actual quantity, and write it in the "Actual Count" column. Note any discrepancies.';
  String get locationPrefix => isArabic ? 'الموقع: ' : 'Location: ';
  String get pdfColumnNum => isArabic ? '#' : '#';
  String get pdfColumnProductName => isArabic ? 'اسم المادة' : 'Material Name';
  String get pdfColumnActualCount => isArabic ? 'العدد الفعلي' : 'Actual Count';
  String get chooseExportMethod => isArabic ? 'اختر طريقة التصدير:' : 'Choose how to export:';
  String get saveOrShare => isArabic ? 'حفظ / مشاركة' : 'Save / Share';
  String get generatedPrefix => isArabic ? 'تم الإنشاء: ' : 'Generated: ';
  String get errorGeneratingPdf => isArabic ? 'خطأ في إنشاء ملف PDF' : 'Error generating PDF';
    String get refreshTooltip => isArabic ? 'تحديث' : 'Refresh';
  String get addProduct => isArabic ? 'إضافة مادة' : 'Add Material';
  String get dispatchBtn => isArabic ? 'صرف' : 'Dispatch';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noProductsFiltered => isArabic      ? 'لا توجد مواد تطابق الفلاتر الحالية.'      : 'No materials found for the current filters.';
  String get availabilityColumn => isArabic ? 'التوفر' : 'Availability';
  String get viewDetailsTooltip => isArabic ? 'عرض التفاصيل' : 'View details';
  String get deleteProductTooltip => isArabic ? 'حذف المادة' : 'Delete material';
  String get stockUpdated => isArabic ? 'تم تحديث المخزون بنجاح.' : 'Stock updated successfully.';
  String unitsDispatched(int units, String product) => isArabic      ? '$units وحدة من $product تم صرفها.'      : '$units units of $product dispatched.';
  String outOfStockWarning(int units, String product) => isArabic      ? '$units وحدة من $product تم صرفها. الصنف نفد من المخزون وتم تعليمه كـ "غير متاح".'      : '$units units of $product dispatched. Item is now out of stock and marked Unavailable.';
  String get editRequestSubmitted => isArabic      ? 'تم تقديم طلب تعديل تاريخ الانتهاء.'      : 'Edit request submitted.';
  String get awaitingApproval => isArabic ? 'بإنتظار موافقة المشرف.' : 'Awaiting supervisor approval.';
  String get deleteTitle => isArabic ? 'حذف المادة' : 'Delete Material';
  String deleteConfirmNamed(String name) => isArabic      ? 'هل أنت متأكد أنك تريد حذف "$name"؟'      : 'Are you sure you want to delete "$name"?';
  String productDeleted(String name) => isArabic      ? 'تم حذف $name بنجاح.'      : '$name deleted successfully.';
  String get undo => isArabic ? 'تراجع' : 'Undo';
  String get all => isArabic ? 'الكل' : 'All';
  String get ordersHistory => isArabic ? 'سجل الطلبات' : 'Orders History';
  String get filterByDate => isArabic ? 'تصفية حسب التاريخ' : 'Filter by Date';
  String get filterByStatus => isArabic ? 'تصفية حسب الحالة' : 'Filter by Status';
  String get editRequests => isArabic ? 'طلبات التعديل' : 'Edit Requests';
  String get noEditRequests => isArabic ? 'لا توجد طلبات تعديل' : 'No edit request notifications';
  String get goToOrders => isArabic ? 'انتقل إلى الطلبات' : 'Go to Orders';
  String get searchOrdersHint => isArabic      ? 'ابحث برقم الطلب أو المنتج أو الرمز...'      : 'Search by order ID, product, SKU, or user...';
  String get productNotInInventory => isArabic      ? 'المادة غير موجودة في المخزون.'      : 'Material not found in inventory.';
  String get reportsAndAnalytics => isArabic ? 'التقارير والتحليلات' : 'Reports & Analytics';
  String get exportReport => isArabic ? 'تصدير التقرير' : 'Export Report';
  String get alertsLabel => isArabic ? 'التنبيهات' : 'Alerts';
  String get accountSettings => isArabic ? 'إعدادات الحساب' : 'Account Settings';
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get personalInfo => isArabic ? 'المعلومات الشخصية' : 'Personal Information';
  String get saving => isArabic ? 'جارٍ الحفظ...' : 'Saving...';
  String get saveChanges => isArabic ? 'حفظ التغييرات' : 'Save Changes';
  String get privacySecurity => isArabic ? 'الخصوصية والأمان' : 'Privacy & Security';
  String get updateAvailable => isArabic ? 'يوجد تحديث متاح' : 'Update Available';
  String get installingUpdate => isArabic ? 'جارٍ تثبيت التحديث...' : 'Installing Update...';
  String get downloadingUpdate => isArabic ? 'جارٍ تنزيل التحديث...' : 'Downloading Update...';
  String get updateNow => isArabic ? 'تحديث الآن' : 'Update Now';
  String get maybeLater => isArabic ? 'ربما لاحقًا' : 'Maybe Later';
  String get whatsNew => isArabic ? 'ما الجديد:' : "What's new:";
  String get downloadUrlNotConfigured => isArabic      ? 'رابط التنزيل غير مهيأ.'      : 'Download URL not configured.';
    String get printingOrders => isArabic ? 'جارٍ طباعة الطلبات...' : 'Printing orders…';
  String get printingReport => isArabic ? 'جارٍ طباعة التقرير...' : 'Printing report…';
    String get thresholdSettings => isArabic ? 'إعدادات الحدود' : 'Threshold Settings';
  String get lowStockThreshold => isArabic ? 'حد المخزون المنخفض' : 'Low Stock Threshold';
  String get lowStockThresholdDesc => isArabic      ? 'الحد الأدنى للكمية الذي تعتبر عنده المادة منخفضة المخزون.'      : 'Minimum quantity below which a material is considered low-stock.';
  String get expiringSoonThreshold => isArabic ? 'أيام انتهاء الصلاحية الوشيك' : 'Expiring Soon Days';
  String get expiringSoonThresholdDesc => isArabic      ? 'عدد الأيام المتبقية قبل انتهاء الصلاحية لاعتبار المادة وشيكة الانتهاء.'      : 'Days remaining before expiry to consider a material as expiring soon.';
  String get settingsSaved => isArabic ? 'تم حفظ الإعدادات' : 'Settings saved';
    String get editApproved => isArabic ? 'تمت الموافقة على التعديل وتطبيقه.' : 'Edit approved and applied.';
  String get editRejected => isArabic ? 'تم رفض التعديل.' : 'Edit rejected.';
  String get rejectReasonHint => isArabic ? 'سبب الرفض' : 'Reason for rejection';
    String get selectMaterial => isArabic ? 'اختر المادة' : 'Select Material';
  String get existingStock => isArabic ? 'مخزون موجود' : 'Add to Existing Stock';
  String get newMaterial => isArabic ? 'مادة جديدة' : 'Add New Material';
  String get invoiceInfo => isArabic ? 'معلومات الفاتورة' : 'Invoice Information';
  String get quantityToAdd => isArabic ? 'الكمية المضافة' : 'Quantity to Add';
  String get currentInfo => isArabic ? 'المعلومات الحالية' : 'Current Information';
  String get materialsAdded => isArabic ? 'المواد المضافة في هذه الجلسة' : 'Materials Added in This Session';
  String get finishSaveAll => isArabic ? 'إنهاء وحفظ الكل' : 'Finish & Save All';
    String get auditLog => isArabic ? 'سجل التدقيق' : 'Audit Log';
  String get searchAuditLog => isArabic ? 'ابحث في سجل التدقيق...' : 'Search audit log...';
  String get noAuditLogs => isArabic ? 'لا توجد سجلات تدقيق' : 'No audit logs found';

  String get checkForUpdates => isArabic ? 'التحقق من التحديثات' : 'Check for Updates';
  String get upToDate => isArabic ? 'البرنامج محدث' : 'You\'re up to date';
  String get logoutConfirmMsg => isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to logout?';
  String get discardChanges => isArabic ? 'تجاهل التغييرات؟' : 'Discard changes?';
  String get discardChangesMsg => isArabic ? 'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد تجاهلها؟' : 'You have unsaved changes. Are you sure you want to discard them?';
  String get discard => isArabic ? 'تجاهل' : 'Discard';
  String get selectedMaterialDetails => isArabic ? 'تفاصيل المادة المحددة' : 'Selected Material Details';
  String get currentStock => isArabic ? 'المخزون الحالي' : 'Current Stock';
  String get extractingUpdate => isArabic ? 'جارٍ فتح حزمة التحديث...' : 'Extracting update package...';
  String get launchingInstaller => isArabic ? 'جارٍ تشغيل المثبت...' : 'Launching installer...';
  String get updateCheckFailed => isArabic ? 'تعذر التحقق من التحديثات. تحقق من اتصالك بالإنترنت.' : 'Failed to check for updates. Check your internet connection.';
  String noOfItems(int count) => isArabic ? '$count عنصر' : '$count items';
  String pageOf(int current, int total) => isArabic      ? 'صفحة $current من $total'      : 'Page $current of $total';
    String get addToDispatch => isArabic ? 'إضافة للصرف' : 'Add to Dispatch';
  String get finishDispatchAll => isArabic ? 'إنهاء وصرف الكل' : 'Finish & Dispatch All';
  String get itemsToDispatch => isArabic ? 'المواد المراد صرفها' : 'Items to Dispatch';
  String unitsDispatchedSummary(int totalQuantity, int itemCount) => isArabic      ? 'تم صرف $totalQuantity وحدة من $itemCount مادة'      : 'Dispatched $totalQuantity units across $itemCount items';

  // === ApprovalsView ===
  String get pendingApprovals => isArabic ? 'الموافقات المعلقة' : 'Pending Approvals';
  String get noPendingApprovals => isArabic ? 'لا توجد موافقات معلقة' : 'No pending approvals';
  String get requestApproved => isArabic ? 'تمت الموافقة على الطلب' : 'Request approved';
  String get rejectRequest => isArabic ? 'رفض الطلب' : 'Reject Request';
  String get rejectionNotes => isArabic ? 'ملاحظات الرفض (اختياري)' : 'Optional rejection notes';
  String get requestRejected => isArabic ? 'تم رفض الطلب' : 'Request rejected';
  String get batchId => isArabic ? 'معرف الدفعة' : 'Batch ID';
  String get oldExpiry => isArabic ? 'تاريخ الانتهاء القديم' : 'Old Expiry';
  String get requestExpiryChange => isArabic ? 'طلب تغيير تاريخ الانتهاء' : 'Request Expiry Change';

  // === EditRequestsView ===
  String get requestedBy => isArabic ? 'مقدم الطلب' : 'Requested By';
  String get source => isArabic ? 'المصدر' : 'Source';
  String get reason => isArabic ? 'السبب' : 'Reason';
  String get date => isArabic ? 'التاريخ' : 'Date';
  String get approved => isArabic ? 'مقبول' : 'Approved';
  String get rejected => isArabic ? 'مرفوض' : 'Rejected';
  String get approvalSource => isArabic ? 'موافقة' : 'Approval';
  String get orderSource => isArabic ? 'طلب' : 'Order';

  // === ExpiryReportView ===
  String get expiryReport => isArabic ? 'تقرير الصلاحية' : 'Expiry Report';
  String get noExpiryData => isArabic ? 'لا توجد بيانات صلاحية' : 'No expiry data available';
  String get valid => isArabic ? 'صالح' : 'Valid';

  // === InvoicesView ===
  String get invoiceDetails => isArabic ? 'تفاصيل الفاتورة' : 'Invoice Details';
  String get totalQuantity => isArabic ? 'الكمية الإجمالية' : 'Total Quantity';
  String get dateRange => isArabic ? 'النطاق الزمني' : 'Date Range';
  String get invoicesTitle => isArabic ? 'الفواتير' : 'Invoices';
  String get today => isArabic ? 'اليوم' : 'Today';
  String get thisWeek => isArabic ? 'هذا الأسبوع' : 'This Week';
  String get thisMonth => isArabic ? 'هذا الشهر' : 'This Month';
  String get thisYear => isArabic ? 'هذه السنة' : 'This Year';
  String get noInvoicesFound => isArabic ? 'لا توجد فواتير' : 'No invoices found';
  String get searchByInvoice => isArabic ? 'ابحث برقم الفاتورة...' : 'Search by invoice number...';
  String get materials => isArabic ? 'مواد' : 'Materials';
  String get units => isArabic ? 'وحدة' : 'units';
  String get refundLabel => isArabic ? 'استرجاع' : 'Refund';
  String get quantityToRefund => isArabic ? 'الكمية المسترجعة' : 'Quantity to refund';
  String get availableToRefund => isArabic ? 'متاح للاسترجاع' : 'Available to refund';
  String get enterValidQuantity => isArabic ? 'أدخل كمية صالحة' : 'Enter a valid quantity';
  String get cannotRefund => isArabic ? 'لا يمكن الاسترجاع: معرف المادة مفقود' : 'Cannot refund: product ID missing';
  String get refundFailed => isArabic ? 'فشل الاسترجاع' : 'Refund failed';
  String refundSuccess(int qty, String unit, String productName) => isArabic      ? 'تم استرجاع $qty $unit من $productName'      : 'Refunded $qty $unit of $productName';
  String refundFailedWithError(String error) => isArabic      ? 'فشل الاسترجاع: $error'      : 'Refund failed: $error';
  String get expPrefix => isArabic ? 'تاريخ الانتهاء: ' : 'EXP: ';
  String get invoiceHash => isArabic ? 'رقم الفاتورة: ' : 'Invoice #';
  String materialsCount(int count) => isArabic      ? '$count مواد'      : '$count materials';
  String totalUnits(int count) => isArabic      ? 'المجموع: $count وحدة'      : 'Total: $count units';

  // === OrdersView ===
  String get orderId => isArabic ? 'رقم الطلب' : 'Order ID';
  String get orderDate => isArabic ? 'تاريخ الطلب' : 'Order Date';

  // === ReportsPage ===
  String get allStatuses => isArabic ? 'جميع الحالات' : 'All Statuses';
  String get uncategorized => isArabic ? 'غير مصنف' : 'Uncategorized';

  // === UserInfo ===
  String get unableToUpdateProfile => isArabic ? 'تعذر تحديث الملف الشخصي' : 'Unable to update profile.';
  String get profileUpdated => isArabic ? 'تم تحديث الملف الشخصي بنجاح' : 'Profile updated successfully';
  String get privacyComingSoon => isArabic ? 'إعدادات الخصوصية قريبًا' : 'Privacy settings coming soon.';
  String get managerScope => isArabic ? 'النطاق: لوحة التحكم، المخزون، التقارير، الطلبات، الإعدادات' : 'Scope: Dashboard, Inventory, Reports, Orders, Settings';
  String get supervisorScope => isArabic ? 'النطاق: الطلبات والتقارير' : 'Scope: Orders and Reports';
  String get sendCode => isArabic ? 'إرسال الرمز' : 'Send Code';
  String get sendVerificationCode => isArabic ? 'إرسال رمز التحقق' : 'Send Verification Code';
  String get verifyCode => isArabic ? 'تحقق من الرمز' : 'Verify Code';
  String get sixDigitCode => isArabic ? 'رمز من 6 أرقام' : '6-digit code';
  String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New Password';
  String get resetNoEmail => isArabic ? 'لم يتم العثور على بريد إلكتروني مسجل' : 'No registered email address was found.';
  String get verificationCodeSent => isArabic ? 'تم إرسال رمز التحقق إلى بريدك الإلكتروني المسجل' : 'A verification code has been sent to your registered email address.';
  String get passwordMinChars => isArabic ? 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل' : 'New password must be at least 6 characters.';
  String get passwordChangedSuccess => isArabic ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully';
  String get requestFailedRetry => isArabic ? 'فشل الطلب. حاول مرة أخرى' : 'Request failed. Please try again.';

  // === AddMaterialWizard ===
  String get addToExistingDesc => isArabic ? 'إضافة إلى مادة موجودة في المخزون' : 'Add to existing material in stock';
  String get addNewDesc => isArabic ? 'إضافة مادة جديدة بالكامل' : 'Add a completely new material';
  String get hintMaterialName => isArabic ? 'مثال: باراسيتامول' : 'e.g. Paracetamol';
  String get hintUnitExamples => isArabic ? 'علبة، قرص، زجاجة' : 'Box, Tablet, Bottle';
  String get hintCategoryExample => isArabic ? 'مثال: مسكن ألم' : 'e.g. Pain Relief';
  String get hintLocationExample => isArabic ? 'مثال: الرف A-12' : 'e.g. Shelf A-12';
  String get pleaseSelectDate => isArabic ? 'من فضلك اختر تاريخًا' : 'Please select a date';

  // === BatchDetailDialog ===
  String get batchesLabel => isArabic ? 'الدفعات' : 'Batches';
  String get noStockBatches => isArabic ? 'لا توجد دفعات مخزون لهذه المادة' : 'No stock batches for this product.';
  String get totalStockLabel => isArabic ? 'إجمالي المخزون: ' : 'Total Stock: ';
  String get batchesFefoOrder => isArabic ? 'الدفعات (ترتيب FEFO)' : 'Batches (FEFO order)';
  String get expiredStatus => isArabic ? 'منتهي الصلاحية' : 'EXPIRED';
  String get expiringSoonStatus => isArabic ? 'ينتهي قريبًا' : 'Expiring soon';
  String get goodStatusLabel => isArabic ? 'جيد' : 'Good';
  String get editExpiry => isArabic ? 'تعديل تاريخ الانتهاء' : 'Edit Expiry';
  String get fefoInfo => isArabic ? 'FEFO: سيتم صرف الدفعة الأقرب للانتهاء أولاً.' : 'FEFO: Earliest expiry will be dispatched first.';

  // === ExpiryChangeDialog ===
  String get selectNewExpiry => isArabic ? 'من فضلك اختر تاريخ انتهاء جديد' : 'Please select a new expiry date';
  String get enterReason => isArabic ? 'من فضلك أدخل سببًا' : 'Please enter a reason';
  String get expiryChangeSubmitted => isArabic ? 'تم تقديم طلب تغيير تاريخ الانتهاء' : 'Expiry change request submitted';
  String get currentExpiry => isArabic ? 'تاريخ الانتهاء الحالي' : 'Current Expiry';
  String get tapToPickDate => isArabic ? 'اضغط لاختيار تاريخ' : 'Tap to pick a date';
  String get whyChangeNeeded => isArabic ? 'لماذا هذا التغيير مطلوب؟' : 'Why is this change needed?';
  String get submitRequest => isArabic ? 'إرسال الطلب' : 'Submit Request';

  // === ProductEditDialog ===
  String get materialNameRequired => isArabic ? 'اسم المادة مطلوب' : 'Material name is required';

  // === DispatchMaterialWizard ===
  String invoiceAlreadyExists(String invoice) => isArabic      ? 'رقم الفاتورة "$invoice" موجود بالفعل. استخدم رقمًا مختلفًا.'      : 'Invoice number "$invoice" already exists. Please use a different number.';

  // === DashboardView ===
  String get uncategorizedLabel => isArabic ? 'غير مصنف' : 'Uncategorized';
  String get name => isArabic ? 'الاسم' : 'Name';
  String get total => isArabic ? 'الإجمالي' : 'TOTAL';

  // === Phase 2 additions ===
  String get userManagement => isArabic ? 'إدارة المستخدمين' : 'User Management';
  String get categoriesManagement => isArabic ? 'إدارة الفئات' : 'Categories Management';
  String get contactsDirectory => isArabic ? 'دليل جهات الاتصال' : 'Contacts Directory';
  String get minStockLevelLabel => isArabic ? 'الحد الأدنى للمخزون' : 'Min Stock Level';
  String get disposal => isArabic ? 'إتلاف' : 'Disposal';
  String get recordDisposal => isArabic ? 'تسجيل إتلاف' : 'Record Disposal';
  String get disposalMethod => isArabic ? 'طريقة الإتلاف' : 'Disposal Method';
  String get recordDisposalTitle => isArabic ? 'إتلاف مواد منتهية الصلاحية' : 'Dispose Expired Materials';
  String get disposeExpiredUnitsTitle => isArabic ? 'إتلاف الوحدات منتهية الصلاحية' : 'Dispose Expired Units';
  String disposeConfirmMessage(String name) => isArabic
      ? 'هل أنت متأكد من رغبتك في إزالة جميع الوحدات منتهية الصلاحية لـ $name؟ هذا الإجراء يزيل فقط الدفعات المنتهية ولا يمكن التراجع عنه.'
      : 'Are you sure you want to remove all expired units for $name? This action only removes expired batches and cannot be undone.';
  String get disposeAction => isArabic ? 'إتلاف' : 'Dispose';
  String get disposalSuccess => isArabic ? 'تم إتلاف الوحدات المنتهية بنجاح.' : 'Expired units disposed successfully.';
  String get toggleStatus => isArabic ? 'تغيير الحالة' : 'Toggle Status';
  String get changeRole => isArabic ? 'تغيير الدور' : 'Change Role';
  String get resetPassword => isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get userStatusActive => isArabic ? 'نشط' : 'Active';
  String get userStatusInactive => isArabic ? 'غير نشط' : 'Inactive';
  String get enterMinStockLevel => isArabic ? 'أدخل الحد الأدنى للمخزون' : 'Enter Minimum Stock Level';
  String get createNewCategory => isArabic ? '+ إنشاء فئة جديدة' : '+ Create New Category';
  String get createCategory => isArabic ? 'إنشاء فئة' : 'Create Category';
  String get categoryName => isArabic ? 'اسم الفئة' : 'Category Name';
  String get createNewContact => isArabic ? '+ إضافة جهة اتصال' : '+ Add Contact';
  String get createContact => isArabic ? 'إضافة جهة اتصال' : 'Create Contact';
  String get contactName => isArabic ? 'الاسم' : 'Contact Name';
  String get contactType => isArabic ? 'النوع' : 'Contact Type';
  String get supplierLabel => isArabic ? 'مورد' : 'Supplier';
  String get recipientLabel => isArabic ? 'مستلم' : 'Recipient';

  // === Dashboard Refinement ===
  String get quickActions => isArabic ? 'إجراءات سريعة' : 'Quick Actions';
  String get stockHealth => isArabic ? 'حالة المخزون' : 'Stock Health';
  String get activityFeed => isArabic ? 'سجل النشاط' : 'Activity Feed';
  String get receiveStock => isArabic ? 'استلام مخزون' : 'Receive Stock';
  String get dispatch => isArabic ? 'صرف' : 'Dispatch';
  String get quickSearch => isArabic ? 'بحث سريع' : 'Quick Search';
  String get performStocktake => isArabic ? 'إجراء جرد' : 'Perform Stocktake';
  String get healthy => isArabic ? 'سليم' : 'Healthy';
  String get lowStock => isArabic ? 'مخزون منخفض' : 'Low Stock';
  String get outOfStockStatus => isArabic ? 'نفذ المخزون' : 'Out of Stock';
  String get stockHealthHealthy => isArabic ? 'المخزون في حالة جيدة' : 'Inventory is in good health';
  String get stockHealthWarning => isArabic ? 'انتبه: يوجد نقص في بعض الأصناف' : 'Attention: Some items are low in stock';
  String get stockHealthCritical => isArabic ? 'حرج: أصناف كثيرة نفدت أو انتهت' : 'Critical: Many items out of stock or expired';

  // === Operational Dashboard ===
  String get pendingApprovalsTitle => isArabic ? 'بانتظار الموافقة' : 'Pending Approvals';
  String get criticalShortages => isArabic ? 'نقص حاد في المخزون' : 'Critical Shortages';
  String get actionRequired => isArabic ? 'إجراء مطلوب' : 'Action Required';
  String get receivedToday => isArabic ? 'تم استلامه اليوم' : 'Received Today';
  String get dispatchedToday => isArabic ? 'تم صرفه اليوم' : 'Dispatched Today';
  String get viewAllApprovals => isArabic ? 'عرض جميع الموافقات' : 'View All Approvals';
  String get urgentActionDesc => isArabic ? 'أصناف تتطلب تدخلاً فورياً' : 'Items requiring immediate attention';
  String get systemFeed => isArabic ? 'سجل النظام المباشر' : 'System Feed';
  String get incomingStock => isArabic ? 'مخزون وارد' : 'Incoming Stock';
  String get outgoingStock => isArabic ? 'مخزون صادر' : 'Outgoing Stock';
}