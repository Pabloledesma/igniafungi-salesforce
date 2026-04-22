trigger CosechaTrigger on Cosecha__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new CosechaHandler().run();
}
