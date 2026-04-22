# Ignia Fungi — CRM & Production Manager on Salesforce

Salesforce DX project for managing mushroom cultivation operations: batch tracking, harvest logging, biological efficiency reporting, and bidirectional integration with a Laravel backend.

---

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── TriggerHandler.cls                    # Base trigger handler framework
│   ├── LoteHandler.cls                       # Trigger handler for Lote__c
│   ├── CosechaHandler.cls                    # Trigger handler for Cosecha__c
│   ├── LoteNombreService.cls                 # Business logic: auto-naming for Lote__c
│   ├── LoteService.cls                       # Business logic: biological efficiency calculation
│   ├── ActualizarTotalesLoteQueueable.cls    # Queueable: async update of harvest totals
│   ├── RecalcularEficienciaBatch.cls         # Batch: nightly efficiency recalculation
│   ├── RecalcularEficienciaScheduler.cls     # Scheduler: runs batch daily at 2am
│   ├── ArchivarLotesViejos.cls               # Batch: archives lotes inactive for 180+ days
│   ├── CosechaTimelineController.cls         # Controller: queries harvests and calculates accumulated weight
│   ├── CosechaTimelineControllerTest.cls     # Test class for CosechaTimelineController
│   ├── DashboardProduccionController.cls     # Controller: aggregates active lotes, harvests, and efficiency
│   ├── DashboardProduccionControllerTest.cls # Test class for DashboardProduccionController
│   ├── RegistrarCosechaController.cls        # Controller: creates new harvest records imperatively
│   └── RegistrarCosechaControllerTest.cls    # Test class for RegistrarCosechaController
├── triggers/
│   ├── LoteTrigger.trigger       # Lote__c trigger (all events)
│   └── CosechaTrigger.trigger    # Cosecha__c trigger (all events)
├── objects/
│   ├── Lote__c/                  # Batch object with custom fields + validation rules
│   ├── Cosecha__c/               # Harvest object with custom fields
│   └── Log_Proceso__c/           # Process execution log
├── permissionsets/
│   └── Igniafungi_Admin.permissionset-meta.xml
├── testSuites/
│   └── igniafungi.testSuite-meta.xml
├── lwc/
│   ├── loteCard/                 # LWC: production summary card for Lote__c record page
│   ├── cosechaTimeline/          # LWC: chronological harvest timeline with accumulated weight
│   ├── dashboardProduccion/      # LWC: global metrics for Home Page
│   └── registrarCosecha/         # LWC: quick-entry form to register a new harvest
└── manifest/
    └── package.xml               # Metadata manifest for org retrieval
```

---

## Custom Objects

### `Lote__c` — Production Batch

Represents a single mushroom cultivation batch from inoculation to harvest.

| Field | Type | Description |
|-------|------|-------------|
| `Name` | Text | Auto-generated as `[Cepa]-[Fecha_Inoculacion]` on every insert |
| `Eficiencia_Biologica__c` | Number(8,2) | Biological efficiency (%): `(total harvest / initial weight) * 100` |
| `Cepa__c` | Text(100) | Mushroom strain name |
| `Fecha_Inoculacion__c` | Date | Inoculation date |
| `Estado__c` | Picklist | Batch lifecycle status: `En Inoculación` · `En Colonización` · `En Producción` · `Finalizado` · `Archivado` |
| `Archivado__c` | Checkbox | `true` when the batch has been archived by the `ArchivarLotesViejos` batch |
| `Total_Cosechado_Kg__c` | Number(12,4) | Sum of all harvest weights in kg — updated asynchronously by `ActualizarTotalesLoteQueueable` |
| `Cantidad_Cosechas__c` | Number(10,0) | Count of harvest records — updated asynchronously by `ActualizarTotalesLoteQueueable` |
| `Tipo__c` | Text(20) | Batch type |
| `Codigo__c` | Text(50) | Internal batch code |
| `Peso_inicial_Kg__c` | Number(8,4) | Initial substrate weight in kg |
| `Cantidad__c` | Number | Quantity |
| `ignia_id__c` | Number (External ID) | ID from the Laravel system |

### `Cosecha__c` — Harvest

Records individual harvest events linked to a batch.

| Field | Type | Description |
|-------|------|-------------|
| `Lote__c` | Lookup(Lote__c) | Parent batch |
| `Peso_Kg__c` | Number | Harvested weight in kg |
| `Fecha_cosecha__c` | Date | Harvest date |
| `Notas__c` | Text | Operator notes |
| `Ignia_ID__c` | Number (External ID) | ID from the Laravel system |

---

## Trigger Handler Framework

### Overview

A lightweight virtual base class (`TriggerHandler`) that provides:

- **Single-entry routing** — one trigger per object delegates all events to a handler class.
- **Recursion prevention** — a static `Set<String> activeHandlers` blocks re-entrant execution of the same handler within a single transaction.
- **Bypass mechanism** — any handler can be bypassed programmatically (useful in batch jobs and tests).

### How It Works

```
LoteTrigger      →  new LoteHandler().run()    →  beforeInsert → LoteNombreService.generarNombre()
                                                →  afterInsert  → LoteService.calcularEficiencia()
                                                →  afterUpdate  → LoteService.calcularEficiencia()  (only if Peso_inicial_Kg__c changed)

