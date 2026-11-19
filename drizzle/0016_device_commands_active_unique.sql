CREATE UNIQUE INDEX "device_commands_active_port_unique" ON "device_commands" USING btree ("port_id") WHERE "device_commands"."port_id" IS NOT NULL
          AND "device_commands"."status" IN ('PENDING', 'SENT', 'ACKNOWLEDGED');--> statement-breakpoint
CREATE UNIQUE INDEX "device_commands_active_restart_unique" ON "device_commands" USING btree ("station_id") WHERE "device_commands"."command_type" = 'RESTART_STATION'
          AND "device_commands"."status" IN ('PENDING', 'SENT', 'ACKNOWLEDGED');