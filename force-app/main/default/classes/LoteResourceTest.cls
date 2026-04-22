@IsTest
private class LoteResourceTest {

    private static final Date HOY = Date.today();

    @TestSetup
    static void setup() {
        TriggerHandler.bypass('LoteHandler');
        insert new List<Lote__c>{
            new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = HOY,
                        Estado__c = 'En Producción', Peso_inicial_Kg__c = 10,
                        ignia_id__c = 1),
            new Lote__c(Cepa__c = 'Ostra', Fecha_Inoculacion__c = HOY,
                        Estado__c = 'Archivado', Peso_inicial_Kg__c = 5,
                        Archivado__c = true, ignia_id__c = 2)
        };
        TriggerHandler.clearBypass('LoteHandler');
    }

    // ── helpers ───────────────────────────────────────────────────────────────────

    private static void setCtx(String method, String uriSuffix, String body) {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = method;
        req.requestURI = '/services/apexrest/ignia/lotes/' + uriSuffix;
        if (body != null) req.requestBody = Blob.valueOf(body);
        RestContext.request  = req;
        RestContext.response = res;
    }

    private static Map<String, Object> parse(String body) {
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private static Id shiitakeId() {
        return [SELECT Id FROM Lote__c WHERE Cepa__c = 'Shiitake' LIMIT 1].Id;
    }

    // ── GET todos ─────────────────────────────────────────────────────────────────

    @IsTest
    static void doGet_sinId_soloDevuelveNoArchivados() {
        setCtx('GET', '', null);

        String body = LoteResource.doGet();
        Map<String, Object> res = parse(body);

        System.assertEquals(true, res.get('success'));
        System.assertEquals(1, ((List<Object>) res.get('data')).size());
    }

    // ── GET por Salesforce ID ────────────────────────────────────────────────────

    @IsTest
    static void doGet_conSalesforceId_devuelveLote() {
        setCtx('GET', shiitakeId(), null);

        Map<String, Object> res = parse(LoteResource.doGet());
        Map<String, Object> dto = (Map<String, Object>) res.get('data');

        System.assertEquals(true, res.get('success'));
        System.assertEquals('Shiitake', dto.get('cepa'));
        System.assertEquals(1, Integer.valueOf(String.valueOf(dto.get('igniaId'))));
    }

    // ── GET por ignia_id__c ───────────────────────────────────────────────────────

    @IsTest
    static void doGet_conIgniaId_devuelveLote() {
        setCtx('GET', '1', null);

        Map<String, Object> res = parse(LoteResource.doGet());
        Map<String, Object> dto = (Map<String, Object>) res.get('data');

        System.assertEquals(true, res.get('success'));
        System.assertEquals('Shiitake', dto.get('cepa'));
    }

    // ── GET no encontrado ─────────────────────────────────────────────────────────

    @IsTest
    static void doGet_idInexistente_devuelve404() {
        setCtx('GET', '9999', null);

        Map<String, Object> res = parse(LoteResource.doGet());

        System.assertEquals(false, res.get('success'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    // ── PATCH por Salesforce ID ───────────────────────────────────────────────────

    @IsTest
    static void doPatch_conSalesforceId_actualizaEstado() {
        Id loteId = shiitakeId();
        setCtx('PATCH', loteId, '{"estado": "Finalizado"}');

        Map<String, Object> res = parse(LoteResource.doPatch());

        System.assertEquals(true, res.get('success'));
        System.assertEquals('Finalizado',
            [SELECT Estado__c FROM Lote__c WHERE Id = :loteId].Estado__c);
    }

    // ── PATCH por ignia_id__c ─────────────────────────────────────────────────────

    @IsTest
    static void doPatch_conIgniaId_actualizaCepaYPeso() {
        setCtx('PATCH', '1', '{"cepa": "Shiitake Premium", "pesoInicialKg": 15.5}');

        Map<String, Object> res = parse(LoteResource.doPatch());

        System.assertEquals(true, res.get('success'));
        Lote__c updated = [SELECT Cepa__c, Peso_inicial_Kg__c
                           FROM Lote__c WHERE ignia_id__c = 1];
        System.assertEquals('Shiitake Premium', updated.Cepa__c);
        System.assertEquals(15.5, updated.Peso_inicial_Kg__c);
    }

    // ── PATCH sin ID en URL ───────────────────────────────────────────────────────

    @IsTest
    static void doPatch_sinId_devuelve400() {
        setCtx('PATCH', '', '{"estado": "Finalizado"}');

        Map<String, Object> res = parse(LoteResource.doPatch());

        System.assertEquals(false, res.get('success'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ── PATCH ID inexistente ──────────────────────────────────────────────────────

    @IsTest
    static void doPatch_idInexistente_devuelve404() {
        setCtx('PATCH', '9999', '{"estado": "Finalizado"}');

        Map<String, Object> res = parse(LoteResource.doPatch());

        System.assertEquals(false, res.get('success'));
        System.assertEquals(404, RestContext.response.statusCode);
    }
}