CosechaTrigger   →  new CosechaHandler().run() →  afterInsert  → LoteService.calcularEficiencia()
                                                →  afterUpdate  → LoteService.calcularEficiencia()  (recalculates old + new parent)
                                                →  afterDelete  → LoteService.calcularEficiencia()
```

`validateRun()` blocks execution when:
1. The trigger is not executing in a real trigger context (`Trigger.isExecuting = false`).
2. The handler is in the `bypassedHandlers` set.
3. The handler is already in `activeHandlers` (recursion guard).

### Bypass API

```apex
// Disable a handler for a block of code
TriggerHandler.bypass('LoteHandler');
insert lotes;
TriggerHandler.clearBypass('LoteHandler');

// Check bypass state
Boolean skipped = TriggerHandler.isBypassed('LoteHandler');

// Reset all bypasses
TriggerHandler.clearAllBypasses();
```

---

## Milestone 1 — Apex Fundamentals

### HU-01: Auto-generated Batch Name

**Class:** `LoteNombreService.generarNombre(List<Lote__c>)`

On every insert the system generates the name automatically using the format:

```
[Cepa__c]-[Fecha_Inoculacion__c]
// e.g. "Shiitake-2026-04-21"
```

**Fallback rules:**
- If `Cepa__c` is blank → uses `Sin-Cepa`
- If `Fecha_Inoculacion__c` is null → uses today's date

**Trigger event:** `before insert` via `LoteHandler.beforeInsert()`

---

### HU-02: Biological Efficiency Calculation

**Class:** `LoteService.calcularEficiencia(Set<Id> loteIds)`

Calculates and persists the biological efficiency of each batch:

```
Eficiencia_Biologica__c = (SUM(Cosecha__c.Peso_Kg__c) / Peso_inicial_Kg__c) * 100
```

**When it runs:**

| Event | Trigger |
|-------|---------|
| `Lote__c` insert with `Peso_inicial_Kg__c` | `LoteHandler.afterInsert` — initializes to `0.00` |
| `Lote__c` update and `Peso_inicial_Kg__c` changed | `LoteHandler.afterUpdate` — recalculates with existing harvests |
| `Cosecha__c` insert / update / delete | `CosechaHandler.after*` — recalculates parent batch |
| `Cosecha__c` update changes parent lookup | `CosechaHandler.afterUpdate` — recalculates both old and new parent |

**Edge cases:**
- `Peso_inicial_Kg__c` is null or `0` → `Eficiencia_Biologica__c` is set to `0` (prevents division by zero)
- `Lote__c` inserted without `Peso_inicial_Kg__c` → field stays `null` until peso is set

---

## Milestone 2 — Batch Apex & Scheduled Jobs

### HU-05: Nightly Efficiency Recalculation Batch

**Class:** `RecalcularEficienciaBatch`

Batch Apex job that recalculates `Eficiencia_Biologica__c` for all non-archived batches. Intended to run nightly to keep efficiency values consistent after any direct data changes.

```apex
// Run manually
Database.executeBatch(new RecalcularEficienciaBatch(), 200);
```

| Interface | Purpose |
|-----------|---------|
| `Database.Batchable<SObject>` | Processes lotes in chunks of 200 |
| `Database.Stateful` | Accumulates `totalProcesados` and `totalErrores` across chunks |

- **`start()`** — queries all `Lote__c` where `Estado__c != 'Archivado'`
- **`execute()`** — calls `LoteService.calcularEficiencia()` per chunk; exceptions are caught and counted without stopping the job
- **`finish()`** — inserts one `Log_Proceso__c` record with the execution summary

### HU-06: Scheduler & Execution Log

**Scheduler class:** `RecalcularEficienciaScheduler`

Schedulable wrapper that fires `RecalcularEficienciaBatch` on a cron schedule.

```apex
// Schedule daily at 2am
System.schedule('RecalcularEficiencia Nightly', '0 0 2 * * ?', new RecalcularEficienciaScheduler());
```

**Log object:** `Log_Proceso__c`

One record is created per batch run in `finish()`:

| Field | Type | Description |
|-------|------|-------------|
| `Name` | Text | `RecalcularEficienciaBatch YYYY-MM-DD HH:mm` |
| `Tipo_Proceso__c` | Text(100) | Batch class name |
| `Fecha_Ejecucion__c` | DateTime | Execution timestamp |
| `Registros_Procesados__c` | Number | Records processed without error |
| `Registros_con_Error__c` | Number | Records that threw an exception |
| `Estado__c` | Picklist | `Exitoso` / `Con Errores` |
| `Job_Id__c` | Text(18) | Salesforce `AsyncApexJob` ID |

### HU-08: Async Harvest Totals Update

**Class:** `ActualizarTotalesLoteQueueable`

Queueable Apex job that updates two summary fields on `Lote__c` after a harvest is recorded. Because the aggregation runs in a separate transaction, the cosecha insert completes immediately and the totals are consistent without consuming the trigger's governor limits.

**Fields updated:**

| Field | Calculation |
|-------|-------------|
| `Total_Cosechado_Kg__c` | `SUM(Cosecha__c.Peso_Kg__c)` |
| `Cantidad_Cosechas__c` | `COUNT(Cosecha__c)` |

**When it runs:** `CosechaHandler.afterInsert` enqueues the job after the synchronous `LoteService.calcularEficiencia()` call.

```
Cosecha__c insert
  └─ CosechaHandler.afterInsert
        ├─ LoteService.calcularEficiencia()          ← sync, updates Eficiencia_Biologica__c
        └─ System.enqueueJob(ActualizarTotalesLoteQueueable)  ← async, updates totals
