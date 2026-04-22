public with sharing class LoteNombreService {

    public static void generarNombre(List<Lote__c> lotes) {
        for (Lote__c lote : lotes) {
            
            String cepa = String.isNotBlank(lote.Cepa__c) ? lote.Cepa__c : 'Sin-Cepa';
            String fecha = lote.Fecha_Inoculacion__c != null
                ? String.valueOf(lote.Fecha_Inoculacion__c)
                : String.valueOf(Date.today());
            lote.Name = cepa + '-' + fecha;
            
        }
    }
}
