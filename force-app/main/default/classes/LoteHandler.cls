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
}
