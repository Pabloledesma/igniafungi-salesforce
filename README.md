# Ignia Fungi — CRM & Production Manager on Salesforce

Salesforce DX project for managing mushroom cultivation operations: batch tracking, harvest logging, biological efficiency reporting, and bidirectional integration with a Laravel backend.

---

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── TriggerHandler.cls        # Base trigger handler framework
│   ├── LoteHandler.cls           # Trigger handler for Lote__c
│   ├── CosechaHandler.cls        # Trigger handler for Cosecha__c
│   ├── LoteNombreService.cls     # Business logic: auto-naming for Lote__c
│   └── LoteService.cls           # Business logic: biological efficiency calculation
├── triggers/
│   ├── LoteTrigger.trigger       # Lote__c trigger (all events)
│   └── CosechaTrigger.trigger    # Cosecha__c trigger (all events)
├── objects/
│   ├── Lote__c/                  # Batch object with custom fields
│   └── Cosecha__c/               # Harvest object with custom fields
├── permissionsets/
│   └── Igniafungi_Admin.permissionset-meta.xml
├── testSuites/
│   └── igniafungi.testSuite-meta.xml
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
| `Estado__c` | Text(50) | Current batch status |
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
