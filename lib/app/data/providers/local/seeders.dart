import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// 🌱 Seeder لتعبئة جدول التصنيفات ببيانات الخضار والفواكه
class Seeders {
  static Future<void> seedCategories(Database db) async {
    // التحقق أولاً إذا كان الجدول يحتوي على بيانات مسبقًا
    final existing = await db.query('categories');
    if (existing.isNotEmpty) {
      print('✅ التصنيفات موجودة مسبقًا (${existing.length})، لن يتم التكرار.');
      return;
    }

    final uuid = const Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    final categories = [
      {'name': 'خيار', 'type': 'خضار'},
      {'name': 'كوسة', 'type': 'خضار'},
      {'name': 'ليمون', 'type': 'فاكهة'},
      {'name': 'ليمون بن زهير', 'type': 'فاكهة'},
      {'name': 'باذنجان', 'type': 'خضار'},
      {'name': 'فاصوليا', 'type': 'خضار'},
      {'name': 'طماطم', 'type': 'خضار'},
      {'name': 'حراق أخضر', 'type': 'خضار'},
      {'name': 'حراق أحمر', 'type': 'خضار'},
      {'name': 'بصل', 'type': 'خضار'},
      {'name': 'بصل أحمر', 'type': 'خضار'},
      {'name': 'بصل أبيض', 'type': 'خضار'},
      {'name': 'بصل أخضر', 'type': 'خضار'},
      {'name': 'كزبرة', 'type': 'خضار'},
      {'name': 'بقدونس', 'type': 'خضار'},
      {'name': 'كراث', 'type': 'خضار'},
      {'name': 'بزاليا', 'type': 'خضار'},
      {'name': 'جزر', 'type': 'خضار'},
      {'name': 'خس', 'type': 'خضار'},
      {'name': 'نعناع', 'type': 'خضار'},
      {'name': 'نعناع حبق', 'type': 'خضار'},
      {'name': 'فجل', 'type': 'خضار'},
      {'name': 'باميا', 'type': 'خضار'},
      {'name': 'بطاط', 'type': 'خضار'},
      {'name': 'بطاط صغير', 'type': 'خضار'},
      {'name': 'كوسة صغير', 'type': 'خضار'},
      {'name': 'ذرة', 'type': 'خضار'},
      {'name': 'ثوم', 'type': 'خضار'},
      {'name': 'ثوم محلي', 'type': 'خضار'},
      {'name': 'ثوم صيني', 'type': 'خضار'},
      {'name': 'ثوم مصري', 'type': 'خضار'},
      {'name': 'ثوم أثيوبي', 'type': 'خضار'},
      {'name': 'ثوم يمني', 'type': 'خضار'},
      {'name': 'تفاح سكري', 'type': 'فاكهة'},
      {'name': 'تفاح سوري', 'type': 'فاكهة'},
      {'name': 'تفاح لبناني', 'type': 'فاكهة'},
      {'name': 'تفاح أخضر', 'type': 'فاكهة'},
      {'name': 'تفاح أحمر', 'type': 'فاكهة'},
      {'name': 'موز كبير', 'type': 'فاكهة'},
      {'name': 'موز صغير', 'type': 'فاكهة'},
      {'name': 'برتقال عصير', 'type': 'فاكهة'},
      {'name': 'برتقال أبو صرة', 'type': 'فاكهة'},
      {'name': 'برتقال بلدي', 'type': 'فاكهة'},
      {'name': 'برتقال شموطي', 'type': 'فاكهة'},
      {'name': 'جوافة', 'type': 'فاكهة'},
      {'name': 'كيوي', 'type': 'فاكهة'},
      {'name': 'كمثرى', 'type': 'فاكهة'},
      {'name': 'كمثرى لبناني', 'type': 'فاكهة'},
      {'name': 'كمثرى مصري', 'type': 'فاكهة'},
      {'name': 'أناناس', 'type': 'فاكهة'},
      {'name': 'بطيخ', 'type': 'فاكهة'},
      {'name': 'شمام', 'type': 'فاكهة'},
      {'name': 'كرز', 'type': 'فاكهة'},
      {'name': 'مانجو', 'type': 'فاكهة'},
      {'name': 'مشمش', 'type': 'فاكهة'},
      {'name': 'توت', 'type': 'فاكهة'},
      {'name': 'عنب أبيض', 'type': 'فاكهة'},
      {'name': 'عنب أحمر', 'type': 'فاكهة'},
      {'name': 'عنب أسود', 'type': 'فاكهة'},
      {'name': 'جريب فروت', 'type': 'فاكهة'},
      {'name': 'دراق', 'type': 'فاكهة'},
      {'name': 'خوخ', 'type': 'فاكهة'},
      {'name': 'برقوق', 'type': 'فاكهة'},
      {'name': 'فراولة', 'type': 'فاكهة'},
      {'name': 'أفوكادو', 'type': 'فاكهة'},
      {'name': 'رمان', 'type': 'فاكهة'},
      {'name': 'ببايا', 'type': 'فاكهة'},
      {'name': 'جح', 'type': 'فاكهة'},
      {'name': 'كمكوات', 'type': 'فاكهة'},
      {'name': 'تمر سكري', 'type': 'فاكهة'},
      {'name': 'تمر خلاص', 'type': 'فاكهة'},
      {'name': 'تمر عجوة', 'type': 'فاكهة'},
      {'name': 'تمر برني', 'type': 'فاكهة'},
      {'name': 'تمر مبروم', 'type': 'فاكهة'},
      {'name': 'تمر صفري', 'type': 'فاكهة'},
      {'name': 'تمر روثانة', 'type': 'فاكهة'},
      {'name': 'تمر خلاص القصيم', 'type': 'فاكهة'},
      {'name': 'تمر نبوت', 'type': 'فاكهة'},
      {'name': 'تمر عجوة المدينة', 'type': 'فاكهة'},
      {'name': 'تمر تبرما', 'type': 'فاكهة'},
      {'name': 'تمر شقراء', 'type': 'فاكهة'},
      {'name': 'تمر صفري القصيم', 'type': 'فاكهة'},
      {'name': 'تمر سكري القصيم', 'type': 'فاكهة'},
      {'name': 'تمر نبوت سويكة', 'type': 'فاكهة'},
      {'name': 'تمر نبوت طويل', 'type': 'فاكهة'},
      {'name': 'تمر خضري', 'type': 'فاكهة'},
    ];

    // استخدام transaction لتحسين السرعة
    await db.transaction((txn) async {
      for (final c in categories) {
        await txn.insert(
          'categories',
          {
            'id': uuid.v4(),
            'name': c['name'],
            'type': c['type'],
            'updated_at': now,
            'deleted': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    print('🌱 تمت إضافة ${categories.length} تصنيفًا بنجاح ✅');
  }
}
