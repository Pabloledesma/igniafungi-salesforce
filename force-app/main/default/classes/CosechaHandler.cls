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
}
