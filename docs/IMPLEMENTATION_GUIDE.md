# BUNO Backend: دليل التنفيذ (Audit Logs · Device Commands · Maintenance)

> آخر تحديث: نوفمبر 2026 · مكتوب بالعربي مع إبقاء المصطلحات التقنية بالإنجليزي.

---

## 1) الملخص السريع

| المطلوب | الحالة | ملاحظة |
|---|---|---|
| **Audit Logs** | ✅ مكتمل | تسجيل داخل نفس الـ transaction + قراءة للـ Admin فقط + سجل لا يتعدّل ولا يتمسح (حماية في الـ DB) |
| **Device Commands** | ✅ مكتمل | API للموظفين + API للجهاز (poll / ack / result) + انتهاء صلاحية تلقائي |
| **Maintenance** | ✅ مكتمل | **كان مفيش جدول أصلاً**، اتعمل schema + migration + lifecycle كامل |
| فحص الأغلاط | ✅ اتلقى **3 bugs حقيقية** واتصلحوا | تفاصيلهم في القسم 3 |
| الاختبارات | ✅ 46 اختبار integration على PostgreSQL حقيقي | + اتأكدت إنها بتفشل لما الكود يتكسر (mutation checks) |

نتيجة الفحص النهائي: `tsc` ✅ · `nest build` ✅ · `oxlint` 0 errors ✅ · `drizzle-kit check` ✅ · الـ migrations بتشتغل من الصفر ✅.

---

## 2) فهم الـ Schema (اللي اشتغلت عليه)

```
users ─┬─< auth_sessions
       ├─< audit_logs            (userId nullable: system / device actions)
       ├─< device_commands       (requestedBy nullable)
       └─< maintenance_records   (reportedBy, assignedTo)         ← جدول جديد

stations ─┬─< ports  (unique: stationId+portNumber)
          ├─< device_commands    (FK مركّب: stationId+portId → ports)
          └─< maintenance_records

ports ──── powerBanks.currentPortId (unique: بنك واحد في كل port)
power_banks ─< power_bank_movements (INITIAL_PLACEMENT, MAINTENANCE_OUT, MAINTENANCE_RETURN, ...)
```

**حالات مهمة:**
- Station: `ONLINE | OFFLINE | MAINTENANCE`
- Port: `EMPTY | OCCUPIED | DISABLED | MAINTENANCE`
- PowerBank: `AVAILABLE | RESERVED | RENTED | MAINTENANCE | LOST`

**قاعدة ذهبية في المشروع:** أي تغيير حالة بيتعمل جوه `transaction` مع قفل الصف `FOR UPDATE`. اتبعت نفس الأسلوب في كل الكود الجديد.

---

## 3) ⚠️ الأغلاط اللي لقيتها واتصلحت

### Bug 1: الـ Notification Worker عمره ما اشتغل
`NotificationDeliveryWorker` فيه `@Interval(5000)` لكن `ScheduleModule.forRoot()` **مكانش متسجل** في `app.module.ts` (كان مستورد بس غير مستخدم).
- **الأثر:** الإشعارات اللي في الـ queue عمرها ما اتبعتت.
- **الإصلاح:** إضافة `ScheduleModule.forRoot()`.
- **إثبات:** شغّلت الـ AppModule الحقيقي: قبل الإصلاح `SchedulerRegistry` مش موجود أصلاً، وبعده بيتسجل job الإشعارات + الـ sweeper بتاع الـ commands.

### Bug 2: أخطاء الـ Duplicate بترجع 500 بدل 409
الكود كان بيفحص `error.code === '23505'`، لكن drizzle-orm بيلف الخطأ في `DrizzleQueryError` والكود الأصلي جوه `error.cause`، فالفحص عمره ما كان بيطابق.
- **الأثر:** تسجيل بإيميل مكرر، أو station / power bank بكود مكرر → المستخدم بياخد **500** بدل **409 Conflict**.
- **الإصلاح:** helper مشترك `src/database/database-errors.ts` بيفحص سلسلة الـ `cause`، واتطبق في 4 أماكن (auth / stations ×2 / power-banks).
- **إثبات:** `test/regressions.e2e-spec.ts` (4 اختبارات؛ بتفشل لو رجّعت الكود القديم).