```

The job is not enqueued when the trigger fires from within a batch context (`System.isBatch()`), since batch jobs cannot enqueue Queueable jobs.

---

### HU-07: Archive Inactive Batches

**Class:** `ArchivarLotesViejos`

Batch Apex job that marks old, inactive lotes as archived. A lote is archived when all of the following are true:

- `Archivado__c = false` and `Estado__c != 'Archivado'`
- Created more than **180 days** ago
- Has **no `Cosecha__c` records** with `Fecha_cosecha__c` within the last 180 days

```apex
// Run manually
Database.executeBatch(new ArchivarLotesViejos(), 200);
```

When a lote matches the criteria, `execute()` sets:

```apex
Archivado__c = true
Estado__c    = 'Archivado'
```

The `totalArchivados` counter (exposed via `@TestVisible`) tracks how many lotes were archived across all chunks.

**`Estado__c` Picklist**

`Estado__c` was converted from a free-text field to a restricted Picklist to prevent arbitrary values and enforce lifecycle integrity:

| Value | Meaning |
|-------|---------|
| `En Inoculación` | Default — batch just created |
| `En Colonización` | Mycelium colonising the substrate |
| `En Producción` | Active fruiting / harvest phase |
| `Finalizado` | Cycle completed, no more harvests expected |
| `Archivado` | Batch archived by `ArchivarLotesViejos` |

---

### HU-03: Inoculation Date Validation

**Metadata:** `Lote__c` Validation Rule `Fecha_Inoculacion_Futura`

Prevents saving a `Lote__c` with an inoculation date more than 7 days in the future. Implemented as a declarative Validation Rule (not Apex) since the logic is a simple date comparison with no need for programmatic bypass.

```
Error condition: Fecha_Inoculacion__c > TODAY() + 7
Error field:     Fecha_Inoculacion__c
```

---

## Milestone 3 — Lightning Web Components

### HU-09: Lote Card

**Component:** `loteCard` — placed on the `Lote__c` record page via Lightning App Builder.

Displays a production summary for the current batch using `@wire(getRecord)`:

| Section | Fields |
|---------|--------|
| Status badge | `Estado__c` — color-coded per lifecycle stage |
| Metrics grid | Días activo · Cosechas · Total cosechado (kg) · Eficiencia biológica (%) |
| Progress bar | `Eficiencia_Biologica__c` clamped to 100 for display |

**Estado badge colors:**

| Value | Color |
|-------|-------|
| En Inoculación | Blue |
| En Colonización | Orange |
| En Producción | Green |
| Finalizado | Purple |
| Archivado | Grey |

**Días activo** is computed client-side: `Math.floor((Date.now() − Fecha_Inoculacion__c) / ms_per_day)`.

The component exposes loading and error states using `lwc:if` / `lwc:elseif` / `lwc:else` directives.

To add to a record page: open Lightning App Builder on any `Lote__c` record → drag **Lote Card** from the custom components panel.

---

### HU-10: Cosecha Timeline

**Component:** `cosechaTimeline` — placed on the `Lote__c` record page via Lightning App Builder.

Displays a chronological timeline of all harvests (`Cosecha__c`) related to a batch (`Lote__c`), along with the accumulated weight over time.

**Key Features:**
- Uses standard Salesforce Lightning Design System (SLDS) timeline classes (`slds-timeline`) for a native look and feel.
- Calculates accumulated weight dynamically via the `CosechaTimelineController` Apex class.
- Handles Salesforce Date parsing without timezone drift to accurately show the harvest date.
- Enables direct navigation to specific harvest records using `NavigationMixin`.

To add to a record page: open Lightning App Builder on any `Lote__c` record → drag **Cosecha Timeline** from the custom components panel.

---

### HU-11: Dashboard Producción

**Component:** `dashboardProduccion` — placed on the Home Page via Lightning App Builder.

Displays high-level global metrics of the farm's active operation using server-side Apex aggregations.

**Key Features:**
- **Lotes Activos**: Counts batches currently in production (excludes `Finalizado` and `Archivado`).
- **Kg Cosechados (Mes)**: Dynamically calculates the total weight harvested in the current calendar month.
- **Eficiencia Promedio**: Calculates the average biological efficiency across all batches, ignoring empty ones.
- Fully responsive grid layout (`lightning-layout`) that adjusts gracefully from desktop to mobile screens.
- Utilizes `@AuraEnabled(cacheable=true)` for lightning-fast loading via Lightning Data Service cache.

To add to the Home Page: open Lightning App Builder on the Home Page → drag **Dashboard de Producción** from the custom components panel.

---

### HU-12: Registrar Cosecha

**Component:** `registrarCosecha` — exposed as a Quick Action (`lightning__RecordAction`) for the `Lote__c` object.

Displays a quick-entry modal form to register a new harvest (`Cosecha__c`) directly from the batch record, without navigating away.

**Key Features:**
- Designed as a **Screen Action** using `lightning-quick-action-panel` for a native modal experience.
- Uses **Imperative Apex** (`crearCosecha`) to insert the record securely.
- Captures `Peso_Kg__c`, `Fecha_cosecha__c`, and `Notas__c`.
- Automatically associates the harvest with the current `Lote__c` context using `@api recordId`.
- Provides user feedback via `ShowToastEvent` on success or failure.
- Dispatches a `RefreshEvent` and a `CloseActionScreenEvent` upon successful creation to close the modal and automatically refresh sibling components (like the Lote Card and Cosecha Timeline) via Lightning Data Service cache invalidation.

To add to a record page: go to Object Manager → `Lote__c` → Buttons, Links, and Actions → New Action → Select "Lightning Web Component" and choose `registrarCosecha`. Then add the action to the Page Layout.

---

## Deployment

### Retrieve metadata from org

```bash
sf project retrieve start --manifest manifest/package.xml
```

### Deploy to org

```bash
sf project deploy start --source-dir force-app/main/default
```

### Deploy specific files

```bash
sf project deploy start --source-dir force-app/main/default/classes/TriggerHandler.cls \
    force-app/main/default/classes/LoteHandler.cls \
    force-app/main/default/classes/LoteNombreService.cls \
    force-app/main/default/classes/LoteService.cls \
    force-app/main/default/classes/CosechaHandler.cls \
    force-app/main/default/triggers/LoteTrigger.trigger \
    force-app/main/default/triggers/CosechaTrigger.trigger
```

### Run test suite

```bash
sf apex run test --suite-name igniafungi --result-format human --synchronous
```

---

## Development Setup

```bash
# Authenticate to org
sf org login web --alias igniafungi

# Set as default org
sf config set target-org igniafungi

# Open org in browser
sf org open
```
