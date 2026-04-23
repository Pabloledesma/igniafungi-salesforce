@IsTest
private class LoteTriggerTest {

    private static final Date TEST_DATE = Date.newInstance(2026, 4, 21);

    // ── Single record ─────────────────────────────────────────────────────────

    @IsTest
    static void insertWithoutName_autoGeneratesName() {
        Lote__c lote = new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE);

        Test.startTest();
        insert lote;
        Test.stopTest();

        lote = [SELECT Name FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals('Shiitake-2026-04-21', lote.Name);
    }

    @IsTest
    static void insertWithName_overridesWithGeneratedName() {
        Lote__c lote = new Lote__c(
            Name = 'Nombre-Manual',
            Cepa__c = 'Shiitake',
            Fecha_Inoculacion__c = TEST_DATE
        );

        Test.startTest();
        insert lote;
        Test.stopTest();

        lote = [SELECT Name FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals('Shiitake-2026-04-21', lote.Name);
    }

    @IsTest
    static void insertWithBlankCepa_usesFallbackInName() {
        Lote__c lote = new Lote__c(Fecha_Inoculacion__c = TEST_DATE);

        Test.startTest();
        insert lote;
        Test.stopTest();

        lote = [SELECT Name FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals('Sin-Cepa-2026-04-21', lote.Name);
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void bulkInsert_allNamesGenerated() {
        List<Lote__c> lotes = new List<Lote__c>();
        for (Integer i = 1; i <= 200; i++) {
            lotes.add(new Lote__c(
                Cepa__c = 'Ostra',
                Fecha_Inoculacion__c = TEST_DATE
            ));
        }

        Test.startTest();
        insert lotes;
        Test.stopTest();

        for (Lote__c l : [SELECT Name FROM Lote__c WHERE Id IN :lotes]) {
            System.assertEquals('Ostra-2026-04-21', l.Name);
        }
    }

    // ── Eficiencia biológica en insert ────────────────────────────────────────

    @IsTest
    static void insertWithPesoInicial_initializesEficienciaToZero() {
        Lote__c lote = new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE, Peso_inicial_Kg__c = 10);

        Test.startTest();
        insert lote;
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(0, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void insertWithoutPesoInicial_eficienciaIsZero() {
        Lote__c lote = new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE);

        Test.startTest();
        insert lote;
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(0, lote.Eficiencia_Biologica__c);
    }

    // ── Eficiencia biológica en update ────────────────────────────────────────

    @IsTest
    static void updatePesoInicial_recalculatesEficiencia() {
        Lote__c lote = new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE, Peso_inicial_Kg__c = 10);
        insert lote;
        insert new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 5, Fecha_cosecha__c = TEST_DATE);

        Test.startTest();
        update new Lote__c(Id = lote.Id, Peso_inicial_Kg__c = 20);
        Test.stopTest();

        lote = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(25.00, lote.Eficiencia_Biologica__c); // 5/20*100
    }

    // ── Bypass ────────────────────────────────────────────────────────────────

    @IsTest
    static void insertWithBypass_doesNotAutoGenerateName() {
        TriggerHandler.bypass('LoteHandler');
        Lote__c lote = new Lote__c(
            Name = 'Nombre-Manual',
            Cepa__c = 'Shiitake',
            Fecha_Inoculacion__c = TEST_DATE
        );

        Test.startTest();
        insert lote;
        Test.stopTest();

        TriggerHandler.clearBypass('LoteHandler');

        lote = [SELECT Name FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals('Nombre-Manual', lote.Name, 'Bypassed handler should not alter the name');
    }
}
