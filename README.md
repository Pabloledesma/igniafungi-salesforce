# Ignia Fungi — CRM & Production Manager on Salesforce

Salesforce DX project for managing mushroom cultivation operations: batch tracking, harvest logging, biological efficiency reporting, and bidirectional integration with a Laravel backend.

---

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── TriggerHandler.cls        # Base trigger handler framework
│   ├── LoteHandler.cls           # Trigger handler for Lote__c
│   └── LoteNombreService.cls     # Business logic: auto-naming for Lote__c
├── triggers/
│   └── LoteTrigger.trigger       # Lote__c trigger (all events)
├── objects/
│   ├── Lote__c/                  # Batch object with custom fields
│   └── Cosecha__c/               # Harvest object with custom fields
└── manifest/
    └── package.xml               # Metadata manifest for org retrieval
```

---

## Custom Objects

### `Lote__c` — Production Batch

Represents a single mushroom cultivation batch from inoculation to harvest.

| Field | Type | Description |
|-------|------|-------------|
| `Name` | Text | Auto-generated as `[Cepa]-[Fecha_Inoculacion]` if left blank |
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
LoteTrigger  →  new LoteHandler().run()  →  TriggerHandler.validateRun()
                                                  ↓
                                        routes to beforeInsert / afterUpdate / etc.
                                                  ↓
                                        LoteHandler.beforeInsert()
                                                  ↓
                                        LoteNombreService.generarNombre()
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

When a `Lote__c` record is inserted without a name, the system generates one automatically using the format:

```
[Cepa__c]-[Fecha_Inoculacion__c]
// e.g. "Shiitake-2026-04-21"
```

**Fallback rules:**
- If `Cepa__c` is blank → uses `Sin-Cepa`
- If `Fecha_Inoculacion__c` is null → uses today's date

**Trigger event:** `before insert` via `LoteHandler.beforeInsert()`

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
    force-app/main/default/triggers/LoteTrigger.trigger
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
