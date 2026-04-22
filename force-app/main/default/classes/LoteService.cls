public with sharing class LoteService {

    public static void calcularEficiencia(Set<Id> loteIds) {
        if (loteIds.isEmpty()) return;

        Map<Id, Decimal> totalPorLote = new Map<Id, Decimal>();
        for (Id loteId : loteIds) {
            totalPorLote.put(loteId, 0);
        }

        for (AggregateResult ar : [
            SELECT Lote__c loteId, SUM(Peso_Kg__c) totalPeso
            FROM Cosecha__c
            WHERE Lote__c IN :loteIds
            GROUP BY Lote__c
        ]) {
            Id loteId    = (Id) ar.get('loteId');
            Decimal total = (Decimal) ar.get('totalPeso');
            totalPorLote.put(loteId, total != null ? total : 0);
        }

        List<Lote__c> lotesToUpdate = new List<Lote__c>();
        for (Lote__c lote : [
            SELECT Id, Peso_inicial_Kg__c
            FROM Lote__c
            WHERE Id IN :loteIds
        ]) {
            Decimal eficiencia = 0;
            if (lote.Peso_inicial_Kg__c != null && lote.Peso_inicial_Kg__c > 0) {
                eficiencia = (totalPorLote.get(lote.Id) / lote.Peso_inicial_Kg__c) * 100;
                eficiencia = eficiencia.setScale(2, RoundingMode.HALF_UP);
            }
            lotesToUpdate.add(new Lote__c(Id = lote.Id, Eficiencia_Biologica__c = eficiencia));
        }

        if (!lotesToUpdate.isEmpty()) {
            update lotesToUpdate;
        }
    }
}
