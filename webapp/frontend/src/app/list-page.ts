import { TranslatePipe } from './i18n.service';
import { Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService } from './api.service';
import { DialogService } from './dialog.service';
import { I18nService } from './i18n.service';
import { FieldComponent } from './field';
import { ColumnMeta, Row, TableMeta, isNumeric, keyParams } from './model';
import { caption, pageCaption, pageFor } from './pages';

/** Listenseite im BC-Stil: Aktionsleiste, Suche, Filterbereich, Raster und FactBox mit Details. */
@Component({
  selector: 'app-list-page',
  imports: [TranslatePipe, RouterLink, FieldComponent],
  template: `
    @let t = table();
    @if (!t) {
      @if (page().id === 'objects' || page().id === 'object_addresses') {
        <div class="page"><div class="notice">
          <b>{{ 'msg.objectsMissingTitle' | t }}</b><br />
          {{ 'msg.objectsMissingText' | t: { file: 'db/proposed/001_objekt_adresse.sql' } }}
        </div></div>
      } @else {
        <div class="page"><div class="notice">{{ 'msg.tableNotInSchema' | t: { table: page().id } }}</div></div>
      }
    } @else {
      <div class="page with-factbox" [class.fb-hidden]="!showFactbox()">
        <div class="page-main">
          <div class="page-head">
            <h1>{{ pageCaption(page().id) }}</h1>
            <div class="search">
              <span>&#x1F50D;</span>
              <input [placeholder]="'action.search' | t" [value]="q()" (input)="q.set($any($event.target).value)" />
            </div>
          </div>
          <nav class="actionbar">
            @if (!t.readOnly) {
              <button (click)="newRecord()"><span class="ico">+</span> {{ 'action.new' | t }}</button>
              <button [disabled]="!selected()" (click)="openSelected(true)"><span class="ico">&#x270E;</span> {{ 'action.edit' | t }}</button>
            }
            <button [disabled]="!selected()" (click)="openSelected(false)"><span class="ico">&#x1F441;</span> {{ 'action.view' | t }}</button>
            @if (!t.readOnly) {
              <button [disabled]="!selected()" (click)="deleteSelected()"><span class="ico">&#x1F5D1;</span> {{ 'action.delete' | t }}</button>
            }
            <span class="sep"></span>
            @if (t.references.length) {
              <div class="menu">
                <button [disabled]="!selected()"><span class="ico">&#x1F517;</span> {{ 'action.related' | t }} &#x25BE;</button>
                @if (selected()) {
                  <div class="menu-items">
                    @for (r of t.references; track r.table + r.column) {
                      <a [routerLink]="['/list', r.table]" [queryParams]="refParams(r)">{{ pageCaption(r.table) }} ({{ cap(r.column) }})</a>
                    }
                  </div>
                }
              </div>
            }
            <button (click)="reload()"><span class="ico">&#x21BB;</span> {{ 'action.refresh' | t }}</button>
            <span class="spacer"></span>
            <button (click)="showFilter.set(!showFilter())" [class.active]="showFilter()"><span class="ico">&#x2A0D;</span> {{ 'action.filter' | t }}</button>
            <button (click)="showFactbox.set(!showFactbox())" [class.active]="showFactbox()"><span class="ico">&#x2139;</span> {{ 'action.factbox' | t }}</button>
          </nav>

          @if (activeFilters().length || showFilter()) {
            <div class="filterbar">
              @for (f of activeFilters(); track f.col) {
                <span class="chip">{{ cap(f.col) }}: <b>{{ f.label }}</b> <button (click)="removeFilter(f.col)">&#x2715;</button></span>
              }
              @if (showFilter()) {
                <select #fc>
                  @for (c of t.columns; track c.name) {
                    <option [value]="c.name">{{ cap(c.name) }}</option>
                  }
                </select>
                <input #fv [placeholder]="'msg.filterValueHint' | t" (keydown.enter)="addFilter(fc.value, fv.value); fv.value = ''" />
                <button class="link" (click)="addFilter(fc.value, fv.value); fv.value = ''">{{ 'action.addFilter' | t }}</button>
              }
            </div>
          }

          <div class="grid-wrap">
            <table class="grid">
              <thead>
                <tr>
                  @for (c of columns(); track c.name) {
                    <th [class.num]="num(c)" (click)="toggleSort(c.name)">
                      {{ cap(c.name) }}
                      @if (sort() === c.name) {
                        <span class="sort">{{ desc() ? '↓' : '↑' }}</span>
                      }
                    </th>
                  }
                </tr>
              </thead>
              <tbody>
                @for (r of rows(); track $index) {
                  <tr [class.selected]="r === selected()" (click)="selected.set(r)" (dblclick)="selected.set(r); openSelected(false)">
                    @for (c of columns(); track c.name; let first = $first) {
                      <td [class.num]="num(c)">
                        @if (first && t.primaryKey.length) {
                          <a class="drill" (click)="selected.set(r); openSelected(false)"><app-field [column]="c" [value]="r[c.name]" /></a>
                        } @else {
                          <app-field [column]="c" [value]="r[c.name]" />
                        }
                      </td>
                    }
                  </tr>
                } @empty {
                  <tr><td class="empty" [attr.colspan]="columns().length">{{ (loading() ? 'common.loading' : 'common.noRecords') | t }}</td></tr>
                }
              </tbody>
            </table>
          </div>
          <div class="grid-footer">
            {{ 'msg.recordCount' | t: { shown: rows().length, total: total() } }}
            @if (rows().length < total()) {
              <button class="link" (click)="more()">{{ 'action.loadMore' | t }}</button>
            }
          </div>
        </div>

        @if (showFactbox()) {
          <aside class="factbox-pane">
            <section class="factbox">
              <header><span class="title">{{ 'common.details' | t }}</span></header>
              @if (selected(); as s) {
                <dl class="fb-fields">
                  @for (c of t.columns; track c.name) {
                    <dt>{{ cap(c.name) }}</dt>
                    <dd><app-field [column]="c" [value]="s[c.name]" /></dd>
                  }
                </dl>
              } @else {
                <div class="empty">{{ 'msg.selectRow' | t }}</div>
              }
            </section>
            @if (selected() && t.references.length) {
              <section class="factbox">
                <header><span class="title">{{ 'common.usedIn' | t }}</span></header>
                <ul class="fb-links">
                  @for (r of t.references; track r.table + r.column) {
                    <li><a [routerLink]="['/list', r.table]" [queryParams]="refParams(r)">{{ pageCaption(r.table) }}</a> <small>{{ cap(r.column) }}</small></li>
                  }
                </ul>
              </section>
            }
          </aside>
        }
      </div>
    }
  `,
})
export class ListPageComponent {
  private api = inject(ApiService);
  private dialog = inject(DialogService);
  private i18n = inject(I18nService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  private params = toSignal(this.route.paramMap);
  private query = toSignal(this.route.queryParamMap);

  readonly page = computed(() => pageFor(this.params()?.get('page') ?? ''));
  readonly table = computed<TableMeta | undefined>(() => this.api.tables()[this.page().id]);

  readonly filters = computed(() => {
    const f: Record<string, string> = {};
    const qp = this.query();
    for (const k of qp?.keys ?? []) if (k.startsWith('f.')) f[k.substring(2)] = qp!.get(k) ?? '';
    return f;
  });

  readonly q = signal('');
  readonly sort = signal<string | undefined>(undefined);
  readonly desc = signal(false);
  readonly rows = signal<Row[]>([]);
  readonly total = signal(0);
  readonly loading = signal(false);
  readonly selected = signal<Row | null>(null);
  readonly showFilter = signal(false);
  readonly showFactbox = signal(true);
  private pageNo = 0;
  private searchTimer: any;

  readonly columns = computed<ColumnMeta[]>(() => {
    const t = this.table();
    if (!t) return [];
    const wanted = this.page().listColumns;
    if (wanted) return wanted.map((n) => t.columns.find((c) => c.name === n)).filter((c): c is ColumnMeta => !!c);
    return t.columns.filter((c) => c.baseType !== 'text' && !(c.primaryKey && t.primaryKey.length === 1 && t.displayColumn !== c.name)).slice(0, 9);
  });

  readonly activeFilters = computed(() => Object.entries(this.filters()).map(([col, v]) => ({ col, label: v === '' ? this.i18n.t('common.empty') : v })));

  constructor() {
    effect(() => {
      // bei Seitenwechsel Sortierung zurücksetzen
      const p = this.page();
      untracked(() => {
        this.sort.set(p.sort);
        this.desc.set(!!p.desc);
        this.q.set('');
      });
    });
    effect(() => {
      this.table();
      this.filters();
      this.sort();
      this.desc();
      const q = this.q();
      clearTimeout(this.searchTimer);
      this.searchTimer = setTimeout(() => untracked(() => this.reload()), q ? 250 : 0);
    });
  }

  reload() {
    this.pageNo = 0;
    this.fetch(false);
  }

  more() {
    this.pageNo++;
    this.fetch(true);
  }

  private fetch(append: boolean) {
    const t = this.table();
    if (!t) return;
    this.loading.set(true);
    this.api.list(t.name, { filters: this.filters(), q: this.q(), sort: this.sort(), desc: this.desc(), page: this.pageNo, size: 50 }).subscribe({
      next: (p) => {
        this.rows.set(append ? [...this.rows(), ...p.rows] : p.rows);
        this.total.set(p.total);
        this.loading.set(false);
        if (!append) this.selected.set(p.rows[0] ?? null);
      },
      error: (e) => {
        this.loading.set(false);
        this.dialog.error(e);
      },
    });
  }

  toggleSort(col: string) {
    if (this.sort() === col) this.desc.set(!this.desc());
    else {
      this.sort.set(col);
      this.desc.set(false);
    }
  }

  addFilter(col: string, value: string) {
    this.router.navigate([], { queryParams: { ['f.' + col]: value }, queryParamsHandling: 'merge' });
  }

  removeFilter(col: string) {
    this.router.navigate([], { queryParams: { ['f.' + col]: null }, queryParamsHandling: 'merge' });
  }

  newRecord() {
    const qp: Record<string, string> = { new: '1', returnUrl: this.router.url };
    for (const [k, v] of Object.entries(this.filters())) if (v !== '') qp['p.' + k] = v;
    this.router.navigate(['/card', this.page().id], { queryParams: qp });
  }

  openSelected(edit: boolean) {
    const t = this.table();
    const s = this.selected();
    if (!t || !s || !t.primaryKey.length) return;
    this.router.navigate(['/card', t.name], { queryParams: { ...keyParams(t, s), ...(edit ? { edit: '1' } : {}), returnUrl: this.router.url } });
  }

  async deleteSelected() {
    const t = this.table();
    const s = this.selected();
    if (!t || !s) return;
    if (!(await this.dialog.confirm(this.i18n.t('msg.deleteRecordConfirm', { name: s[t.displayColumn] ?? '' })))) return;
    this.api.delete(t.name, keyParams(t, s)).subscribe({ next: () => this.reload(), error: (e) => this.dialog.error(e) });
  }

  refParams(r: { table: string; column: string }) {
    const t = this.table()!;
    const s = this.selected();
    // nur einspaltige Bezüge lassen sich direkt filtern
    if (!s || r.column.includes(',') || t.primaryKey.length !== 1) return {};
    return { ['f.' + r.column]: s[t.primaryKey[0]] };
  }

  pageCaption(table: string) {
    return pageCaption(table);
  }

  cap(n: string) {
    return caption(n);
  }

  num(c: ColumnMeta) {
    return isNumeric(c) && !c.fkTable;
  }
}
