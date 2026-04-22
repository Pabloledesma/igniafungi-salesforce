@isTest
public class RegistrarCosechaControllerTest {

    @testSetup
    static void setup() {
        Lote__c lote = new Lote__c(Name = 'Lote Test', Peso_inicial_Kg__c = 10, Cantidad__c = 5);
        insert lote;
    }

    @isTest
    static void testCrearCosechaSuccess() {
        Lote__c lote = [SELECT Id FROM Lote__c LIMIT 1];
        
        Test.startTest();
        RegistrarCosechaController.crearCosecha(lote.Id, 2.5, Date.today(), 'Prueba de cosecha');
        Test.stopTest();
        
        List<Cosecha__c> cosechas = [SELECT Id, Peso_Kg__c, Fecha_cosecha__c, Notas__c FROM Cosecha__c WHERE Lote__c = :lote.Id];
        System.assertEquals(1, cosechas.size(), 'Se debería haber creado una cosecha');
        System.assertEquals(2.5, cosechas[0].Peso_Kg__c, 'El peso debería coincidir');
        System.assertEquals(Date.today(), cosechas[0].Fecha_cosecha__c, 'La fecha debería coincidir');
        System.assertEquals('Prueba de cosecha', cosechas[0].Notas__c, 'Las notas deberían coincidir');
    }

    @isTest
    static void testCrearCosechaError() {
        Test.startTest();
        try {
            // Pasando un Id inválido forzará un error DML
            RegistrarCosechaController.crearCosecha('001000000000000', 2.5, Date.today(), 'Error esperado');
            System.assert(false, 'Se esperaba una excepción de tipo AuraHandledException');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'El controlador debe lanzar AuraHandledException');
        }
        Test.stopTest();
    }
}
