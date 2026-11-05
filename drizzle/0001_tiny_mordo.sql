CREATE TYPE "public"."station_status" AS ENUM('ONLINE', 'OFFLINE', 'MAINTENANCE');--> statement-breakpoint
CREATE TYPE "public"."port_status" AS ENUM('EMPTY', 'OCCUPIED', 'DISABLED', 'MAINTENANCE');--> statement-breakpoint
CREATE TABLE "stations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"station_code" varchar(50) NOT NULL,
	"name" varchar(150) NOT NULL,
	"total_ports" integer DEFAULT 4 NOT NULL,
	"status" "station_status" DEFAULT 'OFFLINE' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "stations_station_code_unique" UNIQUE("station_code")
);
--> statement-breakpoint
CREATE TABLE "ports" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"station_id" uuid NOT NULL,
	"port_number" integer NOT NULL,
	"status" "port_status" DEFAULT 'EMPTY' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "station_port_number_unique" UNIQUE("station_id","port_number")
);
--> statement-breakpoint
ALTER TABLE "ports" ADD CONSTRAINT "ports_station_id_stations_id_fk" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;