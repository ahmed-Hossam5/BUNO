
-- ==========================================
-- 1. CREATE UNIQUE KEYS REQUIRED BY FOREIGN KEYS
-- ==========================================

CREATE UNIQUE INDEX "transfer_missions_id_source_station_unique"
ON "transfer_missions" USING btree ("id", "source_station_id");

--> statement-breakpoint

CREATE UNIQUE INDEX "transfer_missions_id_destination_station_unique"
ON "transfer_missions" USING btree ("id", "destination_station_id");

--> statement-breakpoint

ALTER TABLE "ports"
ADD CONSTRAINT "ports_station_id_id_unique"
UNIQUE ("station_id", "id");

--> statement-breakpoint


-- ==========================================
-- 2. ADD NEW COLUMNS TO TRANSFER MISSION ITEMS
-- ==========================================

ALTER TABLE "transfer_mission_items"
ADD COLUMN "from_station_id" uuid;

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
ADD COLUMN "to_station_id" uuid;

--> statement-breakpoint


-- ==========================================
-- 3. BACKFILL EXISTING DATA
-- ==========================================

UPDATE "transfer_mission_items" AS item
SET
    "from_station_id" = mission."source_station_id",
    "to_station_id" = mission."destination_station_id"
FROM "transfer_missions" AS mission
WHERE item."mission_id" = mission."id";

--> statement-breakpoint


-- ==========================================
-- 4. MAKE NEW COLUMNS NOT NULL
-- ==========================================

ALTER TABLE "transfer_mission_items"
ALTER COLUMN "from_station_id" SET NOT NULL;

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
ALTER COLUMN "to_station_id" SET NOT NULL;

--> statement-breakpoint


-- ==========================================
-- 5. DROP OLD FOREIGN KEYS
-- ==========================================

ALTER TABLE "device_commands"
DROP CONSTRAINT "device_commands_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "rentals"
DROP CONSTRAINT "rentals_pickup_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "rentals"
DROP CONSTRAINT "rentals_return_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "telemetry"
DROP CONSTRAINT "telemetry_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
DROP CONSTRAINT "transfer_mission_items_mission_id_transfer_missions_id_fk";

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
DROP CONSTRAINT "transfer_mission_items_from_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
DROP CONSTRAINT "transfer_mission_items_to_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "power_bank_movements"
DROP CONSTRAINT "power_bank_movements_from_station_id_stations_id_fk";

--> statement-breakpoint

ALTER TABLE "power_bank_movements"
DROP CONSTRAINT "power_bank_movements_from_port_id_ports_id_fk";

--> statement-breakpoint

ALTER TABLE "power_bank_movements"
DROP CONSTRAINT "power_bank_movements_to_station_id_stations_id_fk";

--> statement-breakpoint

ALTER TABLE "power_bank_movements"
DROP CONSTRAINT "power_bank_movements_to_port_id_ports_id_fk";

--> statement-breakpoint


-- ==========================================
-- 6. DEVICE COMMANDS COMPOSITE FOREIGN KEY
-- ==========================================

ALTER TABLE "device_commands"
ADD CONSTRAINT "device_commands_port_station_fk"
FOREIGN KEY ("station_id", "port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint


-- ==========================================
-- 7. RENTALS COMPOSITE FOREIGN KEYS
-- ==========================================

ALTER TABLE "rentals"
ADD CONSTRAINT "rentals_pickup_port_station_fk"
FOREIGN KEY ("pickup_station_id", "pickup_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint

ALTER TABLE "rentals"
ADD CONSTRAINT "rentals_return_port_station_fk"
FOREIGN KEY ("return_station_id", "return_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint


-- ==========================================
-- 8. TELEMETRY COMPOSITE FOREIGN KEY
-- ==========================================

ALTER TABLE "telemetry"
ADD CONSTRAINT "telemetry_port_station_fk"
FOREIGN KEY ("station_id", "port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint


-- ==========================================
-- 9. TRANSFER MISSION ITEMS COMPOSITE FOREIGN KEYS
-- ==========================================

ALTER TABLE "transfer_mission_items"
ADD CONSTRAINT "transfer_items_mission_source_fk"
FOREIGN KEY ("mission_id", "from_station_id")
REFERENCES "public"."transfer_missions" ("id", "source_station_id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
ADD CONSTRAINT "transfer_items_mission_destination_fk"
FOREIGN KEY ("mission_id", "to_station_id")
REFERENCES "public"."transfer_missions" ("id", "destination_station_id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
ADD CONSTRAINT "transfer_items_from_port_station_fk"
FOREIGN KEY ("from_station_id", "from_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint

ALTER TABLE "transfer_mission_items"
ADD CONSTRAINT "transfer_items_to_port_station_fk"
FOREIGN KEY ("to_station_id", "to_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint


-- ==========================================
-- 10. POWER BANK MOVEMENTS COMPOSITE FOREIGN KEYS
-- ==========================================

ALTER TABLE "power_bank_movements"
ADD CONSTRAINT "power_bank_movements_from_port_station_fk"
FOREIGN KEY ("from_station_id", "from_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint

ALTER TABLE "power_bank_movements"
ADD CONSTRAINT "power_bank_movements_to_port_station_fk"
FOREIGN KEY ("to_station_id", "to_port_id")
REFERENCES "public"."ports" ("station_id", "id")
ON DELETE NO ACTION ON UPDATE NO ACTION;

--> statement-breakpoint


-- ==========================================
-- 11. PREVENT DUPLICATE ACTIVE RENTALS
-- ==========================================

CREATE UNIQUE INDEX "one_active_rental_per_power_bank"
ON "rentals" USING btree ("power_bank_id")
WHERE "rentals"."status" IN ('PENDING', 'ACTIVE');

--> statement-breakpoint


-- ==========================================
-- 12. VALIDATE RENTAL RETURN LOCATION
-- ==========================================

ALTER TABLE "rentals"
ADD CONSTRAINT "rentals_return_location_pair_check"
CHECK (
    ("return_station_id" IS NULL) =
    ("return_port_id" IS NULL)
);

--> statement-breakpoint
