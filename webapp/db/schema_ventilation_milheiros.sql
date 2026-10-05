-- Aus dem pg_dump (Custom-Format) vom 2026-10-05 rekonstruierte DDL, nur für lokale Tests.
-- NICHT auf die produktive Datenbank anwenden: die Tabellen existieren dort bereits.
CREATE SCHEMA IF NOT EXISTS ventilation_milheiros;
CREATE TABLE ventilation_milheiros.actuator_characteristics (
    actuator_id bigint NOT NULL,
    characteristic_id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.actuator_values (
    "timestamp" timestamp with time zone NOT NULL,
    actuator_id bigint NOT NULL,
    commanded_position_pct numeric(8,4),
    actual_position_pct numeric(8,4),
    airflow_m3h numeric(12,4),
    pressure_pa numeric(12,4),
    source character varying(20) DEFAULT 'REAL'::character varying NOT NULL
);
CREATE TABLE ventilation_milheiros.actuators (
    actuator_id bigint NOT NULL,
    assembly_id bigint,
    bus_device_id bigint,
    manufacturer character varying(100),
    model character varying(100),
    actuator_type character varying(50),
    name character varying(150) NOT NULL,
    min_position_pct numeric(6,3) DEFAULT 0,
    max_position_pct numeric(6,3) DEFAULT 100,
    fail_position_pct numeric(6,3),
    active boolean DEFAULT true NOT NULL,
    simulation_enabled boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.air_quality_corridors (
    corridor_id bigint NOT NULL,
    parameter character varying(50) NOT NULL,
    unit character varying(30) NOT NULL,
    min_value numeric(15,5),
    target_value numeric(15,5) NOT NULL,
    max_value numeric(15,5) NOT NULL,
    source_id bigint,
    reasoning_source text,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT air_quality_corridors_check CHECK (((min_value IS NULL) OR (min_value <= target_value))),
    CONSTRAINT air_quality_corridors_check1 CHECK ((target_value <= max_value))
);
CREATE TABLE ventilation_milheiros.air_quality_references (
    reference_id bigint NOT NULL,
    source_id bigint NOT NULL,
    parameter character varying(50) NOT NULL,
    unit character varying(30) NOT NULL,
    averaging_time character varying(50),
    value numeric(15,5),
    category character varying(50),
    notes text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.air_quality_sources (
    source_id bigint NOT NULL,
    short_name character varying(100) NOT NULL,
    full_name text NOT NULL,
    authority character varying(100),
    document_reference text,
    version character varying(100),
    publication_year integer,
    is_norm boolean DEFAULT false NOT NULL,
    is_guideline boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.bus_devices (
    bus_device_id bigint NOT NULL,
    bus_id bigint,
    i2c_bus_id bigint,
    sensor_id bigint,
    assembly_id bigint,
    device_name character varying(150),
    address character varying(100),
    mac_address character varying(17),
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.bus_types (
    bus_type_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.buses (
    bus_id bigint NOT NULL,
    bus_type_id bigint NOT NULL,
    assembly_id bigint,
    name character varying(100) NOT NULL,
    interface_name character varying(100),
    address character varying(100),
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.damper_characteristics (
    characteristic_id bigint NOT NULL,
    manufacturer character varying(100) NOT NULL,
    product_family character varying(100) NOT NULL,
    model character varying(100),
    damper_type character varying(30) NOT NULL,
    nominal_diameter_mm integer,
    setting_position numeric(8,3),
    opening_angle_deg numeric(8,3),
    k_factor numeric(12,5),
    source_id bigint,
    source_reference text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.damper_pressure_loss (
    pressure_loss_id bigint NOT NULL,
    characteristic_id bigint NOT NULL,
    airflow_m3h numeric(12,4) NOT NULL,
    pressure_loss_pa numeric(12,4) NOT NULL,
    sound_level_dba numeric(8,3),
    source_reference text
);
CREATE TABLE ventilation_milheiros.i2c_buses (
    i2c_bus_id bigint NOT NULL,
    bus_id bigint,
    name character varying(100) NOT NULL,
    controller character varying(100),
    bus_number integer,
    frequency_hz integer DEFAULT 100000,
    voltage_v numeric(5,2),
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.master_assemblies (
    assembly_id bigint NOT NULL,
    name character varying(150) NOT NULL,
    master_bom_id bigint,
    manufacturer character varying(100),
    model character varying(100),
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.master_bom (
    master_bom_id bigint NOT NULL,
    name character varying(150) NOT NULL,
    version character varying(50),
    manufacturer character varying(100),
    description text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.minimum_airflow_rates (
    mlr_id bigint NOT NULL,
    usage_type_id bigint NOT NULL,
    mlr_fault_m3h numeric(10,3) NOT NULL,
    mlr_controlled_m3h numeric(10,3) NOT NULL,
    source text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.overload_strategy (
    strategy_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    priority_method character varying(50) NOT NULL,
    max_system_load_pct numeric(8,3) DEFAULT 100,
    allow_minimum_airflow_violation boolean DEFAULT false,
    description text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.room_actuators (
    room_id bigint NOT NULL,
    actuator_id bigint NOT NULL,
    airflow_direction character varying(20),
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.room_air_quality_corridors (
    room_id bigint NOT NULL,
    corridor_id bigint NOT NULL,
    min_value numeric(15,5),
    target_value numeric(15,5),
    max_value numeric(15,5),
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT room_air_quality_corridors_check CHECK (((min_value IS NULL) OR (min_value <= target_value))),
    CONSTRAINT room_air_quality_corridors_check1 CHECK ((target_value <= max_value))
);
CREATE TABLE ventilation_milheiros.room_connections (
    connection_id bigint NOT NULL,
    room_a_id bigint NOT NULL,
    room_b_id bigint NOT NULL,
    connection_type character varying(30) NOT NULL,
    sensor_id bigint,
    normally_open boolean,
    active boolean DEFAULT true NOT NULL,
    simulation_enabled boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT room_connections_check CHECK ((room_a_id <> room_b_id)),
    CONSTRAINT room_connections_connection_type_check CHECK (((connection_type)::text = ANY ((ARRAY['DOOR'::character varying, 'WINDOW'::character varying, 'TRANSFER'::character varying, 'OPENING'::character varying, 'OTHER'::character varying])::text[])))
);
CREATE TABLE ventilation_milheiros.room_sensors (
    room_sensor_id bigint NOT NULL,
    room_id bigint NOT NULL,
    sensor_id bigint NOT NULL,
    bus_device_id bigint,
    modbus_address character varying(50),
    mac_address character varying(17),
    installation_position character varying(100),
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.rooms (
    room_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    area_m2 numeric(10,2) NOT NULL,
    height_m numeric(10,2) NOT NULL,
    floor integer,
    location character varying(100),
    usage_type_id bigint,
    ventilation_type character varying(20) NOT NULL,
    desired_temperature numeric(5,2),
    active boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT rooms_area_m2_check CHECK ((area_m2 > (0)::numeric)),
    CONSTRAINT rooms_height_m_check CHECK ((height_m > (0)::numeric)),
    CONSTRAINT rooms_ventilation_type_check CHECK (((ventilation_type)::text = ANY ((ARRAY['SUPPLY'::character varying, 'EXHAUST'::character varying, 'SUPPLY_EXHAUST'::character varying, 'TRANSFER'::character varying, 'NONE'::character varying])::text[])))
);
CREATE TABLE ventilation_milheiros.sensor_actuator_measurements (
    measurement_definition_id bigint NOT NULL,
    actuator_id bigint NOT NULL,
    relationship_type character varying(50) DEFAULT 'MONITORING'::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.sensor_classes (
    sensor_class_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.sensor_manufacturers (
    manufacturer_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    website text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.sensor_measurements (
    measurement_definition_id bigint NOT NULL,
    sensor_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    parameter character varying(50) NOT NULL,
    unit character varying(30) NOT NULL,
    min_value numeric(15,5),
    max_value numeric(15,5),
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.sensor_values (
    "timestamp" timestamp with time zone NOT NULL,
    sensor_id bigint NOT NULL,
    measurement_definition_id bigint NOT NULL,
    value numeric(15,6) NOT NULL,
    quality character varying(30),
    source character varying(20) DEFAULT 'REAL'::character varying NOT NULL
);
CREATE TABLE ventilation_milheiros.sensors (
    sensor_id bigint NOT NULL,
    manufacturer_id bigint,
    model character varying(100),
    name character varying(150) NOT NULL,
    sensor_class_id bigint,
    serial_number character varying(100),
    interface_type character varying(30),
    active boolean DEFAULT true NOT NULL,
    simulation_enabled boolean DEFAULT false NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.simulation_events (
    event_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    room_id bigint,
    sensor_id bigint,
    actuator_id bigint,
    connection_id bigint,
    start_second integer DEFAULT 0 NOT NULL,
    duration_seconds integer,
    event_type character varying(50) NOT NULL,
    parameter character varying(50),
    value numeric(15,5),
    value_text text,
    unit character varying(30),
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.simulation_scenarios (
    scenario_id bigint NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    duration_seconds integer,
    timestep_seconds integer DEFAULT 10,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.simulation_values (
    simulation_value_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    sensor_id bigint,
    measurement_definition_id bigint,
    timestamp_offset_seconds integer NOT NULL,
    value numeric(15,6) NOT NULL
);
CREATE TABLE ventilation_milheiros.solver_actuator_results (
    result_id bigint NOT NULL,
    solver_run_id bigint NOT NULL,
    actuator_id bigint NOT NULL,
    calculated_position_pct numeric(8,4),
    calculated_airflow_m3h numeric(12,4),
    calculated_pressure_pa numeric(12,4)
);
CREATE TABLE ventilation_milheiros.solver_config (
    solver_config_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    algorithm character varying(50) NOT NULL,
    tolerance numeric(15,10) DEFAULT 0.000001,
    max_iterations integer DEFAULT 100,
    airflow_tolerance_m3h numeric(10,4) DEFAULT 0.1,
    pressure_tolerance_pa numeric(10,4) DEFAULT 0.1,
    rls_enabled boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    description text
);
CREATE TABLE ventilation_milheiros.solver_room_results (
    result_id bigint NOT NULL,
    solver_run_id bigint NOT NULL,
    room_id bigint NOT NULL,
    requested_airflow_m3h numeric(12,4),
    allocated_airflow_m3h numeric(12,4),
    calculated_pressure_pa numeric(12,4),
    priority_factor numeric(10,5),
    overload_reduction_pct numeric(10,5)
);
CREATE TABLE ventilation_milheiros.solver_runs (
    solver_run_id bigint NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    run_mode character varying(20) NOT NULL,
    solver_config_id bigint,
    success boolean,
    total_requested_m3h numeric(12,3),
    total_allocated_m3h numeric(12,3),
    system_max_m3h numeric(12,3),
    overload_pct numeric(10,3),
    error_message text,
    CONSTRAINT solver_runs_run_mode_check CHECK (((run_mode)::text = ANY ((ARRAY['REAL'::character varying, 'SIMULATION'::character varying, 'TEST'::character varying])::text[])))
);
CREATE TABLE ventilation_milheiros.usage_types (
    usage_type_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ventilation_milheiros.ventilation_systems (
    system_id bigint NOT NULL,
    name character varying(150) NOT NULL,
    min_airflow_m3h numeric(10,3),
    max_airflow_m3h numeric(10,3) NOT NULL,
    fault_airflow_m3h numeric(10,3),
    supply_enabled boolean DEFAULT true NOT NULL,
    exhaust_enabled boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT ventilation_systems_max_airflow_m3h_check CHECK ((max_airflow_m3h > (0)::numeric))
);
CREATE SEQUENCE ventilation_milheiros.actuators_actuator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.air_quality_corridors_corridor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.air_quality_references_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.air_quality_sources_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.bus_devices_bus_device_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.bus_types_bus_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.buses_bus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.damper_characteristics_characteristic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.damper_pressure_loss_pressure_loss_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.i2c_buses_i2c_bus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.master_assemblies_assembly_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.master_bom_master_bom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.minimum_airflow_rates_mlr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.overload_strategy_strategy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.room_connections_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.room_sensors_room_sensor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.rooms_room_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.sensor_classes_sensor_class_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.sensor_manufacturers_manufacturer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.sensor_measurements_measurement_definition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.sensors_sensor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.simulation_events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.simulation_scenarios_scenario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.simulation_values_simulation_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.solver_actuator_results_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.solver_config_solver_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.solver_room_results_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.solver_runs_solver_run_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.usage_types_usage_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE ventilation_milheiros.ventilation_systems_system_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ventilation_milheiros.actuators_actuator_id_seq OWNED BY ventilation_milheiros.actuators.actuator_id;
ALTER SEQUENCE ventilation_milheiros.air_quality_corridors_corridor_id_seq OWNED BY ventilation_milheiros.air_quality_corridors.corridor_id;
ALTER SEQUENCE ventilation_milheiros.air_quality_references_reference_id_seq OWNED BY ventilation_milheiros.air_quality_references.reference_id;
ALTER SEQUENCE ventilation_milheiros.air_quality_sources_source_id_seq OWNED BY ventilation_milheiros.air_quality_sources.source_id;
ALTER SEQUENCE ventilation_milheiros.bus_devices_bus_device_id_seq OWNED BY ventilation_milheiros.bus_devices.bus_device_id;
ALTER SEQUENCE ventilation_milheiros.bus_types_bus_type_id_seq OWNED BY ventilation_milheiros.bus_types.bus_type_id;
ALTER SEQUENCE ventilation_milheiros.buses_bus_id_seq OWNED BY ventilation_milheiros.buses.bus_id;
ALTER SEQUENCE ventilation_milheiros.damper_characteristics_characteristic_id_seq OWNED BY ventilation_milheiros.damper_characteristics.characteristic_id;
ALTER SEQUENCE ventilation_milheiros.damper_pressure_loss_pressure_loss_id_seq OWNED BY ventilation_milheiros.damper_pressure_loss.pressure_loss_id;
ALTER SEQUENCE ventilation_milheiros.i2c_buses_i2c_bus_id_seq OWNED BY ventilation_milheiros.i2c_buses.i2c_bus_id;
ALTER SEQUENCE ventilation_milheiros.master_assemblies_assembly_id_seq OWNED BY ventilation_milheiros.master_assemblies.assembly_id;
ALTER SEQUENCE ventilation_milheiros.master_bom_master_bom_id_seq OWNED BY ventilation_milheiros.master_bom.master_bom_id;
ALTER SEQUENCE ventilation_milheiros.minimum_airflow_rates_mlr_id_seq OWNED BY ventilation_milheiros.minimum_airflow_rates.mlr_id;
ALTER SEQUENCE ventilation_milheiros.overload_strategy_strategy_id_seq OWNED BY ventilation_milheiros.overload_strategy.strategy_id;
ALTER SEQUENCE ventilation_milheiros.room_connections_connection_id_seq OWNED BY ventilation_milheiros.room_connections.connection_id;
ALTER SEQUENCE ventilation_milheiros.room_sensors_room_sensor_id_seq OWNED BY ventilation_milheiros.room_sensors.room_sensor_id;
ALTER SEQUENCE ventilation_milheiros.rooms_room_id_seq OWNED BY ventilation_milheiros.rooms.room_id;
ALTER SEQUENCE ventilation_milheiros.sensor_classes_sensor_class_id_seq OWNED BY ventilation_milheiros.sensor_classes.sensor_class_id;
ALTER SEQUENCE ventilation_milheiros.sensor_manufacturers_manufacturer_id_seq OWNED BY ventilation_milheiros.sensor_manufacturers.manufacturer_id;
ALTER SEQUENCE ventilation_milheiros.sensor_measurements_measurement_definition_id_seq OWNED BY ventilation_milheiros.sensor_measurements.measurement_definition_id;
ALTER SEQUENCE ventilation_milheiros.sensors_sensor_id_seq OWNED BY ventilation_milheiros.sensors.sensor_id;
ALTER SEQUENCE ventilation_milheiros.simulation_events_event_id_seq OWNED BY ventilation_milheiros.simulation_events.event_id;
ALTER SEQUENCE ventilation_milheiros.simulation_scenarios_scenario_id_seq OWNED BY ventilation_milheiros.simulation_scenarios.scenario_id;
ALTER SEQUENCE ventilation_milheiros.simulation_values_simulation_value_id_seq OWNED BY ventilation_milheiros.simulation_values.simulation_value_id;
ALTER SEQUENCE ventilation_milheiros.solver_actuator_results_result_id_seq OWNED BY ventilation_milheiros.solver_actuator_results.result_id;
ALTER SEQUENCE ventilation_milheiros.solver_config_solver_config_id_seq OWNED BY ventilation_milheiros.solver_config.solver_config_id;
ALTER SEQUENCE ventilation_milheiros.solver_room_results_result_id_seq OWNED BY ventilation_milheiros.solver_room_results.result_id;
ALTER SEQUENCE ventilation_milheiros.solver_runs_solver_run_id_seq OWNED BY ventilation_milheiros.solver_runs.solver_run_id;
ALTER SEQUENCE ventilation_milheiros.usage_types_usage_type_id_seq OWNED BY ventilation_milheiros.usage_types.usage_type_id;
ALTER SEQUENCE ventilation_milheiros.ventilation_systems_system_id_seq OWNED BY ventilation_milheiros.ventilation_systems.system_id;
ALTER TABLE ONLY ventilation_milheiros.actuators ALTER COLUMN actuator_id SET DEFAULT nextval('ventilation_milheiros.actuators_actuator_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.air_quality_corridors ALTER COLUMN corridor_id SET DEFAULT nextval('ventilation_milheiros.air_quality_corridors_corridor_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.air_quality_references ALTER COLUMN reference_id SET DEFAULT nextval('ventilation_milheiros.air_quality_references_reference_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.air_quality_sources ALTER COLUMN source_id SET DEFAULT nextval('ventilation_milheiros.air_quality_sources_source_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.bus_devices ALTER COLUMN bus_device_id SET DEFAULT nextval('ventilation_milheiros.bus_devices_bus_device_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.bus_types ALTER COLUMN bus_type_id SET DEFAULT nextval('ventilation_milheiros.bus_types_bus_type_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.buses ALTER COLUMN bus_id SET DEFAULT nextval('ventilation_milheiros.buses_bus_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.damper_characteristics ALTER COLUMN characteristic_id SET DEFAULT nextval('ventilation_milheiros.damper_characteristics_characteristic_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.damper_pressure_loss ALTER COLUMN pressure_loss_id SET DEFAULT nextval('ventilation_milheiros.damper_pressure_loss_pressure_loss_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.i2c_buses ALTER COLUMN i2c_bus_id SET DEFAULT nextval('ventilation_milheiros.i2c_buses_i2c_bus_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.master_assemblies ALTER COLUMN assembly_id SET DEFAULT nextval('ventilation_milheiros.master_assemblies_assembly_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.master_bom ALTER COLUMN master_bom_id SET DEFAULT nextval('ventilation_milheiros.master_bom_master_bom_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.minimum_airflow_rates ALTER COLUMN mlr_id SET DEFAULT nextval('ventilation_milheiros.minimum_airflow_rates_mlr_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.overload_strategy ALTER COLUMN strategy_id SET DEFAULT nextval('ventilation_milheiros.overload_strategy_strategy_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.room_connections ALTER COLUMN connection_id SET DEFAULT nextval('ventilation_milheiros.room_connections_connection_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.room_sensors ALTER COLUMN room_sensor_id SET DEFAULT nextval('ventilation_milheiros.room_sensors_room_sensor_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.rooms ALTER COLUMN room_id SET DEFAULT nextval('ventilation_milheiros.rooms_room_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.sensor_classes ALTER COLUMN sensor_class_id SET DEFAULT nextval('ventilation_milheiros.sensor_classes_sensor_class_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.sensor_manufacturers ALTER COLUMN manufacturer_id SET DEFAULT nextval('ventilation_milheiros.sensor_manufacturers_manufacturer_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.sensor_measurements ALTER COLUMN measurement_definition_id SET DEFAULT nextval('ventilation_milheiros.sensor_measurements_measurement_definition_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.sensors ALTER COLUMN sensor_id SET DEFAULT nextval('ventilation_milheiros.sensors_sensor_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.simulation_events ALTER COLUMN event_id SET DEFAULT nextval('ventilation_milheiros.simulation_events_event_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.simulation_scenarios ALTER COLUMN scenario_id SET DEFAULT nextval('ventilation_milheiros.simulation_scenarios_scenario_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.simulation_values ALTER COLUMN simulation_value_id SET DEFAULT nextval('ventilation_milheiros.simulation_values_simulation_value_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.solver_actuator_results ALTER COLUMN result_id SET DEFAULT nextval('ventilation_milheiros.solver_actuator_results_result_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.solver_config ALTER COLUMN solver_config_id SET DEFAULT nextval('ventilation_milheiros.solver_config_solver_config_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.solver_room_results ALTER COLUMN result_id SET DEFAULT nextval('ventilation_milheiros.solver_room_results_result_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.solver_runs ALTER COLUMN solver_run_id SET DEFAULT nextval('ventilation_milheiros.solver_runs_solver_run_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.usage_types ALTER COLUMN usage_type_id SET DEFAULT nextval('ventilation_milheiros.usage_types_usage_type_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.ventilation_systems ALTER COLUMN system_id SET DEFAULT nextval('ventilation_milheiros.ventilation_systems_system_id_seq'::regclass);
ALTER TABLE ONLY ventilation_milheiros.actuator_characteristics
    ADD CONSTRAINT actuator_characteristics_pkey PRIMARY KEY (actuator_id, characteristic_id);
ALTER TABLE ONLY ventilation_milheiros.actuator_values
    ADD CONSTRAINT actuator_values_pkey PRIMARY KEY ("timestamp", actuator_id);
ALTER TABLE ONLY ventilation_milheiros.actuators
    ADD CONSTRAINT actuators_pkey PRIMARY KEY (actuator_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_corridors
    ADD CONSTRAINT air_quality_corridors_parameter_unit_key UNIQUE (parameter, unit);
ALTER TABLE ONLY ventilation_milheiros.air_quality_corridors
    ADD CONSTRAINT air_quality_corridors_pkey PRIMARY KEY (corridor_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_references
    ADD CONSTRAINT air_quality_references_pkey PRIMARY KEY (reference_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_sources
    ADD CONSTRAINT air_quality_sources_pkey PRIMARY KEY (source_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_sources
    ADD CONSTRAINT air_quality_sources_short_name_key UNIQUE (short_name);
ALTER TABLE ONLY ventilation_milheiros.bus_devices
    ADD CONSTRAINT bus_devices_pkey PRIMARY KEY (bus_device_id);
ALTER TABLE ONLY ventilation_milheiros.bus_types
    ADD CONSTRAINT bus_types_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.bus_types
    ADD CONSTRAINT bus_types_pkey PRIMARY KEY (bus_type_id);
ALTER TABLE ONLY ventilation_milheiros.buses
    ADD CONSTRAINT buses_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.buses
    ADD CONSTRAINT buses_pkey PRIMARY KEY (bus_id);
ALTER TABLE ONLY ventilation_milheiros.damper_characteristics
    ADD CONSTRAINT damper_characteristics_pkey PRIMARY KEY (characteristic_id);
ALTER TABLE ONLY ventilation_milheiros.damper_pressure_loss
    ADD CONSTRAINT damper_pressure_loss_characteristic_id_airflow_m3h_key UNIQUE (characteristic_id, airflow_m3h);
ALTER TABLE ONLY ventilation_milheiros.damper_pressure_loss
    ADD CONSTRAINT damper_pressure_loss_pkey PRIMARY KEY (pressure_loss_id);
ALTER TABLE ONLY ventilation_milheiros.i2c_buses
    ADD CONSTRAINT i2c_buses_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.i2c_buses
    ADD CONSTRAINT i2c_buses_pkey PRIMARY KEY (i2c_bus_id);
ALTER TABLE ONLY ventilation_milheiros.master_assemblies
    ADD CONSTRAINT master_assemblies_pkey PRIMARY KEY (assembly_id);
ALTER TABLE ONLY ventilation_milheiros.master_bom
    ADD CONSTRAINT master_bom_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.master_bom
    ADD CONSTRAINT master_bom_pkey PRIMARY KEY (master_bom_id);
ALTER TABLE ONLY ventilation_milheiros.minimum_airflow_rates
    ADD CONSTRAINT minimum_airflow_rates_pkey PRIMARY KEY (mlr_id);
ALTER TABLE ONLY ventilation_milheiros.minimum_airflow_rates
    ADD CONSTRAINT minimum_airflow_rates_usage_type_id_key UNIQUE (usage_type_id);
ALTER TABLE ONLY ventilation_milheiros.overload_strategy
    ADD CONSTRAINT overload_strategy_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.overload_strategy
    ADD CONSTRAINT overload_strategy_pkey PRIMARY KEY (strategy_id);
ALTER TABLE ONLY ventilation_milheiros.room_actuators
    ADD CONSTRAINT room_actuators_pkey PRIMARY KEY (room_id, actuator_id);
ALTER TABLE ONLY ventilation_milheiros.room_air_quality_corridors
    ADD CONSTRAINT room_air_quality_corridors_pkey PRIMARY KEY (room_id, corridor_id);
ALTER TABLE ONLY ventilation_milheiros.room_connections
    ADD CONSTRAINT room_connections_pkey PRIMARY KEY (connection_id);
ALTER TABLE ONLY ventilation_milheiros.room_sensors
    ADD CONSTRAINT room_sensors_pkey PRIMARY KEY (room_sensor_id);
ALTER TABLE ONLY ventilation_milheiros.room_sensors
    ADD CONSTRAINT room_sensors_room_id_sensor_id_key UNIQUE (room_id, sensor_id);
ALTER TABLE ONLY ventilation_milheiros.rooms
    ADD CONSTRAINT rooms_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (room_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_actuator_measurements
    ADD CONSTRAINT sensor_actuator_measurements_pkey PRIMARY KEY (measurement_definition_id, actuator_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_classes
    ADD CONSTRAINT sensor_classes_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.sensor_classes
    ADD CONSTRAINT sensor_classes_pkey PRIMARY KEY (sensor_class_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_manufacturers
    ADD CONSTRAINT sensor_manufacturers_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.sensor_manufacturers
    ADD CONSTRAINT sensor_manufacturers_pkey PRIMARY KEY (manufacturer_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_measurements
    ADD CONSTRAINT sensor_measurements_pkey PRIMARY KEY (measurement_definition_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_measurements
    ADD CONSTRAINT sensor_measurements_sensor_id_parameter_key UNIQUE (sensor_id, parameter);
ALTER TABLE ONLY ventilation_milheiros.sensor_values
    ADD CONSTRAINT sensor_values_pkey PRIMARY KEY ("timestamp", sensor_id, measurement_definition_id);
ALTER TABLE ONLY ventilation_milheiros.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (sensor_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_pkey PRIMARY KEY (event_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_scenarios
    ADD CONSTRAINT simulation_scenarios_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.simulation_scenarios
    ADD CONSTRAINT simulation_scenarios_pkey PRIMARY KEY (scenario_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_values
    ADD CONSTRAINT simulation_values_pkey PRIMARY KEY (simulation_value_id);
ALTER TABLE ONLY ventilation_milheiros.solver_actuator_results
    ADD CONSTRAINT solver_actuator_results_pkey PRIMARY KEY (result_id);
ALTER TABLE ONLY ventilation_milheiros.solver_actuator_results
    ADD CONSTRAINT solver_actuator_results_solver_run_id_actuator_id_key UNIQUE (solver_run_id, actuator_id);
ALTER TABLE ONLY ventilation_milheiros.solver_config
    ADD CONSTRAINT solver_config_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.solver_config
    ADD CONSTRAINT solver_config_pkey PRIMARY KEY (solver_config_id);
ALTER TABLE ONLY ventilation_milheiros.solver_room_results
    ADD CONSTRAINT solver_room_results_pkey PRIMARY KEY (result_id);
ALTER TABLE ONLY ventilation_milheiros.solver_room_results
    ADD CONSTRAINT solver_room_results_solver_run_id_room_id_key UNIQUE (solver_run_id, room_id);
ALTER TABLE ONLY ventilation_milheiros.solver_runs
    ADD CONSTRAINT solver_runs_pkey PRIMARY KEY (solver_run_id);
ALTER TABLE ONLY ventilation_milheiros.usage_types
    ADD CONSTRAINT usage_types_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.usage_types
    ADD CONSTRAINT usage_types_pkey PRIMARY KEY (usage_type_id);
ALTER TABLE ONLY ventilation_milheiros.ventilation_systems
    ADD CONSTRAINT ventilation_systems_name_key UNIQUE (name);
ALTER TABLE ONLY ventilation_milheiros.ventilation_systems
    ADD CONSTRAINT ventilation_systems_pkey PRIMARY KEY (system_id);
ALTER TABLE ONLY ventilation_milheiros.actuator_characteristics
    ADD CONSTRAINT actuator_characteristics_actuator_id_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.actuator_characteristics
    ADD CONSTRAINT actuator_characteristics_characteristic_id_fkey FOREIGN KEY (characteristic_id) REFERENCES ventilation_milheiros.damper_characteristics(characteristic_id);
ALTER TABLE ONLY ventilation_milheiros.actuator_values
    ADD CONSTRAINT actuator_values_actuator_id_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.actuators
    ADD CONSTRAINT actuators_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES ventilation_milheiros.master_assemblies(assembly_id);
ALTER TABLE ONLY ventilation_milheiros.actuators
    ADD CONSTRAINT actuators_bus_device_id_fkey FOREIGN KEY (bus_device_id) REFERENCES ventilation_milheiros.bus_devices(bus_device_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_corridors
    ADD CONSTRAINT air_quality_corridors_source_id_fkey FOREIGN KEY (source_id) REFERENCES ventilation_milheiros.air_quality_sources(source_id);
ALTER TABLE ONLY ventilation_milheiros.air_quality_references
    ADD CONSTRAINT air_quality_references_source_id_fkey FOREIGN KEY (source_id) REFERENCES ventilation_milheiros.air_quality_sources(source_id);
ALTER TABLE ONLY ventilation_milheiros.bus_devices
    ADD CONSTRAINT bus_devices_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES ventilation_milheiros.master_assemblies(assembly_id);
ALTER TABLE ONLY ventilation_milheiros.bus_devices
    ADD CONSTRAINT bus_devices_bus_id_fkey FOREIGN KEY (bus_id) REFERENCES ventilation_milheiros.buses(bus_id);
ALTER TABLE ONLY ventilation_milheiros.bus_devices
    ADD CONSTRAINT bus_devices_i2c_bus_id_fkey FOREIGN KEY (i2c_bus_id) REFERENCES ventilation_milheiros.i2c_buses(i2c_bus_id);
ALTER TABLE ONLY ventilation_milheiros.bus_devices
    ADD CONSTRAINT bus_devices_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.buses
    ADD CONSTRAINT buses_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES ventilation_milheiros.master_assemblies(assembly_id);
ALTER TABLE ONLY ventilation_milheiros.buses
    ADD CONSTRAINT buses_bus_type_id_fkey FOREIGN KEY (bus_type_id) REFERENCES ventilation_milheiros.bus_types(bus_type_id);
ALTER TABLE ONLY ventilation_milheiros.damper_characteristics
    ADD CONSTRAINT damper_characteristics_source_id_fkey FOREIGN KEY (source_id) REFERENCES ventilation_milheiros.air_quality_sources(source_id);
ALTER TABLE ONLY ventilation_milheiros.damper_pressure_loss
    ADD CONSTRAINT damper_pressure_loss_characteristic_id_fkey FOREIGN KEY (characteristic_id) REFERENCES ventilation_milheiros.damper_characteristics(characteristic_id);
ALTER TABLE ONLY ventilation_milheiros.i2c_buses
    ADD CONSTRAINT i2c_buses_bus_id_fkey FOREIGN KEY (bus_id) REFERENCES ventilation_milheiros.buses(bus_id);
ALTER TABLE ONLY ventilation_milheiros.master_assemblies
    ADD CONSTRAINT master_assemblies_master_bom_id_fkey FOREIGN KEY (master_bom_id) REFERENCES ventilation_milheiros.master_bom(master_bom_id);
ALTER TABLE ONLY ventilation_milheiros.minimum_airflow_rates
    ADD CONSTRAINT minimum_airflow_rates_usage_type_id_fkey FOREIGN KEY (usage_type_id) REFERENCES ventilation_milheiros.usage_types(usage_type_id);
ALTER TABLE ONLY ventilation_milheiros.room_actuators
    ADD CONSTRAINT room_actuators_actuator_id_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.room_actuators
    ADD CONSTRAINT room_actuators_room_id_fkey FOREIGN KEY (room_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.room_air_quality_corridors
    ADD CONSTRAINT room_air_quality_corridors_corridor_id_fkey FOREIGN KEY (corridor_id) REFERENCES ventilation_milheiros.air_quality_corridors(corridor_id);
ALTER TABLE ONLY ventilation_milheiros.room_air_quality_corridors
    ADD CONSTRAINT room_air_quality_corridors_room_id_fkey FOREIGN KEY (room_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.room_connections
    ADD CONSTRAINT room_connections_room_a_id_fkey FOREIGN KEY (room_a_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.room_connections
    ADD CONSTRAINT room_connections_room_b_id_fkey FOREIGN KEY (room_b_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.room_connections
    ADD CONSTRAINT room_connections_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.room_sensors
    ADD CONSTRAINT room_sensors_bus_device_id_fkey FOREIGN KEY (bus_device_id) REFERENCES ventilation_milheiros.bus_devices(bus_device_id);
ALTER TABLE ONLY ventilation_milheiros.room_sensors
    ADD CONSTRAINT room_sensors_room_id_fkey FOREIGN KEY (room_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.room_sensors
    ADD CONSTRAINT room_sensors_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.rooms
    ADD CONSTRAINT rooms_usage_type_id_fkey FOREIGN KEY (usage_type_id) REFERENCES ventilation_milheiros.usage_types(usage_type_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_actuator_measurements
    ADD CONSTRAINT sensor_actuator_measurements_actuator_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_actuator_measurements
    ADD CONSTRAINT sensor_actuator_measurements_measurement_fkey FOREIGN KEY (measurement_definition_id) REFERENCES ventilation_milheiros.sensor_measurements(measurement_definition_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_measurements
    ADD CONSTRAINT sensor_measurements_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_values
    ADD CONSTRAINT sensor_values_measurement_definition_id_fkey FOREIGN KEY (measurement_definition_id) REFERENCES ventilation_milheiros.sensor_measurements(measurement_definition_id);
ALTER TABLE ONLY ventilation_milheiros.sensor_values
    ADD CONSTRAINT sensor_values_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.sensors
    ADD CONSTRAINT sensors_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES ventilation_milheiros.sensor_manufacturers(manufacturer_id);
ALTER TABLE ONLY ventilation_milheiros.sensors
    ADD CONSTRAINT sensors_sensor_class_id_fkey FOREIGN KEY (sensor_class_id) REFERENCES ventilation_milheiros.sensor_classes(sensor_class_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_actuator_id_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES ventilation_milheiros.room_connections(connection_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_room_id_fkey FOREIGN KEY (room_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES ventilation_milheiros.simulation_scenarios(scenario_id) ON DELETE CASCADE;
ALTER TABLE ONLY ventilation_milheiros.simulation_events
    ADD CONSTRAINT simulation_events_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_values
    ADD CONSTRAINT simulation_values_measurement_definition_id_fkey FOREIGN KEY (measurement_definition_id) REFERENCES ventilation_milheiros.sensor_measurements(measurement_definition_id);
ALTER TABLE ONLY ventilation_milheiros.simulation_values
    ADD CONSTRAINT simulation_values_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES ventilation_milheiros.simulation_scenarios(scenario_id) ON DELETE CASCADE;
ALTER TABLE ONLY ventilation_milheiros.simulation_values
    ADD CONSTRAINT simulation_values_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES ventilation_milheiros.sensors(sensor_id);
ALTER TABLE ONLY ventilation_milheiros.solver_actuator_results
    ADD CONSTRAINT solver_actuator_results_actuator_id_fkey FOREIGN KEY (actuator_id) REFERENCES ventilation_milheiros.actuators(actuator_id);
ALTER TABLE ONLY ventilation_milheiros.solver_actuator_results
    ADD CONSTRAINT solver_actuator_results_solver_run_id_fkey FOREIGN KEY (solver_run_id) REFERENCES ventilation_milheiros.solver_runs(solver_run_id) ON DELETE CASCADE;
ALTER TABLE ONLY ventilation_milheiros.solver_room_results
    ADD CONSTRAINT solver_room_results_room_id_fkey FOREIGN KEY (room_id) REFERENCES ventilation_milheiros.rooms(room_id);
ALTER TABLE ONLY ventilation_milheiros.solver_room_results
    ADD CONSTRAINT solver_room_results_solver_run_id_fkey FOREIGN KEY (solver_run_id) REFERENCES ventilation_milheiros.solver_runs(solver_run_id) ON DELETE CASCADE;
ALTER TABLE ONLY ventilation_milheiros.solver_runs
    ADD CONSTRAINT solver_runs_solver_config_id_fkey FOREIGN KEY (solver_config_id) REFERENCES ventilation_milheiros.solver_config(solver_config_id);
CREATE INDEX idx_room_connections_a ON ventilation_milheiros.room_connections USING btree (room_a_id);
CREATE INDEX idx_room_connections_b ON ventilation_milheiros.room_connections USING btree (room_b_id);
CREATE INDEX idx_sensor_actuator_measurements_actuator ON ventilation_milheiros.sensor_actuator_measurements USING btree (actuator_id);
CREATE INDEX idx_sensor_actuator_measurements_measurement ON ventilation_milheiros.sensor_actuator_measurements USING btree (measurement_definition_id);
CREATE INDEX idx_sensor_values_measurement_time ON ventilation_milheiros.sensor_values USING btree (measurement_definition_id, "timestamp" DESC);
CREATE INDEX idx_sensor_values_sensor_time ON ventilation_milheiros.sensor_values USING btree (sensor_id, "timestamp" DESC);
CREATE INDEX idx_simulation_events_scenario ON ventilation_milheiros.simulation_events USING btree (scenario_id);
CREATE INDEX idx_solver_runs_time ON ventilation_milheiros.solver_runs USING btree (started_at DESC);
