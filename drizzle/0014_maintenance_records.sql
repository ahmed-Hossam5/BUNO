CREATE TYPE "public"."maintenance_priority" AS ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');--> statement-breakpoint
CREATE TYPE "public"."maintenance_status" AS ENUM('OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');--> statement-breakpoint
CREATE TYPE "public"."maintenance_target_type" AS ENUM('STATION', 'PORT', 'POWER_BANK');--> statement-breakpoint
CREATE TYPE "public"."maintenance_type" AS ENUM('PREVENTIVE', 'CORRECTIVE', 'INSPECTION');--> statement-breakpoint
CREATE TABLE "maintenance_records" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"target_type" "maintenance_target_type" NOT NULL,
	"station_id" uuid,
	"port_id" uuid,
	"power_bank_id" uuid,
	"maintenance_type" "maintenance_type" NOT NULL,
	"priority" "maintenance_priority" DEFAULT 'MEDIUM' NOT NULL,
	"status" "maintenance_status" DEFAULT 'OPEN' NOT NULL,
	"title" varchar(200) NOT NULL,
	"description" text,
	"resolution_notes" text,
	"previous_status" varchar(30),
	"reported_by" uuid NOT NULL,
	"assigned_to" uuid,
	"started_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"cancelled_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "maintenance_records_target_shape_check" CHECK ((
        "maintenance_records"."target_type" = 'STATION'
        AND "maintenance_records"."station_id" IS NOT NULL
        AND "maintenance_records"."port_id" IS NULL
        AND "maintenance_records"."power_bank_id" IS NULL
      ) OR (
        "maintenance_records"."target_type" = 'PORT'
        AND "maintenance_records"."station_id" IS NOT NULL
        AND "maintenance_records"."port_id" IS NOT NULL
        AND "maintenance_records"."power_bank_id" IS NULL
      ) OR (
        "maintenance_records"."target_type" = 'POWER_BANK'
        AND "maintenance_records"."power_bank_id" IS NOT NULL
        AND "maintenance_records"."station_id" IS NULL
        AND "maintenance_records"."port_id" IS NULL
      ))
);
--> statement-breakpoint
ALTER TABLE "maintenance_records" ADD CONSTRAINT "maintenance_records_station_id_stations_id_fk" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "maintenance_records" ADD CONSTRAINT "maintenance_records_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "maintenance_records" ADD CONSTRAINT "maintenance_records_reported_by_users_id_fk" FOREIGN KEY ("reported_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "maintenance_records" ADD CONSTRAINT "maintenance_records_assigned_to_users_id_fk" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "maintenance_records" ADD CONSTRAINT "maintenance_records_port_station_fk" FOREIGN KEY ("station_id","port_id") REFERENCES "public"."ports"("station_id","id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "maintenance_active_station_unique" ON "maintenance_records" USING btree ("station_id") WHERE "maintenance_records"."target_type" = 'STATION'
          AND "maintenance_records"."status" IN ('OPEN', 'IN_PROGRESS');--> statement-breakpoint
CREATE UNIQUE INDEX "maintenance_active_port_unique" ON "maintenance_records" USING btree ("port_id") WHERE "maintenance_records"."target_type" = 'PORT'
          AND "maintenance_records"."status" IN ('OPEN', 'IN_PROGRESS');--> statement-breakpoint
CREATE UNIQUE INDEX "maintenance_active_power_bank_unique" ON "maintenance_records" USING btree ("power_bank_id") WHERE "maintenance_records"."target_type" = 'POWER_BANK'
          AND "maintenance_records"."status" IN ('OPEN', 'IN_PROGRESS');--> statement-breakpoint
CREATE INDEX "maintenance_records_status_idx" ON "maintenance_records" USING btree ("status");--> statement-breakpoint
CREATE INDEX "maintenance_records_station_id_idx" ON "maintenance_records" USING btree ("station_id");--> statement-breakpoint
CREATE INDEX "maintenance_records_port_id_idx" ON "maintenance_records" USING btree ("port_id");--> statement-breakpoint
CREATE INDEX "maintenance_records_power_bank_id_idx" ON "maintenance_records" USING btree ("power_bank_id");--> statement-breakpoint
CREATE INDEX "maintenance_records_assigned_to_idx" ON "maintenance_records" USING btree ("assigned_to");--> statement-breakpoint
CREATE INDEX "maintenance_records_created_at_idx" ON "maintenance_records" USING btree ("created_at");