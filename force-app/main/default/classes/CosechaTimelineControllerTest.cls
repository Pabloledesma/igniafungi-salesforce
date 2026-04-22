@isTest
public class CosechaTimelineControllerTest {
    @testSetup
    static void setup() {
        // Create a test Lote__c
        Lote__c lote = new Lote__c();
        lote.Name = 'Lote Test';
        insert lote;

        // Create test Cosecha__c records
        List<Cosecha__c> cosechas = new List<Cosecha__c>();
        cosechas.add(new Cosecha__c(Lote__c = lote.Id, Fecha_cosecha__c = Date.today().addDays(-2), Peso_Kg__c = 10));
        cosechas.add(new Cosecha__c(Lote__c = lote.Id, Fecha_cosecha__c = Date.today().addDays(-1), Peso_Kg__c = 15));
        cosechas.add(new Cosecha__c(Lote__c = lote.Id, Fecha_cosecha__c = Date.today(), Peso_Kg__c = 20));
        
        insert cosechas;
    }

    @isTest
    static void testGetCosechas() {
        Lote__c lote = [SELECT Id FROM Lote__c LIMIT 1];

        Test.startTest();
        List<CosechaTimelineController.CosechaWrapper> result = CosechaTimelineController.getCosechas(lote.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return 3 cosechas');
        
        // Check order and accumulated weight
        System.assertEquals(10, result[0].pesoAcumulado, 'Accumulated weight for first should be 10');
        System.assertEquals(25, result[1].pesoAcumulado, 'Accumulated weight for second should be 25');
        System.assertEquals(45, result[2].pesoAcumulado, 'Accumulated weight for third should be 45');
    }
}
