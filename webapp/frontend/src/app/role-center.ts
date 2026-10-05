import { TranslatePipe } from './i18n.service';
import { Component, computed, effect, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin, of, catchError } from 'rxjs';
import { ApiService } from './api.service';
import { FieldComponent } from './field';
import { Row } from './model';
import { NAV_GROUPS, PAGES, caption, pageCaption, pageFor } from './pages';

interface Cue {
  page: string;
  caption: string;
  count: number | null;
}

const CUE_PAGES = ['rooms', 'sensors', 'actuators', 'bus_devices', 'room_connections', 'simulation_scenarios', 'solver_runs', 'air_quality_corridors'];

/** Rollencenter: Objektkopf, Stapel (Cues) mit Anzahlen und Schnellzugriff auf alle Bereiche. */
@Component({
  selector: 'app-role-center',
  imports: [TranslatePipe, RouterLink, FieldComponent],
  template: `
    <div class="page role-center">
      <div class="rc-headline">
        <h1>{{ 'app.title' | t }}</h1>
        @if (obj(); as o) {
          <div class="rc-object">
            <div class="rc-object-name"><a [routerLink]="['/card', 'objects']" [queryParams]="{ 'k.object_id': o['object_id'] }">{{ o['object_no'] }} · {{ o['name'] }}</a></div>
            <div>{{ address(o) || ('msg.noAddress' | t) }}</div>
            @if (o['valid_from']) {
              <small>{{ 'msg.validSince' | t: { date: o['valid_from'] } }}</small>
            }
          </div>
        } @else if (api.objekt() && !api.objekt()!.available) {
          <div class="notice">
            <b>{{ 'msg.objectsMissingTitle' | t }}</b>
            {{ 'msg.objectsMissingText' | t: { file: 'db/proposed/001_objekt_adresse.sql' } }}
          </div>
        }
      </div>

      <h2 class="rc-section">{{ 'rc.activities' | t }}</h2>
      <div class="cues">
        @for (c of cues(); track c.page) {
          <a class="cue" [routerLink]="['/list', c.page]">
            <span class="cue-caption">{{ c.caption }}</span>
            <span class="cue-count">{{ c.count ?? '–' }}</span>
          </a>
        }
      </div>

      <div class="rc-columns">
        <section class="part">
          <header><span class="title">{{ 'rc.latestValues' | t }}</span><span class="spacer"></span>
            <a class="link" [routerLink]="['/list', 'sensor_values']">{{ 'action.showAll' | t }}</a></header>
          @if (latest().length) {
            <table class="grid compact">
              <thead><tr><th>{{ cap('timestamp') }}</th><th>{{ cap('sensor_id') }}</th><th>{{ cap('measurement_definition_id') }}</th><th class="num">{{ cap('value') }}</th></tr></thead>
              <tbody>
                @for (r of latest(); track $index) {
                  <tr>
                    <td><app-field [column]="col('sensor_values', 'timestamp')" [value]="r['timestamp']" /></td>
                    <td><app-field [column]="col('sensor_values', 'sensor_id')" [value]="r['sensor_id']" /></td>
                    <td><app-field [column]="col('sensor_values', 'measurement_definition_id')" [value]="r['measurement_definition_id']" /></td>
                    <td class="num"><app-field [column]="col('sensor_values', 'value')" [value]="r['value']" /></td>
                  </tr>
                }
              </tbody>
            </table>
          } @else {
            <div class="empty">{{ 'common.noEntries' | t }}</div>
          }
        </section>

        <section class="part">
          <header><span class="title">{{ 'rc.allAreas' | t }}</span></header>
          <div class="rc-links">
            @for (g of groups(); track g.name) {
              <div>
                <h3>{{ 'group.' + g.name | t }}</h3>
                @for (p of g.pages; track p.id) {
                  <a [routerLink]="['/list', p.id]">{{ pageCaption(p.id) }}</a>
                }
              </div>
            }
          </div>
        </section>
      </div>
    </div>
  `,
})
export class RoleCenterComponent {
  readonly api = inject(ApiService);
  readonly cues = signal<Cue[]>([]);
  readonly latest = signal<Row[]>([]);

  readonly obj = computed(() => this.api.objekt()?.objects?.[0] ?? null);

  readonly groups = computed(() => {
    const tables = this.api.tables();
    const ids = new Set(Object.keys(tables));
    const known = new Set(PAGES.map((p) => p.id));
    const all = [...PAGES.filter((p) => ids.has(p.id)), ...[...ids].filter((t) => !known.has(t)).map(pageFor)];
    return NAV_GROUPS.map((name) => ({ name, pages: all.filter((p) => p.group === name) })).filter((g) => g.pages.length);
  });

  constructor() {
    effect(() => {
      const tables = this.api.tables();
      const pages = CUE_PAGES.filter((p) => tables[p]);
      if (!pages.length) return;
      forkJoin(pages.map((p) => this.api.count(p).pipe(catchError(() => of(null))))).subscribe((counts) =>
        this.cues.set(pages.map((p, i) => ({ page: p, caption: pageCaption(p), count: counts[i] }))),
      );
      if (tables['sensor_values']) {
        this.api.list('sensor_values', { sort: 'timestamp', desc: true, size: 10 }).subscribe({ next: (p) => this.latest.set(p.rows), error: () => {} });
      }
    });
  }

  col(table: string, name: string) {
    return this.api.tables()[table].columns.find((c) => c.name === name)!;
  }

  cap(n: string) {
    return caption(n);
  }

  pageCaption(id: string) {
    return pageCaption(id);
  }

  address(o: Row) {
    const line1 = [o['street'], o['house_number']].filter(Boolean).join(' ');
    const line2 = [o['postal_code'], o['city']].filter(Boolean).join(' ');
    return [line1, line2, o['country_code']].filter(Boolean).join(', ');
  }
}
