@RestResource(urlMapping='/ignia/lotes/*')
global with sharing class LoteResource {

    // ── DTOs ─────────────────────────────────────────────────────────────────────

    global class LoteDTO {
        public String  id;
        public String  name;
        public String  cepa;
        public String  estado;
        public Date    fechaInoculacion;
        public Decimal pesoInicialKg;
        public Decimal eficienciaBiologica;
        public Decimal totalCosechadoKg;
        public Integer cantidadCosechas;
        public Integer igniaId;
        public Boolean archivado;

        public LoteDTO(Lote__c l) {
            this.id                  = l.Id;
            this.name                = l.Name;
            this.cepa                = l.Cepa__c;
            this.estado              = l.Estado__c;
            this.fechaInoculacion    = l.Fecha_Inoculacion__c;
            this.pesoInicialKg       = l.Peso_inicial_Kg__c;
            this.eficienciaBiologica = l.Eficiencia_Biologica__c;
            this.totalCosechadoKg    = l.Total_Cosechado_Kg__c;
            this.cantidadCosechas    = l.Cantidad_Cosechas__c != null
                                       ? Integer.valueOf(l.Cantidad_Cosechas__c) : 0;
            this.igniaId             = l.ignia_id__c != null
                                       ? Integer.valueOf(l.ignia_id__c) : null;
            this.archivado           = l.Archivado__c;
        }
    }

    global class ApiResponse {
        public Boolean success;
        public Object  data;
        public String  error;

        public ApiResponse(Object data) {
            this.success = true;
            this.data    = data;
        }

        public ApiResponse(String errorMsg, Integer statusCode) {
            this.success = false;
            this.error   = errorMsg;
            RestContext.response.statusCode = statusCode;
        }
    }

    // ── GET ──────────────────────────────────────────────────────────────────────
    //   GET /ignia/lotes/          → all non-archived lotes
    //   GET /ignia/lotes/{id}      → single lote by Salesforce ID or ignia_id__c

    @HttpGet
    global static String doGet() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        try {
            String urlId = extractUrlId();

            if (String.isBlank(urlId)) {
                List<LoteDTO> dtos = new List<LoteDTO>();
                for (Lote__c l : queryAll()) dtos.add(new LoteDTO(l));
                return JSON.serialize(new ApiResponse(dtos));
            }

            Lote__c lote = queryOne(urlId);
            if (lote == null) return JSON.serialize(new ApiResponse('Lote not found: ' + urlId, 404));
            return JSON.serialize(new ApiResponse(new LoteDTO(lote)));

        } catch (Exception e) {
            return JSON.serialize(new ApiResponse(e.getMessage(), 500));
        }
    }

    // ── PATCH ────────────────────────────────────────────────────────────────────
    //   PATCH /ignia/lotes/{id}
    //   Body (JSON, all fields optional):
    //     { "cepa": "...", "estado": "...", "pesoInicialKg": 10.5, "igniaId": 42 }

    @HttpPatch
    global static String doPatch() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        String urlId = extractUrlId();
        if (String.isBlank(urlId)) {
            return JSON.serialize(new ApiResponse('Record ID is required in the URL', 400));
        }

        try {
            Lote__c existing = queryOne(urlId);
            if (existing == null) return JSON.serialize(new ApiResponse('Lote not found: ' + urlId, 404));

            Map<String, Object> body = (Map<String, Object>)
                JSON.deserializeUntyped(RestContext.request.requestBody.toString());

            Lote__c patch = new Lote__c(Id = existing.Id);
            Boolean changed = false;

            if (body.containsKey('cepa')) {
                patch.Cepa__c = (String) body.get('cepa');
                changed = true;
            }
            if (body.containsKey('estado')) {
                patch.Estado__c = (String) body.get('estado');
                changed = true;
            }
            if (body.containsKey('pesoInicialKg')) {
                patch.Peso_inicial_Kg__c = (Decimal) body.get('pesoInicialKg');
                changed = true;
            }
            if (body.containsKey('igniaId')) {
                patch.ignia_id__c = (Decimal) body.get('igniaId');
                changed = true;
            }

            if (changed) update patch;

            return JSON.serialize(new ApiResponse(new LoteDTO(queryOne(String.valueOf(existing.Id)))));

        } catch (Exception e) {
            return JSON.serialize(new ApiResponse(e.getMessage(), 500));
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private static String extractUrlId() {
        String uri  = RestContext.request.requestURI;
        String tail = uri.substring(uri.lastIndexOf('/') + 1);
        return String.isBlank(tail) ? null : tail;
    }

    private static List<Lote__c> queryAll() {
        return [
            SELECT Id, Name, Cepa__c, Estado__c, Fecha_Inoculacion__c,
                   Peso_inicial_Kg__c, Eficiencia_Biologica__c,
                   Total_Cosechado_Kg__c, Cantidad_Cosechas__c,
                   ignia_id__c, Archivado__c
            FROM   Lote__c
            WHERE  Archivado__c = false
            ORDER BY CreatedDate DESC
        ];
    }

    // Accepts Salesforce ID (15/18-char) or numeric ignia_id__c
    private static Lote__c queryOne(String identifier) {
        List<Lote__c> rows;

        if (identifier.length() == 15 || identifier.length() == 18) {
            try {
                rows = [
                    SELECT Id, Name, Cepa__c, Estado__c, Fecha_Inoculacion__c,
                           Peso_inicial_Kg__c, Eficiencia_Biologica__c,
                           Total_Cosechado_Kg__c, Cantidad_Cosechas__c,
                           ignia_id__c, Archivado__c
                    FROM   Lote__c
                    WHERE  Id = :identifier
                    LIMIT  1
                ];
                if (!rows.isEmpty()) return rows[0];
            } catch (System.QueryException e) {
                // identifier wasn't a valid Salesforce ID — fall through
            }
        }

        if (identifier.isNumeric()) {
            Decimal externalId = Decimal.valueOf(identifier);
            rows = [
                SELECT Id, Name, Cepa__c, Estado__c, Fecha_Inoculacion__c,
                       Peso_inicial_Kg__c, Eficiencia_Biologica__c,
                       Total_Cosechado_Kg__c, Cantidad_Cosechas__c,
                       ignia_id__c, Archivado__c
                FROM   Lote__c
                WHERE  ignia_id__c = :externalId
                LIMIT  1
            ];
            if (!rows.isEmpty()) return rows[0];
        }

        return null;
    }
}
