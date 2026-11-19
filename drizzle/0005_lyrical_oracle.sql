CREATE TYPE "public"."device_command_status" AS ENUM('PENDING', 'SENT', 'ACKNOWLEDGED', 'SUCCEEDED', 'FAILED', 'TIMED_OUT', 'CANCELLED');--> statement-breakpoint
CREATE TYPE "public"."device_command_type" AS ENUM('RELEASE_POWER_BANK', 'STOP_CHARGING', 'RESTART_STATION', 'LOCK_PORT', 'UNLOCK_PORT');--> statement-breakpoint
CREATE TABLE "device_commands" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"command_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"station_id" uuid NOT NULL,
	"port_id" uuid,
	"power_bank_id" uuid,
	"requested_by" uuid,
	"command_type" "device_command_type" NOT NULL,
	"status" "device_command_status" DEFAULT 'PENDING' NOT NULL,
	"payload" jsonb,
	"response" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"sent_at" timestamp with time zone,
	"acknowledged_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"expires_at" timestamp with time zone,
	CONSTRAINT "device_commands_command_id_unique" UNIQUE("command_id")
);
--> statement-breakpoint
ALTER TABLE "device_commands" ADD CONSTRAINT "device_commands_station_id_stations_id_fk" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "device_commands" ADD CONSTRAINT "device_commands_port_id_ports_id_fk" FOREIGN KEY ("port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "device_commands" ADD CONSTRAINT "device_commands_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "device_commands" ADD CONSTRAINT "device_commands_requested_by_users_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "device_commands_station_id_idx" ON "device_commands" USING btree ("station_id");--> statement-breakpoint
CREATE INDEX "device_commands_status_idx" ON "device_commands" USING btree ("status");--> statement-breakpoint
CREATE INDEX "device_commands_created_at_idx" ON "device_commands" USING btree ("created_at");