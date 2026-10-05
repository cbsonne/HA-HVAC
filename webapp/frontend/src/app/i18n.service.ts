import { HttpInterceptorFn } from '@angular/common/http';
import { Injectable, Pipe, PipeTransform, computed, inject, signal } from '@angular/core';

/**
 * Verfügbare Sprachen. Eine weitere Sprache = Eintrag hier + Datei public/i18n/<code>.json.
 * Fehlende Schlüssel fallen auf Englisch zurück, danach auf den Schlüssel selbst.
 */
export const LANGUAGES = [
  { code: 'de', name: 'Deutsch', locale: 'de-DE' },
  { code: 'en', name: 'English', locale: 'en-GB' },
  { code: 'pt', name: 'Português', locale: 'pt-PT' },
] as const;

const FALLBACK = 'en';
const STORAGE_KEY = 'lueftung.lang';

type Dict = Record<string, string>;

@Injectable({ providedIn: 'root' })
export class I18nService {
  readonly lang = signal<string>(FALLBACK);
  private readonly dict = signal<Dict>({});
  private readonly fallback = signal<Dict>({});

  readonly locale = computed(() => LANGUAGES.find((l) => l.code === this.lang())?.locale ?? 'en-GB');

  constructor() {
    i18n = this;
  }

  async init(): Promise<void> {
    let code: string | null = null;
    try {
      code = localStorage.getItem(STORAGE_KEY);
    } catch {
      /* Speicher gesperrt: Browsersprache nehmen */
    }
    code ??= navigator.language?.substring(0, 2) ?? FALLBACK;
    this.fallback.set(await this.load(FALLBACK));
    await this.use(LANGUAGES.some((l) => l.code === code) ? code : FALLBACK);
  }

  async use(code: string): Promise<void> {
    this.dict.set(code === FALLBACK ? this.fallback() : await this.load(code));
    this.lang.set(code);
    document.documentElement.lang = code;
    try {
      localStorage.setItem(STORAGE_KEY, code);
    } catch {
      /* ignorieren */
    }
  }

  has(key: string): boolean {
    return key in this.dict() || key in this.fallback();
  }

  /** Übersetzt einen Schlüssel; Platzhalter {name} werden aus params ersetzt. */
  t(key: string, params?: Record<string, unknown>): string {
    let s = this.dict()[key] ?? this.fallback()[key] ?? key;
    if (params) for (const [k, v] of Object.entries(params)) s = s.split('{' + k + '}').join(String(v ?? ''));
    return s;
  }

  private async load(code: string): Promise<Dict> {
    const res = await fetch(`i18n/${code}.json`);
    return res.ok ? res.json() : {};
  }
}

/** Zugriff für reine Funktionen (pages.ts, format.ts); wird beim Start gesetzt. */
export let i18n: I18nService;

/** {{ 'action.new' | t }} oder {{ 'msg.deleteConfirm' | t: { name: x } }} */
@Pipe({ name: 't', pure: false })
export class TranslatePipe implements PipeTransform {
  private svc = inject(I18nService);

  transform(key: string, params?: Record<string, unknown>): string {
    return this.svc.t(key, params);
  }
}

/** Schickt die gewählte Sprache ans Backend, damit Fehlermeldungen passend zurückkommen. */
export const languageInterceptor: HttpInterceptorFn = (req, next) =>
  next(req.clone({ setHeaders: { 'Accept-Language': inject(I18nService).lang() } }));
