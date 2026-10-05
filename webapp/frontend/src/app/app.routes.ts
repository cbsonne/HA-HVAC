import { Routes } from '@angular/router';
import { CardPageComponent } from './card-page';
import { ListPageComponent } from './list-page';
import { RoleCenterComponent } from './role-center';

export const routes: Routes = [
  { path: '', component: RoleCenterComponent },
  { path: 'list/:page', component: ListPageComponent },
  { path: 'card/:page', component: CardPageComponent },
  { path: '**', redirectTo: '' },
];
