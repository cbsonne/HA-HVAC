import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, firstValueFrom, map, shareReplay } from 'rxjs';
import { LookupEntry, ObjektStatus, Page, Row, TableMeta } from './model';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private lookups = new Map<string, Observable<LookupEntry[]>>();

  readonly schema = signal('');
  readonly tables = signal<Record<string, TableMeta>>({});
  readonly objekt = signal<ObjektStatus | null>(null);
  /** Fehler beim Start (Backend oder Datenbank nicht erreichbar); sonst null. */
  readonly loadError = signal<string | null>(null);

  async loadMeta(refresh = false): Promise<void> {
    const req = refresh
      ? this.http.post<{ schema: string; tables: TableMeta[] }>('/api/meta/refresh', {})
      : this.http.get<{ schema: string; tables: TableMeta[] }>('/api/meta');
    const m = await firstValueFrom(req);
    const byName: Record<string, TableMeta> = {};
    for (const t of m.tables) byName[t.name] = t;
    this.schema.set(m.schema);
    this.tables.set(byName);
    this.lookups.clear();
    await this.loadObjekt();
  }

  async loadObjekt(): Promise<void> {
    this.objekt.set(await firstValueFrom(this.http.get<ObjektStatus>('/api/objekt/status')));
  }

  table(name: string): TableMeta | undefined {
    return this.tables()[name];
  }

  list(table: string, opts: { filters?: Record<string, string>; q?: string; sort?: string; desc?: boolean; page?: number; size?: number }): Observable<Page> {
    let p = new HttpParams();
    for (const [k, v] of Object.entries(opts.filters ?? {})) p = p.set('f.' + k, v);
    if (opts.q) p = p.set('q', opts.q);
    if (opts.sort) p = p.set('sort', opts.sort).set('desc', String(!!opts.desc));
    p = p.set('page', String(opts.page ?? 0)).set('size', String(opts.size ?? 50));
    return this.http.get<Page>(`/api/data/${table}`, { params: p });
  }

  get(table: string, key: Record<string, string>): Observable<Row> {
    return this.http.get<Row>(`/api/data/${table}/record`, { params: key });
  }

  create(table: string, values: Row): Observable<Row> {
    return this.http.post<Row>(`/api/data/${table}`, values).pipe(map((r) => this.invalidate(table, r)));
  }

  update(table: string, key: Record<string, string>, values: Row): Observable<Row> {
    return this.http.put<Row>(`/api/data/${table}/record`, values, { params: key }).pipe(map((r) => this.invalidate(table, r)));
  }

  delete(table: string, key: Record<string, string>): Observable<void> {
    return this.http.delete<void>(`/api/data/${table}/record`, { params: key }).pipe(map((r) => this.invalidate(table, r)));
  }

  count(table: string, filters: Record<string, string> = {}): Observable<number> {
    return this.list(table, { filters, size: 1 }).pipe(map((p) => p.total));
  }

  lookup(table: string): Observable<LookupEntry[]> {
    let l = this.lookups.get(table);
    if (!l) {
      l = this.http.get<LookupEntry[]>(`/api/data/${table}/lookup`).pipe(shareReplay(1));
      this.lookups.set(table, l);
    }
    return l;
  }

  changeAddress(objectId: any, values: Row): Observable<Row> {
    return this.http.post<Row>(`/api/objekt/${objectId}/adresse-aendern`, values).pipe(map((r) => this.invalidate('object_addresses', r)));
  }

  private invalidate<T>(table: string, result: T): T {
    this.lookups.delete(table);
    if (table === 'objects' || table === 'object_addresses') this.loadObjekt();
    return result;
  }
}