### Bug 3: تكرار في `schema/index.ts`
`notifications.schema` كان متصدّر مرتين. اتشال التكرار (مكانش بيكسر حاجة، بس تنضيف).

---

## 4) اللي اتعمل (الملفات)

### جديد
| الملف | الغرض |
|---|---|
| `src/database/schema/maintenance.schema.ts` | جدول `maintenance_records` |
| `drizzle/0014_maintenance_records.sql` | migration الجدول |
| `drizzle/0015_audit_logs_immutable.sql` | trigger بيمنع UPDATE/DELETE على `audit_logs` |
| `drizzle/0016_device_commands_active_unique.sql` | قيود فريدة للأوامر النشطة |
| `src/database/database-errors.ts` | helpers لأخطاء Postgres |
| `src/modules/auth/guards/roles.guard.ts` + `decorators/roles.decorator.ts` | `@Roles()` + `RolesGuard` |
| `src/modules/audit-logs/*` | service / controller / DTO / `@ClientIp()` |
| `src/modules/device-commands/*` | service / 2 controllers / sweeper / guard / DTOs |
| `src/modules/maintenance/*` | service / controller / DTOs |
| `test/*.e2e-spec.ts` + `test/helpers/test-app.ts` | 46 اختبار |
| `.env.example` | المتغيرات المطلوبة |

### معدّل (بأقل تغيير)
`app.module.ts` (ScheduleModule) · `schema/index.ts` · `schema/device-commands.schema.ts` (إضافة الـ 2 unique index فقط) · `auth.service.ts` · `stations.service.ts` · `power-banks.service.ts` (إصلاح Bug 2 فقط) · `drizzle/meta/*` (تلقائي من drizzle-kit)

> `package.json` و`package-lock.json` **ما اتغيروش** (مفيش dependencies جديدة).

> `RolesGuard` **fail-closed**: لو route عليه الـ guard من غير `@Roles()` بيترفض. و`SUPER_ADMIN` بيعدّي دايماً.

---

## 5) Audit Logs

**`AuditLogsService.record(entry, tx?)`**: أي مديول بيستخدمه (المديول `@Global`). لو مررت الـ `tx`، سطر الـ audit بيتعمل commit/rollback **مع** التغيير نفسه، فمستحيل يحصل تغيير من غير أثر.

**ضمانات:**
- **Redaction:** أي key فيه `password / token / secret / hash / apiKey / credential` بيتخزّن `[REDACTED]`.
- **Append-only على مستوى الـ DB:** trigger بيرفض `UPDATE`/`DELETE` (error `55000`) حتى لو فيه bug في الكود.
- **IP:** بيتطبّع (`::ffff:` بيتشال) ولا بيتخزن غير IP صالح لعمود `inet`.

| Endpoint | الصلاحية |
|---|---|
| `GET /audit-logs` | ADMIN / SUPER_ADMIN |
| `GET /audit-logs/:id` | ADMIN / SUPER_ADMIN |

فلاتر: `userId, action, entityType, entityId, from, to, page, limit`. مفيش POST/PATCH/DELETE (للقراءة فقط عن قصد).

**بيتسجل تلقائياً:** كل عمليات الـ Device Commands والـ Maintenance (وتغييرات حالة الـ station/port/power bank الناتجة عنها).

---

## 6) Device Commands

### State machine
```
PENDING ──► SENT ──► ACKNOWLEDGED ──► SUCCEEDED
   │          │            │       └─► FAILED
   │          └────────────┴─────────► TIMED_OUT   (انتهت المهلة)
   └──► CANCELLED   (والـ PENDING بس)
```
الجهاز ممكن يبعت النتيجة مباشرة من `SENT`، وممكن يبلّغ نتيجة **متأخرة** لأمر `TIMED_OUT` (لأن اللي حصل فيزيائياً هو الحقيقة)، وبيتسجل `lateResult` في الـ audit.

