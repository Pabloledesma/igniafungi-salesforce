@IsTest
private class CosechaTriggerTest {

    private static final Date TEST_DATE = Date.newInstance(2026, 4, 1);

    @TestSetup
    static void setup() {
        insert new List<Lote__c>{
            new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE, Peso_inicial_Kg__c = 10),
            new Lote__c(Cepa__c = 'Ostra',    Fecha_Inoculacion__c = TEST_DATE, Peso_inicial_Kg__c = 20)
        };
    }

    private static Map<String, Lote__c> getLotesByCepa() {
        Map<String, Lote__c> result = new Map<String, Lote__c>();
        for (Lote__c l : [SELECT Id, Cepa__c, Eficiencia_Biologica__c FROM Lote__c]) {
            result.put(l.Cepa__c, l);
        }
        return result;
    }

    // ── After insert ──────────────────────────────────────────────────────────

    @IsTest
    static void insertCosecha_recalculatesEficiencia() {
        Lote__c lote = getLotesByCepa().get('Shiitake');

        Test.startTest();
        insert new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 6, Fecha_cosecha__c = TEST_DATE);
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(60.00, lote.Eficiencia_Biologica__c); // 6/10*100
    }

    // ── After update ──────────────────────────────────────────────────────────

    @IsTest
    static void updateCosechaPeso_recalculatesEficiencia() {
        Lote__c lote = getLotesByCepa().get('Shiitake');
        Cosecha__c cosecha = new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 4, Fecha_cosecha__c = TEST_DATE);
        insert cosecha;

        Test.startTest();
        cosecha.Peso_Kg__c = 8;
        update cosecha;
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(80.00, lote.Eficiencia_Biologica__c); // 8/10*100
    }

    // ── After delete ──────────────────────────────────────────────────────────

    @IsTest
    static void deleteCosecha_recalculatesEficiencia() {
        Lote__c lote = getLotesByCepa().get('Shiitake');
        Cosecha__c c1 = new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 6, Fecha_cosecha__c = TEST_DATE);
        Cosecha__c c2 = new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 4, Fecha_cosecha__c = TEST_DATE);
        insert new List<Cosecha__c>{ c1, c2 };

        Test.startTest();
        delete c2;
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(60.00, lote.Eficiencia_Biologica__c); // solo c1: 6/10*100
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void bulkInsertCosechas_eficienciaCalculatedOnce() {
        Lote__c lote = getLotesByCepa().get('Shiitake');
        List<Cosecha__c> cosechas = new List<Cosecha__c>();
        for (Integer i = 0; i < 100; i++) {
            cosechas.add(new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 1, Fecha_cosecha__c = TEST_DATE));
        }

        Test.startTest();
        insert cosechas;
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(1000.00, lote.Eficiencia_Biologica__c); // 100/10*100
    }
}
