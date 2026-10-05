export interface ColumnMeta {
  name: string;
  position: number;
  baseType: string;
  fullType: string;
  nullable: boolean;
  defaultExpr: string | null;
  primaryKey: boolean;
  fkTable: string | null;
  fkColumn: string | null;
  enumValues: string[];
  comment: string | null;
}

export interface TableMeta {
  name: string;
  columns: ColumnMeta[];
  primaryKey: string[];
  displayColumn: string;
  hypertable: boolean;
  readOnly: boolean;
  references: { table: string; column: string }[];
  comment: string | null;
}

export type Row = Record<string, any>;

export interface Page {
  rows: Row[];
  total: number;
}

export interface LookupEntry {
  key: any;
  label: string | null;
}

export interface ObjektStatus {
  available: boolean;
  schema: string;
  objects: Row[];
}

export function isSerial(c: ColumnMeta): boolean {
  return !!c.defaultExpr && c.defaultExpr.startsWith('nextval(');
}

export function isNumeric(c: ColumnMeta): boolean {
  return ['numeric', 'integer', 'bigint', 'smallint', 'double precision', 'real'].includes(c.baseType);
}

export function isRequired(c: ColumnMeta): boolean {
  return !c.nullable && !c.defaultExpr;
}

export function maxLength(c: ColumnMeta): number | null {
  const m = /^(?:character varying|character)\((\d+)\)$/.exec(c.fullType);
  return m ? +m[1] : null;
}

/** Schlüssel eines Datensatzes als Query-Parameter "k.<spalte>". */
export function keyParams(t: TableMeta, row: Row): Record<string, string> {
  const out: Record<string, string> = {};
  for (const k of t.primaryKey) out['k.' + k] = String(row[k]);
  return out;
}
