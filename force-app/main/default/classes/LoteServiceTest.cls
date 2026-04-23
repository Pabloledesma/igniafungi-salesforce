@IsTest
private class LoteServiceTest {

    // Crea un Lote__c en memoria con Total_Cosechado_Kg__c (Roll-Up Summary, read-only).
    // JSON.deserialize permite fijar campos calculados sin DML.
    private static Lote__c loteConTotal(Decimal pesoInicial, Decimal totalCosechado) {
        String payload = '{"Peso_inicial_Kg__c":' + (pesoInicial == null ? 'null' : String.valueOf(pesoInicial))
                       + ',"Total_Cosechado_Kg__c":' + (totalCosechado == null ? 'null' : String.valueOf(totalCosechado))
                       + '}';
        return (Lote__c) JSON.deserialize(payload, Lote__c.class);
    }

    // ── Cálculo básico ────────────────────────────────────────────────────────

    @IsTest
    static void conTotalYPeso_calculaEficienciaCorrecta() {
        Lote__c lote = loteConTotal(10, 5);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(50.00, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void conTotalIgualAlPeso_retorna100() {
        Lote__c lote = loteConTotal(8, 8);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(100.00, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void resultado_seRedondea2Decimales() {
        Lote__c lote = loteConTotal(3, 1);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(33.33, lote.Eficiencia_Biologica__c); // 1/3*100 = 33.333...
    }

    // ── Protección división por cero ──────────────────────────────────────────

    @IsTest
    static void conPesoInicialNulo_poneEficienciaEnCero() {
        Lote__c lote = loteConTotal(null, 5);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(0, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void conPesoInicialCero_poneEficienciaEnCero() {
        Lote__c lote = loteConTotal(0, 5);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(0, lote.Eficiencia_Biologica__c);
    }

    @IsTest
    static void conTotalCosechadoNulo_poneEficienciaEnCero() {
        Lote__c lote = loteConTotal(10, null);
        LoteService.calcularEficiencia(new List<Lote__c>{ lote });
        Assert.areEqual(0, lote.Eficiencia_Biologica__c);
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void variosLotes_calculaCadaUnoIndependientemente() {
        Lote__c loteA = loteConTotal(10, 5);
        Lote__c loteB = loteConTotal(20, 8);
        Lote__c loteC = loteConTotal(null, 3);
        LoteService.calcularEficiencia(new List<Lote__c>{ loteA, loteB, loteC });
        Assert.areEqual(50.00, loteA.Eficiencia_Biologica__c);
        Assert.areEqual(40.00, loteB.Eficiencia_Biologica__c);
        Assert.areEqual(0,     loteC.Eficiencia_Biologica__c);
    }

    @IsTest
    static void listaVacia_noLanzaExcepcion() {
        LoteService.calcularEficiencia(new List<Lote__c>());
        Assert.isTrue(true);
    }
}
