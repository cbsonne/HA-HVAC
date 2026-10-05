import { Injectable, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { i18n } from './i18n.service';

export interface DialogState {
  kind: 'error' | 'confirm' | 'info';
  title: string;
  message: string;
  resolve: (ok: boolean) => void;
}

/** Meldungen und Rückfragen wie in Business Central (modaler Dialog mit OK/Ja/Nein). */
@Injectable({ providedIn: 'root' })
export class DialogService {
  readonly current = signal<DialogState | null>(null);

  error(err: unknown): Promise<boolean> {
    let message = i18n.t('msg.unknownError');
    if (err instanceof HttpErrorResponse) {
      message = err.error?.message ?? (err.status === 0 ? i18n.t('msg.serverUnreachable') : `${err.status} ${err.statusText}`);
    } else if (err instanceof Error) {
      message = err.message;
    } else if (typeof err === 'string') {
      message = err;
    }
    return this.open('error', 'dialog.error', message);
  }

  confirm(message: string, title = 'dialog.confirm'): Promise<boolean> {
    return this.open('confirm', title, message);
  }

  info(message: string, title = 'dialog.info'): Promise<boolean> {
    return this.open('info', title, message);
  }

  close(ok: boolean) {
    const d = this.current();
    this.current.set(null);
    d?.resolve(ok);
  }

  private open(kind: DialogState['kind'], title: string, message: string): Promise<boolean> {
    return new Promise((resolve) => this.current.set({ kind, title, message, resolve }));
  }
}
