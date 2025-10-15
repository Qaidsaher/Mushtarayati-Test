// SQL migrations for local sqlite DB following the ER diagram
class Migrations {
  static const v1 = '''
  CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    last_price REAL DEFAULT 0,
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
    qty INTEGER,
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

  static const v3 = '''
  ALTER TABLE categories ADD COLUMN last_price REAL DEFAULT 0;

  DROP TABLE IF EXISTS items_tmp;
  CREATE TABLE IF NOT EXISTS items_tmp (
    id TEXT PRIMARY KEY,
    menu_id TEXT,
    category_id TEXT,
    qty INTEGER,
    unit_price REAL,
    total REAL,
    notes TEXT,
    updated_at INTEGER,
    deleted INTEGER DEFAULT 0
  );

  INSERT INTO items_tmp (id, menu_id, category_id, qty, unit_price, total, notes, updated_at, deleted)
    SELECT id, menu_id, category_id, CAST(qty AS INTEGER), unit_price, total, notes, updated_at, deleted FROM items;

  DROP TABLE items;
  ALTER TABLE items_tmp RENAME TO items;

  CREATE INDEX IF NOT EXISTS idx_items_menu ON items(menu_id);
  CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id);
  ''';
}
