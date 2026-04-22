@isTest
public class DashboardProduccionControllerTest {
    
    @testSetup
    static void setup() {
        // Create Lotes
        List<Lote__c> lotes = new List<Lote__c>();
        lotes.add(new Lote__c(Name='Lote 1', Estado__c='En Producción', Peso_inicial_Kg__c=10, Cantidad__c=5));
        lotes.add(new Lote__c(Name='Lote 2', Estado__c='Finalizado', Peso_inicial_Kg__c=10, Cantidad__c=5));
        insert lotes;
        
        // Create Cosechas
        List<Cosecha__c> cosechas = new List<Cosecha__c>();
        cosechas.add(new Cosecha__c(Lote__c=lotes[0].Id, Peso_Kg__c=5, Fecha_cosecha__c=Date.today())); // 50% ef
        cosechas.add(new Cosecha__c(Lote__c=lotes[1].Id, Peso_Kg__c=10, Fecha_cosecha__c=Date.today())); // 100% ef
        insert cosechas;
    }
    
    @isTest
    static void testGetLotesActivos() {
        Test.startTest();
        Integer activos = DashboardProduccionController.getLotesActivos();
        Test.stopTest();
        
        System.assertEquals(1, activos, 'Debería haber 1 lote activo');
    }
    
    @isTest
    static void testGetKgCosechadosEsteMes() {
        Test.startTest();
        Decimal total = DashboardProduccionController.getKgCosechadosEsteMes();
        Test.stopTest();
        
        System.assertEquals(15, total, 'Deberían haberse cosechado 15 kg este mes');
    }
    
    @isTest
    static void testGetEficienciaPromedio() {
        Test.startTest();
        Decimal promedio = DashboardProduccionController.getEficienciaPromedio();
        Test.stopTest();
        
        System.assertEquals(75.00, promedio, 'La eficiencia promedio debería ser 75%');
    }
    
    @isTest
    static void testEmptyStates() {
        // Delete all data to test null/empty returns
        delete [SELECT Id FROM Cosecha__c];
        delete [SELECT Id FROM Lote__c];
        
        Test.startTest();
        System.assertEquals(0, DashboardProduccionController.getLotesActivos(), 'Should be 0');
        System.assertEquals(0, DashboardProduccionController.getKgCosechadosEsteMes(), 'Should be 0');
        System.assertEquals(0, DashboardProduccionController.getEficienciaPromedio(), 'Should be 0');
        Test.stopTest();
    }
}
