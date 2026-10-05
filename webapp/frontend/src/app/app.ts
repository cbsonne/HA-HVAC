import { TranslatePipe } from './i18n.service';
import { Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { ApiService } from './api.service';
import { DialogService } from './dialog.service';
import { NAV_GROUPS, PAGES, pageCaption, pageFor } from './pages';
import { I18nService, LANGUAGES } from './i18n.service';

/** Rahmen der Anwendung: Kopfzeile mit Objekt, Navigationsleiste, Dialoge. */
@Component({
  selector: 'app-root',
  imports: [TranslatePipe, RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <header class="topbar">
      <a class="brand" routerLink="/">{{ 'app.brand' | t }}</a>
      <span class="object">{{ objectLine() }}</span>
      <span class="spacer"></span>
      <div class="jump">
        <input list="pagelist" [placeholder]="'app.searchPage' | t" #jump
          (keydown.enter)="go(jump.value); jump.value = ''" />
        <datalist id="pagelist">
          @for (p of allPages(); track p.id) {
            <option [value]="pageCaption(p.id)"></option>
          }
        </datalist>
      </div>
      <select class="langsel" (change)="i18n.use($any($event.target).value)" [title]="'app.language' | t">
        @for (l of languages; track l.code) {
          <option [value]="l.code" [selected]="l.code === i18n.lang()">{{ l.code.toUpperCase() }} · {{ l.name }}</option>
        }
      </select>
      <button class="topbtn" [title]="'app.reloadMetaHint' | t" (click)="refresh()">&#x21BB; {{ 'app.reloadMeta' | t }}</button>
      <span class="schema" [title]="'app.schema' | t">{{ api.schema() }}</span>
    </header>

    <div class="shell">
      <nav class="sidenav" [class.collapsed]="navCollapsed()">
        <button class="collapse" (click)="navCollapsed.set(!navCollapsed())">{{ navCollapsed() ? '&#x276F;' : '&#x276E;' }}</button>
        <a class="nav-item" routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">{{ 'app.roleCenter' | t }}</a>
        @for (g of groups(); track g.name) {
          <div class="nav-group">{{ 'group.' + g.name | t }}</div>
          @for (p of g.pages; track p.id) {
            <a class="nav-item" [routerLink]="['/list', p.id]" routerLinkActive="active">{{ pageCaption(p.id) }}</a>
          }
        }
      </nav>
      <main><router-outlet /></main>
    </div>

    @if (dialog.current(); as d) {
      <div class="modal-backdrop">
        <div class="modal" [class.error]="d.kind === 'error'">
          <h2>{{ d.title | t }}</h2>
          <pre class="modal-message">{{ d.message }}</pre>
          <div class="modal-buttons">
            @if (d.kind === 'confirm') {
              <button class="primary" (click)="dialog.close(true)">{{ 'common.yes' | t }}</button>
              <button (click)="dialog.close(false)">{{ 'common.no' | t }}</button>
            } @else {
              <button class="primary" (click)="dialog.close(true)">{{ 'action.ok' | t }}</button>
            }
          </div>
        </div>
      </div>
    }
  `,
})
export class App {
  readonly api = inject(ApiService);
  readonly dialog = inject(DialogService);
  readonly i18n = inject(I18nService);
  readonly languages = LANGUAGES;
  private router = inject(Router);

  readonly navCollapsed = signal(false);

  readonly allPages = computed(() => {
    const ids = new Set(Object.keys(this.api.tables()));
    const known = new Set(PAGES.map((p) => p.id));
    return [...PAGES.filter((p) => ids.has(p.id)), ...[...ids].filter((t) => !known.has(t)).map(pageFor)];
  });

  readonly groups = computed(() =>
    NAV_GROUPS.map((name) => ({ name, pages: this.allPages().filter((p) => p.group === name) })).filter((g) => g.pages.length),
  );

  readonly objectLine = computed(() => {
    const o = this.api.objekt()?.objects?.[0];
    if (!o) return '';
    const addr = [[o['street'], o['house_number']].filter(Boolean).join(' '), [o['postal_code'], o['city']].filter(Boolean).join(' ')]
      .filter(Boolean).join(', ');
    return [o['name'], addr].filter(Boolean).join(' · ');
  });

  go(caption: string) {
    const p = this.allPages().find((x) => pageCaption(x.id).toLowerCase() === caption.trim().toLowerCase());
    if (p) this.router.navigate(['/list', p.id]);
  }

  pageCaption(id: string) {
    return pageCaption(id);
  }

  async refresh() {
    await this.api.loadMeta(true);
    this.router.navigate([this.router.url], { skipLocationChange: true });
  }
}
