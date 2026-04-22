@IsTest
private class LoteServiceTest {

    private static final Date TEST_DATE = Date.newInstance(2026, 4, 1);

    @TestSetup
    static void setup() {
        insert new Lote__c(
            Cepa__c = 'Shiitake',
            Fecha_Inoculacion__c = TEST_DATE,
            Peso_inicial_Kg__c = 10
        );
    }

    private static Lote__c getLote() {
        return [SELECT Id, Peso_inicial_Kg__c, Eficiencia_Biologica__c FROM Lote__c LIMIT 1];
    }

    // ── Cálculo básico ────────────────────────────────────────────────────────

    @IsTest
    static void withNoCosechas_setsEficienciaToZero() {
        Lote__c lote = getLote();

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ lote.Id });
        Test.stopTest();

        lote = getLote();
        System.assertEquals(0, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void withOneCosecha_calculatesCorrectPercentage() {
        Lote__c lote = getLote();
        insert new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 5, Fecha_cosecha__c = TEST_DATE);

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ lote.Id });
        Test.stopTest();

        lote = getLote();
        System.assertEquals(50.00, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void withMultipleCosechas_sumsBeforeCalculating() {
        Lote__c lote = getLote();
        insert new List<Cosecha__c>{
            new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 3, Fecha_cosecha__c = TEST_DATE),
            new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 4, Fecha_cosecha__c = TEST_DATE)
        };

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ lote.Id });
        Test.stopTest();

        lote = getLote();
        System.assertEquals(70.00, lote.Eficiencia_Biologica__c); // (3+4)/10*100
    }

    // ── Protección división por cero ──────────────────────────────────────────

    @IsTest
    static void withNullPesoInicial_setsEficienciaToZero() {
        Lote__c lote2 = new Lote__c(Cepa__c = 'Ostra', Fecha_Inoculacion__c = TEST_DATE);
        TriggerHandler.bypass('LoteHandler');
        insert lote2;
        TriggerHandler.clearBypass('LoteHandler');

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ lote2.Id });
        Test.stopTest();

        lote2 = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :lote2.Id];
        System.assertEquals(0, lote2.Eficiencia_Biologica__c);
    }

    @IsTest
    static void withZeroPesoInicial_setsEficienciaToZero() {
        Lote__c lote = getLote();
        TriggerHandler.bypass('LoteHandler');
        update new Lote__c(Id = lote.Id, Peso_inicial_Kg__c = 0);
        TriggerHandler.clearBypass('LoteHandler');

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ lote.Id });
        Test.stopTest();

        lote = getLote();
        System.assertEquals(0, lote.Eficiencia_Biologica__c);
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void withMultipleLotes_calculatesEachIndependently() {
        Lote__c loteA = getLote();
        Lote__c loteB = new Lote__c(Cepa__c = 'Ostra', Fecha_Inoculacion__c = TEST_DATE, Peso_inicial_Kg__c = 20);
        insert loteB;

        insert new List<Cosecha__c>{
            new Cosecha__c(Lote__c = loteA.Id, Peso_Kg__c = 5,  Fecha_cosecha__c = TEST_DATE),
            new Cosecha__c(Lote__c = loteB.Id, Peso_Kg__c = 8, Fecha_cosecha__c = TEST_DATE)
        };

        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>{ loteA.Id, loteB.Id });
        Test.stopTest();

        Map<Id, Lote__c> result = new Map<Id, Lote__c>([
            SELECT Id, Eficiencia_Biologica__c FROM Lote__c WHERE Id IN :new Set<Id>{ loteA.Id, loteB.Id }
        ]);
        System.assertEquals(50.00, result.get(loteA.Id).Eficiencia_Biologica__c); // 5/10*100
        System.assertEquals(40.00, result.get(loteB.Id).Eficiencia_Biologica__c); // 8/20*100
    }

    @IsTest
    static void withEmptySet_doesNothing() {
        Test.startTest();
        LoteService.calcularEficiencia(new Set<Id>());
        Test.stopTest();
        System.assert(true, 'Should handle empty set without exception');
    }
}
