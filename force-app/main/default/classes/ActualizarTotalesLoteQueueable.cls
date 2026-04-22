public class ActualizarTotalesLoteQueueable implements Queueable {

    private Set<Id> loteIds;

    public ActualizarTotalesLoteQueueable(Set<Id> loteIds) {
        this.loteIds = loteIds;
    }

    public void execute(QueueableContext ctx) {
        if (loteIds == null || loteIds.isEmpty()) return;

        Map<Id, Decimal> totalPorLote    = new Map<Id, Decimal>();
        Map<Id, Integer> cantidadPorLote = new Map<Id, Integer>();
        for (Id id : loteIds) {
            totalPorLote.put(id, 0);
            cantidadPorLote.put(id, 0);
        }

        for (AggregateResult ar : [
            SELECT Lote__c loteId, SUM(Peso_Kg__c) totalPeso, COUNT(Id) cantidad
            FROM   Cosecha__c
            WHERE  Lote__c IN :loteIds
            GROUP BY Lote__c
        ]) {
            Id      loteId = (Id) ar.get('loteId');
            Decimal total  = (Decimal) ar.get('totalPeso');
            Integer cant   = Integer.valueOf(ar.get('cantidad'));
            totalPorLote.put(loteId, total != null ? total : 0);
            cantidadPorLote.put(loteId, cant);
        }

        List<Lote__c> toUpdate = new List<Lote__c>();
        for (Id id : loteIds) {
            toUpdate.add(new Lote__c(
                Id                    = id,
                Total_Cosechado_Kg__c = totalPorLote.get(id),
                Cantidad_Cosechas__c  = cantidadPorLote.get(id)
            ));
        }

        update toUpdate;
    }
}
