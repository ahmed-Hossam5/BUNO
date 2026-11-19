-- Audit logs are an append-only ledger.
-- Any UPDATE or DELETE on audit_logs is rejected at the database level,
-- so history cannot be altered even by application bugs.
-- (TRUNCATE is intentionally not blocked, to keep test setup simple.)
CREATE OR REPLACE FUNCTION audit_logs_prevent_modification()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only: % is not allowed', TG_OP
    USING ERRCODE = '55000';
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
CREATE TRIGGER audit_logs_immutable_trg
BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION audit_logs_prevent_modification();
