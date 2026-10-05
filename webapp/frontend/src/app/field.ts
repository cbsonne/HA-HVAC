import { Component, computed, inject, input, output } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { RouterLink } from '@angular/router';
import { of, switchMap } from 'rxjs';
import { ApiService } from './api.service';
import { formatValue } from './format';
import { ColumnMeta, LookupEntry, isNumeric, isSerial, maxLength } from './model';
import { enumCaption } from './pages';
import { I18nService } from './i18n.service';

/** Ein Feld einer Kartenseite: Anzeige oder Eingabe passend zum Spaltentyp. */
@Component({
  selector: 'app-field',
  imports: [RouterLink],
  template: `
    @let c = column();
    @if (!editable()) {
      @if (c.fkTable && value() !== null && value() !== undefined) {
        <a class="drill" [routerLink]="['/card', c.fkTable]" [queryParams]="fkParams()">{{ display() }}</a>
      } @else if (c.baseType === 'boolean') {
        <span class="toggle" [class.on]="!!value()"><span></span></span>
      } @else {
        <span class="ro" [class.num]="numeric()">{{ display() }}</span>
      }
    } @else if (c.baseType === 'boolean') {
      <label class="toggle edit" [class.on]="!!value()">
        <input type="checkbox" [checked]="!!value()" (change)="emit($any($event.target).checked)" /><span></span>
      </label>
    } @else if (c.enumValues.length) {
      <select [value]="value() ?? ''" (change)="emit($any($event.target).value)">
        <option value=""></option>
        @for (e of c.enumValues; track e) {
          <option [value]="e" [selected]="e === value()">{{ enumCaption(e) }}</option>
        }
      </select>
    } @else if (c.fkTable) {
      <select (change)="emit($any($event.target).value)">
        <option value="" [selected]="value() === null || value() === undefined"></option>
        @for (o of lookup(); track o.key) {
          <option [value]="o.key" [selected]="sameKey(o.key)">{{ o.label ?? o.key }}</option>
        }
      </select>
    } @else if (c.baseType === 'text') {
      <textarea rows="3" [value]="value() ?? ''" (input)="emit($any($event.target).value)"></textarea>
    } @else if (c.baseType === 'date') {
      <input type="date" [value]="value() ?? ''" (input)="emit($any($event.target).value)" />
    } @else if (c.baseType.startsWith('timestamp')) {
      <input type="datetime-local" step="1" [value]="localDateTime()" (input)="emitDateTime($any($event.target).value)" />
    } @else {
      <input type="text" [class.num]="numeric()" [attr.inputmode]="numeric() ? 'decimal' : null"
        [attr.maxlength]="maxLen()" [value]="value() ?? ''" (input)="emit($any($event.target).value)" />
    }
  `,
})
export class FieldComponent {
  private api = inject(ApiService);
  private i18n = inject(I18nService);

  readonly column = input.required<ColumnMeta>();
  readonly value = input<any>();
  readonly editMode = input(false);
  readonly isNew = input(false);
  readonly valueChange = output<any>();

  readonly numeric = computed(() => isNumeric(this.column()));
  readonly maxLen = computed(() => maxLength(this.column()));
  readonly editable = computed(() => {
    const c = this.column();
    if (!this.editMode()) return false;
    return !(isSerial(c) && c.primaryKey);
  });

  readonly lookup = toSignal(
    toObservable(computed(() => this.column().fkTable)).pipe(switchMap((t) => (t ? this.api.lookup(t) : of([] as LookupEntry[])))),
    { initialValue: [] as LookupEntry[] },
  );

  readonly display = computed(() => {
    const c = this.column();
    const v = this.value();
    if (c.primaryKey && isSerial(c) && this.isNew()) return this.i18n.t('common.auto');
    if (c.fkTable && v !== null && v !== undefined) {
      const hit = this.lookup().find((o) => String(o.key) === String(v));
      return hit?.label ? `${hit.label}` : String(v);
    }
    return formatValue(c, v);
  });

  readonly fkParams = computed(() => ({ ['k.' + this.column().fkColumn]: this.value() }));

  readonly localDateTime = computed(() => {
    const v = this.value();
    if (!v) return '';
    const d = new Date(v);
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  });

  enumCaption(e: string) {
    return enumCaption(e);
  }

  sameKey(k: any) {
    const v = this.value();
    return v !== null && v !== undefined && String(k) === String(v);
  }

  emit(v: any) {
    this.valueChange.emit(v === '' ? null : v);
  }

  emitDateTime(v: string) {
    this.valueChange.emit(v ? new Date(v).toISOString() : null);
  }
}