### Endpoints للموظفين (ADMIN / TECHNICIAN)
| Method | Path | الوظيفة |
|---|---|---|
| POST | `/device-commands` | إنشاء أمر |
| GET | `/device-commands` | قائمة + فلاتر |
| GET | `/device-commands/:id` | تفاصيل |
| PATCH | `/device-commands/:id/cancel` | إلغاء (PENDING فقط) |

أنواع الأوامر: `RELEASE_POWER_BANK, UNLOCK_PORT, LOCK_PORT, STOP_CHARGING, RESTART_STATION`.

**قواعد التحقق:**
- `RESTART_STATION` ممنوع معاه `portId`، وكل الباقي لازم `portId` تابع لنفس الـ station.
- الـ station `OFFLINE` ← مرفوض. `RELEASE_POWER_BANK` يحتاج station `ONLINE` + port `OCCUPIED` + بنك `AVAILABLE|RESERVED` (الـ `powerBankId` بيتحدد تلقائياً).
- **أمر نشط واحد فقط لكل port**، و`RESTART_STATION` نشط واحد لكل station.
- مهلة افتراضية: 60 ثانية للـ release، 300 للباقي (`ttlSeconds` من 5 لـ 3600). حد أقصى للـ payload 4KB.

### Endpoints للجهاز (الـ firmware)
مصادقة بالهيدر `x-device-key` = `DEVICE_API_KEY`.

| Method | Path | الوظيفة |
|---|---|---|
| POST | `/device/stations/:stationId/commands/poll` | يسحب الأوامر (PENDING→SENT). الأوامر اللي لسه ما اتأكدتش بتتبعت تاني (الجهاز يفرز بـ `commandId`) |
| POST | `.../:commandId/ack` | استلمت وبدأت |
| POST | `.../:commandId/result` | `{ "success": true, "response": {...} }` |

كل العمليات **idempotent** (تكرار نفس الـ ack/result آمن، ونتيجة متعارضة = 409).

### الأمان وعدم التعارض (Concurrency)
1. قفل الـ station/port (`FOR NO KEY UPDATE`) أثناء الإنشاء.
2. **قيود فريدة جزئية في الـ DB** (`0016`) بتضمن القاعدة حتى لو طلبين عدّوا الفحص مع بعض. اكتشفت ده بـ mutation test: لما شلت الـ locks الاختبار لسه نجح، فعرفت إن الضمان كان معتمد على الكود بس، فاتضاف القيد.
3. الـ `poll` بيستخدم `FOR UPDATE SKIP LOCKED` فمفيش جهازين ياخدوا نفس الأمر.
4. **Sweeper** كل 10 ثواني بيحوّل الأوامر المنتهية لـ `TIMED_OUT`.

---

## 7) Maintenance

### Lifecycle
```
OPEN ──start──► IN_PROGRESS ──complete──► COMPLETED
  │                  │
  └──────cancel──────┴──► CANCELLED   (و IN_PROGRESS بيرجّع الهدف لحالته)
```
`OPEN` بس تذكرة، **مش بتلمس الهدف**. `start` هو اللي بيحط الهدف في `MAINTENANCE`.

| الهدف | عند `start` | عند `complete` |
|---|---|---|
| **STATION** | `→ MAINTENANCE` (بيحفظ الحالة القديمة) | يرجع للحالة القديمة، أو `stationStatusAfter` (`ONLINE`/`OFFLINE`) |
| **PORT** | لازم `EMPTY` أو `DISABLED` ← `MAINTENANCE` | `→ EMPTY` |
| **POWER_BANK** | لازم `AVAILABLE`؛ بيتشال من الـ port (`MAINTENANCE_OUT`) | `AVAILABLE`، ولو `returnPortId` اتبعت بيتحط في port فاضي (`MAINTENANCE_RETURN`) |

**موانع الـ start** (نفس قواعد `ports.service`): الـ port فيه بنك · فيه rental محجوز · فيه transfer نشط · فيه device command نشط · الـ station عليه rentals PENDING.

