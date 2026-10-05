import { TranslatePipe } from './i18n.service';
import { Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService } from './api.service';
import { DialogService } from './dialog.service';
import { I18nService } from './i18n.service';
import { FieldComponent } from './field';
import { normalizeNumber } from './format';
import { ColumnMeta, Row, TableMeta, isNumeric, isRequired, isSerial, keyParams } from './model';
import { AddressChangeComponent } from './address-change';
import { PartComponent } from './part';
import { FastTab, caption, cardCaption, pageCaption, pageFor } from './pages';

/** Kartenseite im BC-Stil: Inforegister (FastTabs), Zeilen-Unterseiten und Infoboxen rechts. */
@Component({
  selector: 'app-card-page',
  imports: [TranslatePipe, RouterLink, FieldComponent, PartComponent, AddressChangeComponent],
  template: `
    @let t = table();
    @if (!t) {
      <div class="page"><div class="notice">{{ 'msg.tableNotInSchema' | t: { table: page().id } }}</div></div>
    } @else if (record(); as r) {
      <div class="page with-factbox" [class.fb-hidden]="!showFactbox() || isNew()">
        <div class="page-main">
          <div class="page-head card-head">
            <button class="back" [title]="'action.back' | t" (click)="back()">&#x2190;</button>
            <div>
              <div class="subtitle">{{ cardCaption(page().id) }}</div>
              <h1>{{ title() }}</h1>
            </div>
            @if (dirty()) {
              <span class="state unsaved">{{ 'msg.unsaved' | t }}</span>
            } @else if (savedHint()) {
              <span class="state saved">{{ 'msg.saved' | t }}</span>
            }
          </div>
          <nav class="actionbar">
            @if (!t.readOnly) {
              @if (edit()) {
                <button class="primary" (click)="save()"><span class="ico">&#x1F4BE;</span> {{ 'action.save' | t }}</button>
                <button (click)="discard()"><span class="ico">&#x21B6;</span> {{ 'action.discard' | t }}</button>
              } @else {
                <button (click)="edit.set(true)"><span class="ico">&#x270E;</span> {{ 'action.edit' | t }}</button>
              }
              <button (click)="newRecord()"><span class="ico">+</span> {{ 'action.new' | t }}</button>
              @if (!isNew()) {
                <button (click)="remove()"><span class="ico">&#x1F5D1;</span> {{ 'action.delete' | t }}</button>
              }
            }
            @if (page().id === 'objects' && !isNew() && api.table('object_addresses')) {
              <span class="sep"></span>
              <button (click)="addressDialog.set(true)"><span class="ico">&#x1F3E0;</span> {{ 'action.changeAddress' | t }}</button>
            }
            @if (!isNew() && t.references.length) {
              <span class="sep"></span>
              <div class="menu">
                <button><span class="ico">&#x1F517;</span> {{ 'action.related' | t }} &#x25BE;</button>
                <div class="menu-items">
                  @for (ref of t.references; track ref.table + ref.column) {
                    <a [routerLink]="['/list', ref.table]" [queryParams]="refParams(ref)">{{ pageCaption(ref.table) }} ({{ cap(ref.column) }})</a>
                  }
                </div>
              </div>
            }
            <span class="spacer"></span>
            @if (!isNew()) {
              <button (click)="showFactbox.set(!showFactbox())" [class.active]="showFactbox()"><span class="ico">&#x2139;</span> {{ 'action.factbox' | t }}</button>
            }
          </nav>

          @for (tab of tabs(); track tab.caption) {
            <section class="fasttab">
              <header (click)="toggleTab(tab.caption)">
                <span class="chev" [class.closed]="closedTabs().has(tab.caption)">&#x276F;</span>
                <span class="title">{{ tab.caption | t }}</span>
                @if (closedTabs().has(tab.caption)) {
                  <span class="summary">{{ tabSummary(tab) }}</span>
                }
              </header>
              @if (!closedTabs().has(tab.caption)) {
                <div class="fields">
                  @for (c of tabColumns(tab); track c.name) {
                    <div class="field" [class.wide]="c.baseType === 'text'">
                      <label [class.required]="required(c)" [title]="c.comment ?? c.name">{{ cap(c.name) }}</label>
                      <div class="value">
                        <app-field [column]="c" [value]="r[c.name]" [editMode]="edit() && !lockedKey(c)" [isNew]="isNew()" (valueChange)="set(c.name, $event)" />
                      </div>
                    </div>
                  }
                </div>
              }
            </section>
          }

          @if (!isNew()) {
            @for (p of page().parts ?? []; track p.caption) {
              <app-part [part]="p" [parent]="r" variant="part" />
            }
          }
        </div>

        @if (showFactbox() && !isNew()) {
          <aside class="factbox-pane">
            @for (p of page().factboxes ?? []; track p.caption) {
              <app-part [part]="p" [parent]="r" variant="factbox" />
            }
            @if (t.references.length) {
              <section class="factbox">
                <header><span class="title">{{ 'common.usedIn' | t }}</span></header>
                <ul class="fb-links">
                  @for (ref of t.references; track ref.table + ref.column) {
                    <li><a [routerLink]="['/list', ref.table]" [queryParams]="refParams(ref)">{{ pageCaption(ref.table) }}</a> <small>{{ cap(ref.column) }}</small></li>
                  }
                </ul>
              </section>
            }
          </aside>
        }
      </div>
      @if (addressDialog()) {
        <app-address-change [objectId]="r['object_id']" (closed)="addressDialog.set(false); $event && reloadParts()" />
      }
    } @else {
      <div class="page"><div class="notice">{{ 'common.loading' | t }}</div></div>
    }
  `,
})
export class CardPageComponent {
  readonly api = inject(ApiService);
  private dialog = inject(DialogService);
  private i18n = inject(I18nService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  private params = toSignal(this.route.paramMap);
  private query = toSignal(this.route.queryParamMap);

  readonly page = computed(() => pageFor(this.params()?.get('page') ?? ''));
  readonly table = computed<TableMeta | undefined>(() => this.api.tables()[this.page().id]);
  readonly isNew = computed(() => this.query()?.get('new') === '1');

  readonly record = signal<Row | null>(null);
  private original: Row | null = null;
  readonly edit = signal(false);
  readonly dirty = signal(false);
  readonly savedHint = signal(false);
  readonly showFactbox = signal(true);
  readonly closedTabs = signal(new Set<string>());
  readonly addressDialog = signal(false);

  readonly title = computed(() => {
    const t = this.table();
    const r = this.record();
    if (!t || !r) return '';
    if (this.isNew()) return this.i18n.t('action.new');
    const d = r[t.displayColumn];
    return d !== null && d !== undefined && d !== '' ? String(d) : t.primaryKey.map((k) => r[k]).join(' · ');
  });

  /** Inforegister: aus der Seitendefinition, plus "Weitere Felder" für alle übrigen Spalten. */
  readonly tabs = computed<FastTab[]>(() => {
    const t = this.table();
    if (!t) return [];
    const defined = this.page().fastTabs ?? [];
    const used = new Set(defined.flatMap((f) => f.fields));
    // automatisch vergebene Schlüssel (Sequenzen) gehören nicht auf die Karte
    const rest = t.columns.filter((c) => !used.has(c.name) && !(c.primaryKey && isSerial(c))).map((c) => c.name);
    if (!defined.length) return [{ caption: 'tab.allgemein', fields: rest }];
    return rest.length ? [...defined, { caption: 'tab.weitere_felder', fields: rest }] : defined;
  });

  constructor() {
    effect(() => {
      const t = this.table();
      const qp = this.query();
      if (!t || !qp) return;
      untracked(() => this.load(t, qp));
    });
  }

  private load(t: TableMeta, qp: import('@angular/router').ParamMap) {
    this.savedHint.set(false);
    this.dirty.set(false);
    if (qp.get('new') === '1') {
      const r: Row = {};
      for (const c of t.columns) {
        const pre = qp.get('p.' + c.name);
        if (pre !== null) r[c.name] = pre;
        else if (c.baseType === 'boolean' && c.defaultExpr) r[c.name] = c.defaultExpr === 'true';
        else r[c.name] = null;
      }
      this.original = { ...r };
      this.record.set(r);
      this.edit.set(true);
      return;
    }
    const key: Record<string, string> = {};
    for (const k of qp.keys) if (k.startsWith('k.')) key[k] = qp.get(k)!;
    this.record.set(null);
    this.api.get(t.name, key).subscribe({
      next: (r) => {
        this.original = { ...r };
        this.record.set(r);
        this.edit.set(qp.get('edit') === '1' && !t.readOnly);
      },
      error: (e) => this.dialog.error(e).then(() => this.back()),
    });
  }

  set(col: string, v: any) {
    this.record.update((r) => ({ ...r!, [col]: v }));
    this.dirty.set(true);
    this.savedHint.set(false);
  }

  /** Bei zusammengesetzten Schlüsseln (Zuordnungstabellen) bleibt der Schlüssel nach dem Anlegen fest. */
  lockedKey(c: ColumnMeta) {
    const t = this.table()!;
    return !this.isNew() && c.primaryKey && (t.hypertable || isSerial(c));
  }

  required(c: ColumnMeta) {
    return isRequired(c) && !isSerial(c);
  }

  async save() {
    const t = this.table()!;
    const r = this.record()!;
    const missing = t.columns.filter((c) => this.required(c) && (r[c.name] === null || r[c.name] === undefined || r[c.name] === ''));
    if (missing.length) {
      await this.dialog.error(this.i18n.t('msg.requiredFields', { fields: missing.map((c) => caption(c.name)).join(', ') }));
      return;
    }
    const values: Row = {};
    for (const c of t.columns) {
      if (this.isNew() || r[c.name] !== this.original?.[c.name]) {
        values[c.name] = isNumeric(c) ? normalizeNumber(r[c.name]) : r[c.name];
      }
    }
    if (this.isNew()) {
      this.api.create(t.name, values).subscribe({
        next: (saved) => {
          this.dirty.set(false);
          const returnUrl = this.query()?.get('returnUrl');
          this.router.navigate(['/card', t.name], { queryParams: { ...keyParams(t, saved), ...(returnUrl ? { returnUrl } : {}) }, replaceUrl: true });
        },
        error: (e) => this.dialog.error(e),
      });
    } else {
      this.api.update(t.name, keyParams(t, this.original!), values).subscribe({
        next: (saved) => {
          this.original = { ...saved };
          this.record.set(saved);
          this.dirty.set(false);
          this.edit.set(false);
          this.savedHint.set(true);
          // Schlüssel geändert (z. B. Zuordnungstabelle) -> URL nachziehen
          this.router.navigate([], { queryParams: { ...keyParams(t, saved), edit: null }, queryParamsHandling: 'merge', replaceUrl: true });
        },
        error: (e) => this.dialog.error(e),
      });
    }
  }

  async discard() {
    if (this.dirty() && !(await this.dialog.confirm(this.i18n.t('msg.discardConfirm')))) return;
    if (this.isNew()) {
      this.back();
      return;
    }
    this.record.set({ ...this.original! });
    this.dirty.set(false);
    this.edit.set(false);
  }

  async remove() {
    const t = this.table()!;
    if (!(await this.dialog.confirm(this.i18n.t('msg.deleteRecordConfirm', { name: this.title() })))) return;
    this.api.delete(t.name, keyParams(t, this.original!)).subscribe({ next: () => this.back(true), error: (e) => this.dialog.error(e) });
  }

  async newRecord() {
    if (this.dirty() && !(await this.dialog.confirm(this.i18n.t('msg.discardUnsavedConfirm')))) return;
    this.router.navigate(['/card', this.page().id], { queryParams: { new: '1', returnUrl: this.query()?.get('returnUrl') } });
  }

  async back(force = false) {
    if (!force && this.dirty() && !(await this.dialog.confirm(this.i18n.t('msg.discardUnsavedConfirm')))) return;
    const returnUrl = this.query()?.get('returnUrl');
    this.router.navigateByUrl(returnUrl ?? `/list/${this.page().id}`);
  }

  reloadParts() {
    // Unterseiten neu laden, indem der Datensatz neu gesetzt wird
    this.record.set({ ...this.record()! });
  }

  toggleTab(c: string) {
    const s = new Set(this.closedTabs());
    s.has(c) ? s.delete(c) : s.add(c);
    this.closedTabs.set(s);
  }

  tabColumns(tab: FastTab): ColumnMeta[] {
    const t = this.table()!;
    return tab.fields.map((n) => t.columns.find((c) => c.name === n)).filter((c): c is ColumnMeta => !!c);
  }

  tabSummary(tab: FastTab) {
    const r = this.record()!;
    return this.tabColumns(tab)
      .filter((c) => c.baseType !== 'text' && r[c.name] !== null && r[c.name] !== undefined && r[c.name] !== '')
      .slice(0, 3)
      .map((c) => r[c.name])
      .join(' · ');
  }

  refParams(ref: { table: string; column: string }) {
    const t = this.table()!;
    const r = this.original;
    if (!r || ref.column.includes(',') || t.primaryKey.length !== 1) return {};
    return { ['f.' + ref.column]: r[t.primaryKey[0]] };
  }

  pageCaption(table: string) {
    return pageCaption(table);
  }

  cardCaption(table: string) {
    return cardCaption(table);
  }

  cap(n: string) {
    return caption(n);
  }
}
