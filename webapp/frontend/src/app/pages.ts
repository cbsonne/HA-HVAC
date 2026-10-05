import { i18n } from './i18n.service';

/**
 * Seitendefinitionen im Stil von Business-Central-Seitenobjekten.
 * Hier wird festgelegt, wie eine Tabelle als Liste und Karte erscheint.
 * Alle sichtbaren Texte stehen in public/i18n/<sprache>.json:
 *   page.<id> (Listenname), card.<id> (Kartenname), group.<gruppe>, tab.*, part.*,
 *   field.<spalte> (Feldbeschriftung), enum.<wert> (Auswahlwerte).
 * Tabellen ohne Eintrag bekommen automatisch eine Standardseite unter "Weitere Tabellen",
 * neue Spalten erscheinen automatisch im Inforegister "Weitere Felder".
 */

export interface PartDef {
  /** Übersetzungsschlüssel, z. B. part.sensoren_im_raum */
  caption: string;
  /** Seite (= Tabelle) der Unterseite */
  page: string;
  /** Verknüpfung: Spalte der Unterseite -> Spalte des Kopfdatensatzes */
  link: Record<string, string>;
  columns?: string[];
  sort?: string;
  desc?: boolean;
  /** nur Datensätze, deren Spalte leer ist (z. B. aktuelle Adresse: valid_to leer) */
  emptyFilter?: string[];
  limit?: number;
}

export interface FastTab {
  /** Übersetzungsschlüssel, z. B. tab.allgemein */
  caption: string;
  fields: string[];
}

export interface PageDef {
  id: string;
  /** Schlüssel der Navigationsgruppe (Übersetzung: group.<schlüssel>) */
  group: string;
  listColumns?: string[];
  fastTabs?: FastTab[];
  /** Zeilen-Unterseiten auf der Karte */
  parts?: PartDef[];
  /** Infoboxen rechts auf der Karte */
  factboxes?: PartDef[];
  sort?: string;
  desc?: boolean;
}

export const NAV_GROUPS = ['object', 'rooms', 'sensors', 'actuators', 'bus', 'airQuality', 'control', 'simulation', 'other'];

