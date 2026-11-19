// ==========================================
// POSTGRES ERROR HELPERS
// ==========================================
//
// drizzle-orm (>= 0.44) wraps driver errors in a
// DrizzleQueryError and keeps the original pg error
// in `error.cause`. Checking only `error.code` therefore
// never matches. These helpers inspect the whole cause
// chain so constraint violations are mapped correctly.

export const PG_UNIQUE_VIOLATION = '23505';
export const PG_FOREIGN_KEY_VIOLATION = '23503';
export const PG_CHECK_VIOLATION = '23514';

const MAX_CAUSE_DEPTH = 5;

export function getPgErrorCode(
  error: unknown,
): string | undefined {
  let current: unknown = error;

  for (
    let depth = 0;
    depth < MAX_CAUSE_DEPTH &&
    typeof current === 'object' &&
    current !== null;
    depth++
  ) {
    if (
      'code' in current &&
      typeof current.code === 'string'
    ) {
      return current.code;
    }

    current =
      'cause' in current ? current.cause : undefined;
  }

  return undefined;
}

export function getPgConstraintName(
  error: unknown,
): string | undefined {
  let current: unknown = error;

  for (
    let depth = 0;
    depth < MAX_CAUSE_DEPTH &&
    typeof current === 'object' &&
    current !== null;
    depth++
  ) {
    if (
      'constraint' in current &&
      typeof current.constraint === 'string'
    ) {
      return current.constraint;
    }

    current =
      'cause' in current ? current.cause : undefined;
  }

  return undefined;
}

export function isUniqueViolation(error: unknown): boolean {
  return getPgErrorCode(error) === PG_UNIQUE_VIOLATION;
}
