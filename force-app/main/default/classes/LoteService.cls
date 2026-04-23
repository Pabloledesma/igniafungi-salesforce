public with sharing class LoteService {

    public static void calcularEficiencia(List<Lote__c> lotes) {
        for (Lote__c lote : lotes) {
            if (lote.Peso_inicial_Kg__c != null && lote.Peso_inicial_Kg__c > 0 && lote.Total_Cosechado_Kg__c != null) {
                Decimal eficiencia = (lote.Total_Cosechado_Kg__c / lote.Peso_inicial_Kg__c) * 100;
                lote.Eficiencia_Biologica__c = eficiencia.setScale(2, RoundingMode.HALF_UP);
            } else {
                lote.Eficiencia_Biologica__c = 0;
            }
        }
    }
}
