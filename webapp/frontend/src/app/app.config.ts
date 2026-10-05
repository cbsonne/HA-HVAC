import { ApplicationConfig, provideAppInitializer, provideBrowserGlobalErrorListeners, inject } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideRouter, withInMemoryScrolling } from '@angular/router';
import { ApiService } from './api.service';
import { routes } from './app.routes';
import { I18nService, languageInterceptor } from './i18n.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withFetch(), withInterceptors([languageInterceptor])),
    provideRouter(routes, withInMemoryScrolling({ scrollPositionRestoration: 'top' })),
    provideAppInitializer(async () => {
      const i18n = inject(I18nService);
      const api = inject(ApiService);
      await i18n.init();
      await api.loadMeta();
    }),
  ],
};
