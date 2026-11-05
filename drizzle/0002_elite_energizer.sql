ALTER TABLE "ports" DROP CONSTRAINT "ports_station_id_stations_id_fk";
--> statement-breakpoint
ALTER TABLE "ports" ADD CONSTRAINT "ports_station_id_stations_id_fk" FOREIGN KEY ("station_id") REFERENCES "public"."stations"("id") ON DELETE no action ON UPDATE no action;