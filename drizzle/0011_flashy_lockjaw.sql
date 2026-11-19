
CREATE TYPE "public"."device_platform" AS ENUM('ANDROID', 'IOS');
--> statement-breakpoint

CREATE TABLE "user_devices" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    "user_id" uuid NOT NULL,
    "installation_id" uuid NOT NULL,
    "fcm_token" text NOT NULL,
    "platform" "device_platform" NOT NULL,
    "device_name" varchar(150),
    "device_model" varchar(150),
    "app_version" varchar(50),
    "is_active" boolean DEFAULT true NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint

ALTER TABLE "user_devices"
ADD CONSTRAINT "user_devices_user_id_users_id_fk"
FOREIGN KEY ("user_id")
REFERENCES "public"."users"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint

CREATE UNIQUE INDEX "user_devices_installation_id_unique"
ON "user_devices" USING btree ("installation_id");
--> statement-breakpoint

CREATE UNIQUE INDEX "user_devices_fcm_token_unique"
ON "user_devices" USING btree ("fcm_token");
--> statement-breakpoint

CREATE INDEX "user_devices_user_id_idx"
ON "user_devices" USING btree ("user_id");
--> statement-breakpoint

CREATE INDEX "user_devices_user_active_idx"
ON "user_devices" USING btree ("user_id", "is_active");
