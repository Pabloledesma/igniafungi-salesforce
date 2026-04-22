public with sharing class CosechaHandler extends TriggerHandler {

    private List<Cosecha__c> newList;
    private Map<Id, Cosecha__c> newMap;
    private List<Cosecha__c> oldList;
    private Map<Id, Cosecha__c> oldMap;

    public CosechaHandler() {
        this.newList = (List<Cosecha__c>) Trigger.new;
        this.newMap  = (Map<Id, Cosecha__c>) Trigger.newMap;
        this.oldList = (List<Cosecha__c>) Trigger.old;
        this.oldMap  = (Map<Id, Cosecha__c>) Trigger.oldMap;
    }

    protected override void afterInsert() {
        Set<Id> loteIds = collectLoteIds(newList, null);
        LoteService.calcularEficiencia(loteIds);
        if (!loteIds.isEmpty() && !System.isBatch()) {
            System.enqueueJob(new ActualizarTotalesLoteQueueable(loteIds));
        }
    }

    protected override void afterUpdate() {
        // Recalculate both old and new parent when the lookup changes
        LoteService.calcularEficiencia(collectLoteIds(newList, oldMap));
    }

    protected override void afterDelete() {
        LoteService.calcularEficiencia(collectLoteIds(oldList, null));
    }

    private Set<Id> collectLoteIds(List<Cosecha__c> cosechas, Map<Id, Cosecha__c> previousMap) {
        Set<Id> ids = new Set<Id>();
        for (Cosecha__c c : cosechas) {
            if (c.Lote__c != null) ids.add(c.Lote__c);
            if (previousMap != null) {
                Cosecha__c old = previousMap.get(c.Id);
                if (old.Lote__c != null && old.Lote__c != c.Lote__c) {
                    ids.add(old.Lote__c);
                }
            }
        }
        return ids;
    }
}
