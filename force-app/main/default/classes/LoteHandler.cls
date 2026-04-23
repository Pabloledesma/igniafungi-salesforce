public with sharing class LoteHandler extends TriggerHandler {

    private List<Lote__c> newList;
    private Map<Id, Lote__c> newMap;
    private List<Lote__c> oldList;
    private Map<Id, Lote__c> oldMap;

    public LoteHandler() {
        this.newList = (List<Lote__c>) Trigger.new;
        this.newMap  = (Map<Id, Lote__c>) Trigger.newMap;
        this.oldList = (List<Lote__c>) Trigger.old;
        this.oldMap  = (Map<Id, Lote__c>) Trigger.oldMap;
    }

    protected override void beforeInsert() {
        LoteNombreService.generarNombre(newList);
    }

    protected override void afterInsert() {
        Set<Id> loteIds = new Set<Id>();
        for (Lote__c lote : newList) {
            if (lote.Peso_inicial_Kg__c != null && lote.Peso_inicial_Kg__c > 0) {
                loteIds.add(lote.Id);
            }
        }
        if (!loteIds.isEmpty()) {
            LoteService.calcularEficiencia(loteIds);
        }
    }

    @TestVisible private static List<Database.SaveResult> publishResults;

    protected override void afterUpdate() {
        Set<Id> recalcIds = new Set<Id>();
        List<LoteActualizado__e> events = new List<LoteActualizado__e>();

        for (Lote__c lote : newList) {
            Lote__c old = oldMap.get(lote.Id);

            if (lote.Peso_inicial_Kg__c != old.Peso_inicial_Kg__c) {
                recalcIds.add(lote.Id);
            }

            if (lote.Estado__c != old.Estado__c) {
                events.add(new LoteActualizado__e(
                    Lote_Id__c              = lote.Id,
                    Ignia_Id__c             = lote.ignia_id__c,
                    Estado_Nuevo__c         = lote.Estado__c,
                    Cepa__c                 = lote.Cepa__c,
                    Eficiencia_Biologica__c = lote.Eficiencia_Biologica__c
                ));
            }
        }

        if (!recalcIds.isEmpty()) {
            LoteService.calcularEficiencia(recalcIds);
        }

        if (!events.isEmpty()) {
            publishResults = EventBus.publish(events);
        }
    }
}
