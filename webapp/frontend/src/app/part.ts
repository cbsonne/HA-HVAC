import { TranslatePipe } from './i18n.service';
import { Component, computed, effect, inject, input, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from './api.service';
import { DialogService } from './dialog.service';
import { I18nService } from './i18n.service';
import { FieldComponent } from './field';
import { ColumnMeta, Row, TableMeta, keyParams } from './model';
import { PartDef, caption, pageFor } from './pages';

/**
 * Unterseite einer Karte ("Zeilen") oder Infobox rechts ("FactBox").
 * Zeigt die über part.link verknüpften Datensätze einer anderen Tabelle.
 */
@Component({
  selector: 'app-part',
  imports: [TranslatePipe, RouterLink, FieldComponent],
  template: `
    @let t = table();
    <section [class]="variant() === 'factbox' ? 'factbox' : 'part'">
      <header (click)="open.set(!open())">
        <span class="chev" [class.closed]="!open()">&#x276F;</span>
        <span class="title">{{ part().caption | t }}</span>
        @if (total() !== null) {
          <span class="badge">{{ total() }}</span>
        }
        <span class="spacer"></span>
        @if (open() && t) {
          @if (variant() === 'part' && !t.readOnly) {
            <button class="link" (click)="$event.stopPropagation(); newLine()">+ {{ 'action.new' | t }}</button>
          }
          <a class="link" (click)="$event.stopPropagation()" [routerLink]="['/list', part().page]" [queryParams]="filterParams()">{{ 'action.showAll' | t }}</a>
        }
      </header>
      @if (open()) {
        @if (!t) {
          <div class="empty">{{ 'msg.tableMissing' | t: { table: part().page } }}</div>
        } @else if (rows().length === 0) {
          <div class="empty">{{ 'common.noEntries' | t }}</div>
        } @else if (variant() === 'factbox' && rows().length === 1) {
          <dl class="fb-fields">
            @for (c of columns(); track c.name) {
              <dt>{{ cap(c.name) }}</dt>
              <dd><app-field [column]="c" [value]="rows()[0][c.name]" /></dd>
            }
          </dl>
        } @else {
          <table class="grid compact">
            <thead>
              <tr>
                @for (c of columns(); track c.name) {
                  <th [class.num]="isNum(c)">{{ cap(c.name) }}</th>
                }
                @if (variant() === 'part' && !t.readOnly) {
                  <th></th>
                }
              </tr>
            </thead>
            <tbody>
              @for (r of rows(); track $index) {
                <tr (dblclick)="openRow(r)">
                  @for (c of columns(); track c.name; let first = $first) {
                    <td [class.num]="isNum(c)">
                      @if (first) {
                        <a class="drill" (click)="openRow(r)"><app-field [column]="c" [value]="r[c.name]" /></a>
                      } @else {
                        <app-field [column]="c" [value]="r[c.name]" />
                      }
                    </td>
                  }
                  @if (variant() === 'part' && !t.readOnly) {
                    <td class="row-actions"><button class="icon" [title]="'action.deleteLine' | t" (click)="deleteRow(r)">&#x1F5D1;</button></td>
                  }
                </tr>
              }
            </tbody>
          </table>
        }
      }
    </section>
  `,
})
export class PartComponent {
  private api = inject(ApiService);
  private router = inject(Router);
  private dialog = inject(DialogService);
  private i18n = inject(I18nService);

  readonly part = input.required<PartDef>();
  readonly parent = input.required<Row>();
  readonly variant = input<'part' | 'factbox'>('part');

  readonly open = signal(true);
  readonly rows = signal<Row[]>([]);
  readonly total = signal<number | null>(null);

  readonly table = computed<TableMeta | undefined>(() => this.api.tables()[this.part().page]);

  readonly filters = computed(() => {
    const f: Record<string, string> = {};
    for (const [child, parentCol] of Object.entries(this.part().link)) f[child] = String(this.parent()[parentCol] ?? '');
    for (const col of this.part().emptyFilter ?? []) f[col] = '';
    return f;
  });

  readonly filterParams = computed(() => {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(this.filters())) out['f.' + k] = v;
    return out;
  });

  readonly columns = computed<ColumnMeta[]>(() => {
    const t = this.table();
    if (!t) return [];
    const linkCols = Object.keys(this.part().link);
    const wanted = this.part().columns ?? pageFor(t.name).listColumns;
    const cols = wanted
      ? wanted.map((n) => t.columns.find((c) => c.name === n)).filter((c): c is ColumnMeta => !!c)
      : t.columns.filter((c) => !linkCols.includes(c.name) && c.baseType !== 'text' && !(c.primaryKey && t.primaryKey.length === 1)).slice(0, 6);
    return cols;
  });

  constructor() {
    effect(() => {
      if (this.table() && this.parent()) this.load();
    });
  }

  load() {
    const p = this.part();
    const parent = this.parent();
    if (Object.values(p.link).some((pc) => parent[pc] === null || parent[pc] === undefined)) {
      this.rows.set([]);
      this.total.set(0);
      return;
    }
    if (Object.keys(p.link).some((c) => !this.table()!.columns.some((tc) => tc.name === c))) {
      this.rows.set([]);
      this.total.set(null);
      return;
    }
    this.api.list(p.page, { filters: this.filters(), sort: p.sort, desc: p.desc, size: p.limit ?? 100 }).subscribe({
      next: (r) => {
        this.rows.set(r.rows);
        this.total.set(r.total);
      },
      error: () => this.rows.set([]),
    });
  }

  openRow(r: Row) {
    const t = this.table()!;
    if (!t.primaryKey.length) return;
    this.router.navigate(['/card', t.name], { queryParams: { ...keyParams(t, r), returnUrl: this.router.url } });
  }

  newLine() {
    const prefill: Record<string, string> = { new: '1', returnUrl: this.router.url };
    for (const [child, parentCol] of Object.entries(this.part().link)) prefill['p.' + child] = String(this.parent()[parentCol]);
    this.router.navigate(['/card', this.part().page], { queryParams: prefill });
  }

  async deleteRow(r: Row) {
    const t = this.table()!;
    if (!(await this.dialog.confirm(this.i18n.t('msg.deleteLineConfirm')))) return;
    this.api.delete(t.name, keyParams(t, r)).subscribe({ next: () => this.load(), error: (e) => this.dialog.error(e) });
  }

  cap(n: string) {
    return caption(n);
  }

  isNum(c: ColumnMeta) {
    return ['numeric', 'integer', 'bigint', 'smallint', 'double precision', 'real'].includes(c.baseType) && !c.fkTable;
  }
}
