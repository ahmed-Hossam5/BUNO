CREATE TYPE "public"."power_bank_status" AS ENUM('AVAILABLE', 'RENTED', 'MAINTENANCE', 'LOST');--> statement-breakpoint
CREATE TABLE "power_banks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"device_identifier" varchar(100) NOT NULL,
	"status" "power_bank_status" DEFAULT 'AVAILABLE' NOT NULL,
	"current_port_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "power_banks_device_identifier_unique" UNIQUE("device_identifier"),
	CONSTRAINT "power_banks_current_port_id_unique" UNIQUE("current_port_id")
);
--> statement-breakpoint
ALTER TABLE "power_banks" ADD CONSTRAINT "power_banks_current_port_id_ports_id_fk" FOREIGN KEY ("current_port_id") REFERENCES "public"."ports"("id") ON DELETE no action ON UPDATE no action;