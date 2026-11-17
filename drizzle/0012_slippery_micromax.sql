CREATE TYPE "public"."notification_delivery_status" AS ENUM('PENDING', 'PROCESSING', 'SENT', 'FAILED', 'CANCELLED');--> statement-breakpoint
CREATE TABLE "notification_deliveries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"notification_id" uuid NOT NULL,
	"user_device_id" uuid NOT NULL,
	"status" "notification_delivery_status" DEFAULT 'PENDING' NOT NULL,
	"attempt_count" integer DEFAULT 0 NOT NULL,
	"max_attempts" integer DEFAULT 5 NOT NULL,
	"next_attempt_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_attempt_at" timestamp with time zone,
	"locked_until" timestamp with time zone,
	"sent_at" timestamp with time zone,
	"failed_at" timestamp with time zone,
	"last_error_code" varchar(100),
	"last_error_message" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "notification_deliveries_attempt_count_check" CHECK ("notification_deliveries"."attempt_count" >= 0
        AND "notification_deliveries"."attempt_count" <= "notification_deliveries"."max_attempts"),
	CONSTRAINT "notification_deliveries_max_attempts_check" CHECK ("notification_deliveries"."max_attempts" > 0)
);
--> statement-breakpoint
ALTER TABLE "notification_deliveries" ADD CONSTRAINT "notification_deliveries_notification_id_notifications_id_fk" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notification_deliveries" ADD CONSTRAINT "notification_deliveries_user_device_id_user_devices_id_fk" FOREIGN KEY ("user_device_id") REFERENCES "public"."user_devices"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "notification_deliveries_notification_device_unique" ON "notification_deliveries" USING btree ("notification_id","user_device_id");--> statement-breakpoint
CREATE INDEX "notification_deliveries_device_id_idx" ON "notification_deliveries" USING btree ("user_device_id");--> statement-breakpoint
CREATE INDEX "notification_deliveries_status_next_attempt_idx" ON "notification_deliveries" USING btree ("status","next_attempt_at");