CREATE TYPE "public"."transfer_mission_status" AS ENUM('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'PARTIALLY_COMPLETED', 'COMPLETED', 'CANCELLED');--> statement-breakpoint
CREATE TYPE "public"."transfer_mission_item_status" AS ENUM('PENDING', 'IN_TRANSIT', 'COMPLETED', 'FAILED', 'CANCELLED');--> statement-breakpoint
CREATE TYPE "public"."power_bank_movement_type" AS ENUM('INITIAL_PLACEMENT', 'RENTAL_PICKUP', 'RENTAL_RETURN', 'TRANSFER_OUT', 'TRANSFER_IN', 'MAINTENANCE_OUT', 'MAINTENANCE_RETURN');--> statement-breakpoint
ALTER TYPE "public"."power_bank_status" ADD VALUE 'RESERVED' BEFORE 'RENTED';--> statement-breakpoint
CREATE TABLE "transfer_missions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"source_station_id" uuid NOT NULL,
	"destination_station_id" uuid NOT NULL,
	"created_by" uuid NOT NULL,
	"assigned_to" uuid,
	"status" "transfer_mission_status" DEFAULT 'OPEN' NOT NULL,
	"accepted_at" timestamp with time zone,
	"started_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"cancelled_at" timestamp with time zone,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "transfer_missions_different_stations" CHECK ("transfer_missions"."source_station_id" <> "transfer_missions"."destination_station_id")
);
--> statement-breakpoint
CREATE TABLE "transfer_mission_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"mission_id" uuid NOT NULL,
	"power_bank_id" uuid NOT NULL,
	"from_port_id" uuid NOT NULL,
	"to_port_id" uuid,
	"status" "transfer_mission_item_status" DEFAULT 'PENDING' NOT NULL,
	"removed_at" timestamp with time zone,
	"received_at" timestamp with time zone,
	"failure_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "power_bank_movements" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"power_bank_id" uuid NOT NULL,
	"from_station_id" uuid,
	"from_port_id" uuid,
	"to_station_id" uuid,
	"to_port_id" uuid,
	"performed_by" uuid,
	"movement_type" "power_bank_movement_type" NOT NULL,
	"rental_id" uuid,
	"transfer_mission_item_id" uuid,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "power_bank_movements_from_location_pair_check" CHECK (("power_bank_movements"."from_station_id" IS NULL) = ("power_bank_movements"."from_port_id" IS NULL)),
	CONSTRAINT "power_bank_movements_to_location_pair_check" CHECK (("power_bank_movements"."to_station_id" IS NULL) = ("power_bank_movements"."to_port_id" IS NULL))
);
--> statement-breakpoint
ALTER TABLE "transfer_missions" ADD CONSTRAINT "transfer_missions_source_station_id_stations_id_fk" FOREIGN KEY ("source_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_missions" ADD CONSTRAINT "transfer_missions_destination_station_id_stations_id_fk" FOREIGN KEY ("destination_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_missions" ADD CONSTRAINT "transfer_missions_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_missions" ADD CONSTRAINT "transfer_missions_assigned_to_users_id_fk" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_mission_items" ADD CONSTRAINT "transfer_mission_items_mission_id_transfer_missions_id_fk" FOREIGN KEY ("mission_id") REFERENCES "public"."transfer_missions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_mission_items" ADD CONSTRAINT "transfer_mission_items_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_mission_items" ADD CONSTRAINT "transfer_mission_items_from_port_id_ports_id_fk" FOREIGN KEY ("from_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transfer_mission_items" ADD CONSTRAINT "transfer_mission_items_to_port_id_ports_id_fk" FOREIGN KEY ("to_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_from_station_id_stations_id_fk" FOREIGN KEY ("from_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_from_port_id_ports_id_fk" FOREIGN KEY ("from_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_to_station_id_stations_id_fk" FOREIGN KEY ("to_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_to_port_id_ports_id_fk" FOREIGN KEY ("to_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_performed_by_users_id_fk" FOREIGN KEY ("performed_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_rental_id_rentals_id_fk" FOREIGN KEY ("rental_id") REFERENCES "public"."rentals"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "power_bank_movements" ADD CONSTRAINT "power_bank_movements_transfer_mission_item_id_transfer_mission_items_id_fk" FOREIGN KEY ("transfer_mission_item_id") REFERENCES "public"."transfer_mission_items"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "transfer_missions_status_idx" ON "transfer_missions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "transfer_missions_assigned_to_idx" ON "transfer_missions" USING btree ("assigned_to");--> statement-breakpoint
CREATE INDEX "transfer_missions_source_station_idx" ON "transfer_missions" USING btree ("source_station_id");--> statement-breakpoint
CREATE INDEX "transfer_missions_destination_station_idx" ON "transfer_missions" USING btree ("destination_station_id");--> statement-breakpoint
CREATE UNIQUE INDEX "transfer_mission_items_mission_power_bank_unique" ON "transfer_mission_items" USING btree ("mission_id","power_bank_id");--> statement-breakpoint
CREATE UNIQUE INDEX "transfer_mission_items_active_power_bank_unique" ON "transfer_mission_items" USING btree ("power_bank_id") WHERE "transfer_mission_items"."status" IN ('PENDING', 'IN_TRANSIT', 'FAILED');--> statement-breakpoint
CREATE INDEX "transfer_mission_items_mission_id_idx" ON "transfer_mission_items" USING btree ("mission_id");--> statement-breakpoint
CREATE INDEX "transfer_mission_items_power_bank_id_idx" ON "transfer_mission_items" USING btree ("power_bank_id");--> statement-breakpoint
CREATE INDEX "power_bank_movements_power_bank_id_idx" ON "power_bank_movements" USING btree ("power_bank_id");--> statement-breakpoint
CREATE INDEX "power_bank_movements_performed_by_idx" ON "power_bank_movements" USING btree ("performed_by");--> statement-breakpoint
CREATE INDEX "power_bank_movements_rental_id_idx" ON "power_bank_movements" USING btree ("rental_id");--> statement-breakpoint
CREATE INDEX "power_bank_movements_created_at_idx" ON "power_bank_movements" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "power_bank_movements_transfer_item_type_unique" ON "power_bank_movements" USING btree ("transfer_mission_item_id","movement_type") WHERE "power_bank_movements"."transfer_mission_item_id" IS NOT NULL;