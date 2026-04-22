public with sharing class CosechaTimelineController {
    @AuraEnabled(cacheable=true)
    public static List<CosechaWrapper> getCosechas(Id loteId) {
        List<Cosecha__c> cosechas = [
            SELECT Id, Name, Fecha_cosecha__c, Peso_Kg__c, Notas__c
            FROM Cosecha__c
            WHERE Lote__c = :loteId
            ORDER BY Fecha_cosecha__c ASC, CreatedDate ASC
        ];
        
        List<CosechaWrapper> result = new List<CosechaWrapper>();
        Decimal pesoAcumulado = 0;
        
        for (Cosecha__c c : cosechas) {
            pesoAcumulado += (c.Peso_Kg__c != null ? c.Peso_Kg__c : 0);
            CosechaWrapper cw = new CosechaWrapper();
            cw.cosecha = c;
            cw.pesoAcumulado = pesoAcumulado;
            result.add(cw);
        }
        
        return result;
    }
    
    public class CosechaWrapper {
        @AuraEnabled public Cosecha__c cosecha { get; set; }
        @AuraEnabled public Decimal pesoAcumulado { get; set; }
    }
}
