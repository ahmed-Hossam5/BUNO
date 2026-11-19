CREATE TYPE "public"."rental_status" AS ENUM('PENDING', 'ACTIVE', 'RETURNED', 'CANCELLED');--> statement-breakpoint
CREATE TABLE "rentals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"power_bank_id" uuid NOT NULL,
	"pickup_station_id" uuid NOT NULL,
	"pickup_port_id" uuid NOT NULL,
	"return_station_id" uuid,
	"return_port_id" uuid,
	"status" "rental_status" DEFAULT 'PENDING' NOT NULL,
	"started_at" timestamp with time zone,
	"returned_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_power_bank_id_power_banks_id_fk" FOREIGN KEY ("power_bank_id") REFERENCES "public"."power_banks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_pickup_station_id_stations_id_fk" FOREIGN KEY ("pickup_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_pickup_port_id_ports_id_fk" FOREIGN KEY ("pickup_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_return_station_id_stations_id_fk" FOREIGN KEY ("return_station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rentals" ADD CONSTRAINT "rentals_return_port_id_ports_id_fk" FOREIGN KEY ("return_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "one_active_rental_per_user" ON "rentals" USING btree ("user_id") WHERE "rentals"."status" IN ('PENDING', 'ACTIVE');