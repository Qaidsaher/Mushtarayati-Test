// SQL migrations for local sqlite DB following the ER diagram
class Migrations {
  static const v1 = '''
  CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    updated_at INTEGER,
    deleted INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS branches (
    id TEXT PRIMARY KEY,
    name TEXT,
    location TEXT,
    phone_number TEXT,
    updated_at INTEGER,
    deleted INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS menus (
    id TEXT PRIMARY KEY,
    name TEXT,
    date TEXT,
    user_id TEXT,
    branch_id TEXT,
    stationery_expenses REAL,
    transportation_expenses REAL,
    updated_at INTEGER,
    deleted INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS items (
    id TEXT PRIMARY KEY,
    menu_id TEXT,
    category_id TEXT,
    qty REAL,
    unit_price REAL,
    total REAL,
    notes TEXT,
    updated_at INTEGER,
    deleted INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS ops (
    id TEXT PRIMARY KEY,
    entity_type TEXT,
    entity_id TEXT,
    action TEXT,
    payload TEXT,
    updated_at INTEGER,
    synced INTEGER DEFAULT 0
  );
  ''';

  static const v2 = '''
  ALTER TABLE menus ADD COLUMN stationery_expenses REAL;
  ALTER TABLE menus ADD COLUMN transportation_expenses REAL;
  ''';
}
