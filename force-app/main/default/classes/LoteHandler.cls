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

    protected override void afterUpdate() {
        Set<Id> changedIds = new Set<Id>();
        for (Lote__c lote : newList) {
            if (lote.Peso_inicial_Kg__c != oldMap.get(lote.Id).Peso_inicial_Kg__c) {
                changedIds.add(lote.Id);
            }
        }
        if (!changedIds.isEmpty()) {
            LoteService.calcularEficiencia(changedIds);
        }
    }
}