export const PAGES: PageDef[] = [
  // ---------- Objekt ----------
  {
    id: 'objects', group: 'object',
    listColumns: ['object_no', 'name', 'active'],
    fastTabs: [{ caption: 'tab.allgemein', fields: ['object_no', 'name', 'active', 'description'] }],
    parts: [{ caption: 'part.adresshistorie', page: 'object_addresses', link: { object_id: 'object_id' }, sort: 'valid_from', desc: true,
      columns: ['valid_from', 'valid_to', 'street', 'house_number', 'postal_code', 'city', 'country_code'] }],
    factboxes: [{ caption: 'part.aktuelle_adresse', page: 'object_addresses', link: { object_id: 'object_id' }, emptyFilter: ['valid_to'],
      columns: ['street', 'house_number', 'postal_code', 'city', 'district', 'country_code', 'valid_from'] },
      { caption: 'part.lueftungsanlagen', page: 'ventilation_systems', link: { object_id: 'object_id' }, columns: ['name', 'max_airflow_m3h'] }],
  },
  {
    id: 'object_addresses', group: 'object',
    listColumns: ['object_id', 'street', 'house_number', 'postal_code', 'city', 'country_code', 'valid_from', 'valid_to'],
    sort: 'valid_from', desc: true,
    fastTabs: [
      { caption: 'tab.adresse', fields: ['object_id', 'street', 'house_number', 'postal_code', 'city', 'district', 'country_code'] },
      { caption: 'tab.gueltigkeit', fields: ['valid_from', 'valid_to', 'note'] },
      { caption: 'tab.geoposition', fields: ['latitude', 'longitude'] },
    ],
  },
  {
    id: 'ventilation_systems', group: 'object',
    listColumns: ['name', 'min_airflow_m3h', 'max_airflow_m3h', 'fault_airflow_m3h', 'supply_enabled', 'exhaust_enabled', 'active'],
    fastTabs: [
      { caption: 'tab.allgemein', fields: ['name', 'object_id', 'active', 'description'] },
      { caption: 'tab.luftmengen', fields: ['min_airflow_m3h', 'max_airflow_m3h', 'fault_airflow_m3h', 'supply_enabled', 'exhaust_enabled'] },
    ],
  },

  // ---------- Räume ----------
  {
    id: 'rooms', group: 'rooms',
    listColumns: ['name', 'floor', 'area_m2', 'height_m', 'usage_type_id', 'ventilation_type', 'desired_temperature', 'active'],
    fastTabs: [
      { caption: 'tab.allgemein', fields: ['name', 'floor', 'location', 'usage_type_id', 'active', 'description'] },
      { caption: 'tab.geometrie', fields: ['area_m2', 'height_m'] },
      { caption: 'tab.lueftung', fields: ['ventilation_type', 'desired_temperature'] },
    ],
    parts: [
      { caption: 'part.sensoren_im_raum', page: 'room_sensors', link: { room_id: 'room_id' }, columns: ['sensor_id', 'installation_position', 'bus_device_id', 'active'] },
      { caption: 'part.aktoren_im_raum', page: 'room_actuators', link: { room_id: 'room_id' }, columns: ['actuator_id', 'airflow_direction', 'active'] },
      { caption: 'part.luftqualitaetskorridore', page: 'room_air_quality_corridors', link: { room_id: 'room_id' }, columns: ['corridor_id', 'min_value', 'target_value', 'max_value', 'active'] },
    ],
    factboxes: [
      { caption: 'part.verbindungen_als_raum_a', page: 'room_connections', link: { room_a_id: 'room_id' }, columns: ['room_b_id', 'connection_type'] },
      { caption: 'part.verbindungen_als_raum_b', page: 'room_connections', link: { room_b_id: 'room_id' }, columns: ['room_a_id', 'connection_type'] },
      { caption: 'part.letzte_solver_ergebnisse', page: 'solver_room_results', link: { room_id: 'room_id' }, sort: 'solver_run_id', desc: true, limit: 5,
        columns: ['solver_run_id', 'requested_airflow_m3h', 'allocated_airflow_m3h'] },
    ],
  },
  {
    id: 'room_connections', group: 'rooms',
    listColumns: ['room_a_id', 'room_b_id', 'connection_type', 'normally_open', 'sensor_id', 'active', 'simulation_enabled'],
  },
  { id: 'usage_types', group: 'rooms',
    parts: [{ caption: 'part.mindestluftmengen', page: 'minimum_airflow_rates', link: { usage_type_id: 'usage_type_id' } }] },
  { id: 'minimum_airflow_rates', group: 'rooms' },

  // ---------- Sensorik ----------
  {
    id: 'sensors', group: 'sensors',
    listColumns: ['name', 'manufacturer_id', 'model', 'sensor_class_id', 'interface_type', 'serial_number', 'active', 'simulation_enabled'],
    fastTabs: [
      { caption: 'tab.allgemein', fields: ['name', 'sensor_class_id', 'active', 'simulation_enabled', 'description'] },
      { caption: 'tab.geraet', fields: ['manufacturer_id', 'model', 'serial_number', 'interface_type'] },
    ],
    parts: [
      { caption: 'part.messgroessen', page: 'sensor_measurements', link: { sensor_id: 'sensor_id' }, columns: ['name', 'parameter', 'unit', 'min_value', 'max_value', 'active'] },
      { caption: 'part.einbauorte', page: 'room_sensors', link: { sensor_id: 'sensor_id' }, columns: ['room_id', 'installation_position', 'bus_device_id', 'modbus_address'] },
    ],
    factboxes: [
      { caption: 'part.letzte_messwerte', page: 'sensor_values', link: { sensor_id: 'sensor_id' }, sort: 'timestamp', desc: true, limit: 8,
        columns: ['timestamp', 'measurement_definition_id', 'value'] },
      { caption: 'part.busgeraete', page: 'bus_devices', link: { sensor_id: 'sensor_id' }, columns: ['device_name', 'address'] },
    ],
  },
  { id: 'sensor_measurements', group: 'sensors',
    listColumns: ['sensor_id', 'name', 'parameter', 'unit', 'min_value', 'max_value', 'active'],
    parts: [{ caption: 'part.ueberwachte_aktoren', page: 'sensor_actuator_measurements', link: { measurement_definition_id: 'measurement_definition_id' } }],
    factboxes: [{ caption: 'part.letzte_messwerte', page: 'sensor_values', link: { measurement_definition_id: 'measurement_definition_id' }, sort: 'timestamp', desc: true, limit: 8, columns: ['timestamp', 'value', 'quality'] }] },
  { id: 'room_sensors', group: 'sensors',
    listColumns: ['room_id', 'sensor_id', 'installation_position', 'bus_device_id', 'modbus_address', 'mac_address', 'active'] },
  { id: 'sensor_manufacturers', group: 'sensors' },
  { id: 'sensor_classes', group: 'sensors' },
  { id: 'sensor_values', group: 'sensors', sort: 'timestamp', desc: true },

  // ---------- Aktorik ----------
  {
    id: 'actuators', group: 'actuators',
    listColumns: ['name', 'actuator_type', 'manufacturer', 'model', 'min_position_pct', 'max_position_pct', 'fail_position_pct', 'active'],
    fastTabs: [
      { caption: 'tab.allgemein', fields: ['name', 'actuator_type', 'active', 'simulation_enabled', 'description'] },
      { caption: 'tab.geraet', fields: ['manufacturer', 'model', 'assembly_id', 'bus_device_id'] },
      { caption: 'tab.stellbereich', fields: ['min_position_pct', 'max_position_pct', 'fail_position_pct'] },
    ],
    parts: [
      { caption: 'part.raeume', page: 'room_actuators', link: { actuator_id: 'actuator_id' }, columns: ['room_id', 'airflow_direction', 'active'] },
      { caption: 'part.klappenkennlinien', page: 'actuator_characteristics', link: { actuator_id: 'actuator_id' } },
      { caption: 'part.ueberwachende_messgroessen', page: 'sensor_actuator_measurements', link: { actuator_id: 'actuator_id' } },
    ],
    factboxes: [
      { caption: 'part.letzte_stellwerte', page: 'actuator_values', link: { actuator_id: 'actuator_id' }, sort: 'timestamp', desc: true, limit: 8,
        columns: ['timestamp', 'commanded_position_pct', 'actual_position_pct', 'airflow_m3h'] },
    ],
  },
  { id: 'room_actuators', group: 'actuators' },
  { id: 'damper_characteristics', group: 'actuators',
    listColumns: ['manufacturer', 'product_family', 'model', 'damper_type', 'nominal_diameter_mm', 'setting_position', 'k_factor', 'active'],
    parts: [{ caption: 'part.druckverlustpunkte', page: 'damper_pressure_loss', link: { characteristic_id: 'characteristic_id' }, sort: 'airflow_m3h',
      columns: ['airflow_m3h', 'pressure_loss_pa', 'sound_level_dba'] }] },
  { id: 'damper_pressure_loss', group: 'actuators' },
  { id: 'actuator_characteristics', group: 'actuators' },
  { id: 'sensor_actuator_measurements', group: 'actuators' },
  { id: 'actuator_values', group: 'actuators', sort: 'timestamp', desc: true },

  // ---------- Bus & Hardware ----------
  { id: 'buses', group: 'bus',
    listColumns: ['name', 'bus_type_id', 'interface_name', 'address', 'assembly_id', 'active'],
    parts: [{ caption: 'part.busgeraete', page: 'bus_devices', link: { bus_id: 'bus_id' }, columns: ['device_name', 'address', 'sensor_id', 'active'] },
      { caption: 'part.i2c_busse', page: 'i2c_buses', link: { bus_id: 'bus_id' } }] },
  { id: 'bus_types', group: 'bus' },
  { id: 'i2c_buses', group: 'bus',
    parts: [{ caption: 'part.busgeraete', page: 'bus_devices', link: { i2c_bus_id: 'i2c_bus_id' }, columns: ['device_name', 'address', 'sensor_id', 'active'] }] },
  { id: 'bus_devices', group: 'bus',
    listColumns: ['device_name', 'bus_id', 'i2c_bus_id', 'address', 'mac_address', 'sensor_id', 'assembly_id', 'active'] },
  { id: 'master_assemblies', group: 'bus',
    parts: [{ caption: 'part.aktoren', page: 'actuators', link: { assembly_id: 'assembly_id' }, columns: ['name', 'actuator_type', 'active'] },
      { caption: 'part.busgeraete', page: 'bus_devices', link: { assembly_id: 'assembly_id' }, columns: ['device_name', 'address', 'active'] }] },
  { id: 'master_bom', group: 'bus',
    parts: [{ caption: 'part.baugruppen', page: 'master_assemblies', link: { master_bom_id: 'master_bom_id' } }] },

  // ---------- Luftqualität ----------
  { id: 'air_quality_sources', group: 'airQuality',
    listColumns: ['short_name', 'full_name', 'authority', 'version', 'publication_year', 'is_norm', 'is_guideline', 'active'],
    parts: [{ caption: 'part.referenzwerte', page: 'air_quality_references', link: { source_id: 'source_id' }, columns: ['parameter', 'unit', 'averaging_time', 'value', 'category'] }] },
  { id: 'air_quality_references', group: 'airQuality' },
  { id: 'air_quality_corridors', group: 'airQuality',
    listColumns: ['parameter', 'unit', 'min_value', 'target_value', 'max_value', 'source_id', 'active'],
    parts: [{ caption: 'part.raumspezifische_abweichungen', page: 'room_air_quality_corridors', link: { corridor_id: 'corridor_id' } }] },
  { id: 'room_air_quality_corridors', group: 'airQuality' },

  // ---------- Regelung ----------
  { id: 'overload_strategy', group: 'control' },
  { id: 'solver_config', group: 'control' },
  { id: 'solver_runs', group: 'control', sort: 'started_at', desc: true,
    listColumns: ['solver_run_id', 'started_at', 'run_mode', 'success', 'total_requested_m3h', 'total_allocated_m3h', 'overload_pct'],
    parts: [{ caption: 'part.raumergebnisse', page: 'solver_room_results', link: { solver_run_id: 'solver_run_id' } },
      { caption: 'part.aktorergebnisse', page: 'solver_actuator_results', link: { solver_run_id: 'solver_run_id' } }] },
  { id: 'solver_room_results', group: 'control' },
  { id: 'solver_actuator_results', group: 'control' },

  // ---------- Simulation ----------
  { id: 'simulation_scenarios', group: 'simulation',
    parts: [{ caption: 'part.ereignisse', page: 'simulation_events', link: { scenario_id: 'scenario_id' }, sort: 'start_second',
      columns: ['start_second', 'duration_seconds', 'event_type', 'room_id', 'sensor_id', 'actuator_id', 'parameter', 'value', 'unit'] },
      { caption: 'part.vorgabewerte', page: 'simulation_values', link: { scenario_id: 'scenario_id' }, sort: 'timestamp_offset_seconds' }] },
  { id: 'simulation_events', group: 'simulation' },
  { id: 'simulation_values', group: 'simulation' },
];