**ضمانات:** تذكرة نشطة واحدة لكل هدف (قيد فريد في الـ DB) · لو `complete` فشل في النص (مثلاً `returnPortId` مشغول) كل حاجة بترجع زي ما كانت (rollback) · الحالة لو اتغيّرت من برّه التذكرة بيرفض بـ 409.

### Endpoints (TECHNICIAN / ADMIN)
| Method | Path | ملاحظة |
|---|---|---|
| POST | `/maintenance` | `{ targetType, targetId, maintenanceType, priority?, title, description? }` |
| GET | `/maintenance` | فلاتر: `status, targetType, targetId, priority, assignedTo, maintenanceType` |
| GET | `/maintenance/:id` | مع اسم المُبلِّغ والمُكلَّف |
| PATCH | `/maintenance/:id/start` | الفني المُكلَّف أو Admin |
| PATCH | `/maintenance/:id/complete` | `resolutionNotes` إجباري |
| PATCH | `/maintenance/:id/cancel` | Admin / المُكلَّف / (المُبلِّغ لو OPEN) |
| PATCH | `/maintenance/:id/assign` | **ADMIN فقط**؛ الفني لازم يكون TECHNICIAN/ADMIN ونشط |

---

## 8) التشغيل والاختبار

```bash
cp .env.example .env            # واملا القيم (خصوصاً DEVICE_API_KEY)
npm ci
npm run db:migrate              # بيطبّق 0014 → 0016 على الجداول الحالية
npm run build && npm run lint

# الاختبارات تحتاج PostgreSQL حقيقي (DATABASE_URL)
npx vitest run --config vitest.config.e2e.ts \
  test/audit-logs.e2e-spec.ts test/regressions.e2e-spec.ts \
  test/device-commands.e2e-spec.ts test/maintenance.e2e-spec.ts
```
> ⚠️ ملف `0016` بيعمل unique index. لو في قاعدة بياناتك الحالية صفوف `device_commands` نشطة مكررة لنفس الـ port، الـ migration هيفشل: نضّفها الأول. (المديول كان فاضي فالأغلب مفيش.)

---

## 9) ⚠️ ملاحظات على الكود القديم (متغيّرتش، محتاجة قرارك)

1. **أخطر نقطة: Controllers من غير أي حماية:** `users` و`stations` و`ports` و`power-banks` مفيهمش `JwtAuthGuard`. أي حد يقدر يقرا/يعدّل/يمسح. أنا ما غيّرتهم لأن ده قرار منتج ممكن يكسر تطبيق الموبايل؛ الحل الجاهز: `@UseGuards(JwtAuthGuard, RolesGuard)` + `@Roles('ADMIN')` على عمليات التعديل.
2. `ObserveModule.forRoot` فيه `appKey: 'YOUR_APP_KEY'` placeholders.
3. `src/database.controller.ts` نسخة مكررة غير مستخدمة (المستخدم هو `src/database/database.controller.ts`)؛ تقدر تمسحها.
4. `test/app.e2e-spec.ts` القديم محتاج بيئة كاملة (Firebase + DB) ومتوقع `Hello World!`؛ غالباً بيفشل بدونها.
5. warning واحد قديم في `notifications.service.ts:740` (`no-base-to-string`).

## 10) حدود معروفة / خطوات قادمة
- **نجاح `RELEASE_POWER_BANK` مش بيغيّر حالة الـ port/البنك**؛ ده شغل مديول الـ rentals (لسه فاضي). الـ command بيسجّل نتيجة الجهاز بس. الـ rentals يستدعي `DeviceCommandsService.create()` (مُصدَّر من المديول).
- مفتاح الجهاز واحد للأسطول كله. الأفضل لاحقاً credential لكل station (مخزّن hashed).
- خلف reverse proxy فعّل `app.set('trust proxy', ...)` عشان الـ IP في الـ audit يبقى IP العميل الحقيقي.
- جدول `telemetry` ومديول الـ rentals لسه فاضيين؛ مش جزء من الطلب.
