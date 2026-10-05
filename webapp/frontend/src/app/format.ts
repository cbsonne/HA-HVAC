import { i18n } from './i18n.service';
import { ColumnMeta, isNumeric } from './model';
import { enumCaption } from './pages';

const cache = new Map<string, { num: Intl.NumberFormat; dateTime: Intl.DateTimeFormat; date: Intl.DateTimeFormat }>();

function formats() {
  const locale = i18n.locale();
  let f = cache.get(locale);
  if (!f) {
    f = {
      num: new Intl.NumberFormat(locale, { maximumFractionDigits: 6 }),
      dateTime: new Intl.DateTimeFormat(locale, { dateStyle: 'short', timeStyle: 'medium' }),
      date: new Intl.DateTimeFormat(locale, { dateStyle: 'short' }),
    };
    cache.set(locale, f);
  }
  return f;
}

/** Anzeige eines Werts im Format der gewählten Sprache. */
export function formatValue(c: ColumnMeta | undefined, v: any): string {
  if (v === null || v === undefined || v === '') return '';
  if (!c) return String(v);
  if (c.baseType === 'boolean') return i18n.t(v ? 'common.yes' : 'common.no');
  if (c.enumValues.length) return enumCaption(String(v));
  if (isNumeric(c) && !c.primaryKey && !c.fkTable) return formats().num.format(Number(v));
  if (c.baseType.startsWith('timestamp')) return formats().dateTime.format(new Date(v));
  if (c.baseType === 'date') return formats().date.format(new Date(v + 'T00:00:00'));
  return String(v);
}

/**
 * Zahleneingabe normalisieren. Komma gilt als Dezimaltrenner, wenn die Sprache das so vorsieht
 * (de, pt: "1.234,5"); in Englisch ist das Komma Tausendertrenner ("1,234.5").
 */
export function normalizeNumber(v: any): any {
  if (typeof v !== 'string') return v;
  const t = v.trim();
  const decimalComma = formats().num.format(1.5).includes(',');
  if (decimalComma) return t.includes(',') ? t.replace(/\./g, '').replace(',', '.') : t;
  return t.replace(/,/g, '');
}
