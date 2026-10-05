import { TranslatePipe } from './i18n.service';
import { Component, computed, inject, input, output, signal } from '@angular/core';
import { ApiService } from './api.service';
import { DialogService } from './dialog.service';
import { I18nService } from './i18n.service';
import { FieldComponent } from './field';
import { ColumnMeta, Row } from './model';
import { caption } from './pages';

/**
 * Aktion "Adresse ändern": beendet die aktuelle Adresse zum Vortag von "Gültig ab"
 * und legt die neue Adresse an. Für reine Tippfehler die Adresse in der Adresshistorie direkt korrigieren.
 */
@Component({
  selector: 'app-address-change',
  imports: [TranslatePipe, FieldComponent],
  template: `
    <div class="modal-backdrop">
      <div class="modal wide">
        <h2>{{ 'action.changeAddress' | t }}</h2>
        <p class="hint">{{ 'msg.changeAddressHint' | t }}</p>
        <div class="fields">
          @for (c of columns(); track c.name) {
            <div class="field">
              <label [class.required]="c.name === 'valid_from'">{{ cap(c.name) }}</label>
              <div class="value"><app-field [column]="c" [value]="values()[c.name]" [editMode]="true" (valueChange)="set(c.name, $event)" /></div>
            </div>
          }
        </div>
        <div class="modal-buttons">
          <button class="primary" [disabled]="busy()" (click)="ok()">{{ 'action.ok' | t }}</button>
          <button (click)="closed.emit(false)">{{ 'action.cancel' | t }}</button>
        </div>
      </div>
    </div>
  `,
})
export class AddressChangeComponent {
  private api = inject(ApiService);
  private dialog = inject(DialogService);
  private i18n = inject(I18nService);

  readonly objectId = input.required<any>();
  readonly closed = output<boolean>();

  readonly busy = signal(false);
  readonly values = signal<Row>({ valid_from: new Date().toISOString().substring(0, 10), country_code: 'PT' });

  readonly columns = computed<ColumnMeta[]>(() => {
    const t = this.api.table('object_addresses');
    if (!t) return [];
    const order = ['valid_from', 'street', 'house_number', 'postal_code', 'city', 'district', 'country_code', 'latitude', 'longitude', 'note'];
    const known = order.map((n) => t.columns.find((c) => c.name === n)).filter((c): c is ColumnMeta => !!c);
    const extra = t.columns.filter((c) => !order.includes(c.name) && !['address_id', 'object_id', 'valid_to'].includes(c.name));
    return [...known, ...extra];
  });

  set(col: string, v: any) {
    this.values.update((r) => ({ ...r, [col]: v }));
  }

  ok() {
    if (!this.values()['valid_from']) {
      this.dialog.error(this.i18n.t('msg.validFromRequired'));
      return;
    }
    this.busy.set(true);
    this.api.changeAddress(this.objectId(), this.values()).subscribe({
      next: () => {
        this.busy.set(false);
        this.closed.emit(true);
      },
      error: (e) => {
        this.busy.set(false);
        this.dialog.error(e);
      },
    });
  }

  cap(n: string) {
    return caption(n);
  }
}
