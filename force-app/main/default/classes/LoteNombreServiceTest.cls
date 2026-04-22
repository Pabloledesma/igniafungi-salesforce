@IsTest
private class LoteNombreServiceTest {

    private static final Date TEST_DATE = Date.newInstance(2026, 4, 21);

    // ── Happy path ────────────────────────────────────────────────────────────

    @IsTest
    static void withCepaAndFecha_generatesCorrectName() {
        Lote__c lote = new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE);

        LoteNombreService.generarNombre(new List<Lote__c>{ lote });

        System.assertEquals('Shiitake-2026-04-21', lote.Name);
    }

    // ── Fallbacks ─────────────────────────────────────────────────────────────

    @IsTest
    static void withBlankCepa_usesSinCepaFallback() {
        Lote__c lote = new Lote__c(Fecha_Inoculacion__c = TEST_DATE);

        LoteNombreService.generarNombre(new List<Lote__c>{ lote });

        System.assertEquals('Sin-Cepa-2026-04-21', lote.Name);
    }

    @IsTest
    static void withNullFecha_usesTodayAsDate() {
        Lote__c lote = new Lote__c(Cepa__c = 'Ostra');

        LoteNombreService.generarNombre(new List<Lote__c>{ lote });

        String expected = 'Ostra-' + String.valueOf(Date.today());
        System.assertEquals(expected, lote.Name);
    }

    @IsTest
    static void withBothBlank_usesBothFallbacks() {
        Lote__c lote = new Lote__c();

        LoteNombreService.generarNombre(new List<Lote__c>{ lote });

        String expected = 'Sin-Cepa-' + String.valueOf(Date.today());
        System.assertEquals(expected, lote.Name);
    }

    // ── Always overrides ──────────────────────────────────────────────────────

    @IsTest
    static void withExistingName_alwaysOverridesWithGeneratedName() {
        Lote__c lote = new Lote__c(
            Name = 'Nombre-Fijo',
            Cepa__c = 'Shiitake',
            Fecha_Inoculacion__c = TEST_DATE
        );

        LoteNombreService.generarNombre(new List<Lote__c>{ lote });

        System.assertEquals('Shiitake-2026-04-21', lote.Name);
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void withBulkList_processesEachLoteCorrectly() {
        List<Lote__c> lotes = new List<Lote__c>{
            new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = Date.newInstance(2026, 1, 10)),
            new Lote__c(Cepa__c = 'Ostra',    Fecha_Inoculacion__c = Date.newInstance(2026, 3, 5)),
            new Lote__c(Name = 'Fijo')
        };

        LoteNombreService.generarNombre(lotes);

        System.assertEquals('Shiitake-2026-01-10',                        lotes[0].Name);
        System.assertEquals('Ostra-2026-03-05',                            lotes[1].Name);
        System.assertEquals('Sin-Cepa-' + String.valueOf(Date.today()),    lotes[2].Name);
    }

    @IsTest
    static void withEmptyList_doesNotThrow() {
        LoteNombreService.generarNombre(new List<Lote__c>());
        System.assert(true, 'Should handle empty list without exception');
    }
}