/** Feldbeschriftung in der aktuellen Sprache; fehlt sie, wird sie aus dem Spaltennamen abgeleitet. */
export function caption(column: string): string {
  const key = 'field.' + column;
  if (i18n.has(key)) return i18n.t(key);
  const s = column
    .replace(/_m3h$/, ' (m³/h)').replace(/_pa$/, ' (Pa)').replace(/_pct$/, ' (%)').replace(/_m2$/, ' (m²)').replace(/_mm$/, ' (mm)')
    .replace(/_id$/, '').replace(/_/g, ' ');
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export function enumCaption(value: string): string {
  const key = 'enum.' + value;
  return i18n.has(key) ? i18n.t(key) : value;
}

function humanizeTable(table: string): string {
  const s = table.replace(/_/g, ' ');
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/** Name der Listenseite, z. B. "Räume" / "Rooms" / "Divisões". */
export function pageCaption(id: string): string {
  return i18n.has('page.' + id) ? i18n.t('page.' + id) : humanizeTable(id);
}

/** Name der Kartenseite, z. B. "Raumkarte" / "Room Card". */
export function cardCaption(id: string): string {
  return i18n.has('card.' + id) ? i18n.t('card.' + id) : pageCaption(id);
}

/** Seite zu einer Tabelle; unbekannte Tabellen bekommen eine Standardseite. */
export function pageFor(id: string): PageDef {
  return PAGES.find((p) => p.id === id) ?? { id, group: 'other' };
}
