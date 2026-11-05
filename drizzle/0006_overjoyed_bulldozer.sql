CREATE TYPE "public"."telemetry_event_type" AS ENUM('HEARTBEAT', 'BATTERY_UPDATE', 'TEMPERATURE_UPDATE', 'PORT_STATUS_UPDATE', 'CHARGING_UPDATE', 'ERROR');--> statement-breakpoint
CREATE TABLE "telemetry" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"station_id" uuid NOT NULL,
	"port_id" uuid,
	"power_bank_id" uuid,
	"event_type" "telemetry_event_type" NOT NULL,
	"data" jsonb NOT NULL,
	"recorded_at" timestamp with time zone NOT NULL,
	"received_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "telemetry" ADD CONSTRAINT "telemetry_station_id_stations_id_fk" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "telemetry" ADD CONSTRAINT "telemetry_port_id_ports_id_fk" FOREIGN KEY ("port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "telemetry" ADD CONSTRAINT "telemetry_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "telemetry_station_id_idx" ON "telemetry" USING btree ("station_id");--> statement-breakpoint
CREATE INDEX "telemetry_power_bank_id_idx" ON "telemetry" USING btree ("power_bank_id");--> statement-breakpoint
CREATE INDEX "telemetry_recorded_at_idx" ON "telemetry" USING btree ("recorded_at");