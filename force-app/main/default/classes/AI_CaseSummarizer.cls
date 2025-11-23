public with sharing class AI_CaseSummarizer {

    // -------- Flow Input / Output DTOs --------

    public class Request {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    public class Response {
        @InvocableVariable public Id caseId;
        @InvocableVariable public String summary;
        @InvocableVariable public String tone;
        @InvocableVariable public String recommendation;
    }

    // Resultado interno
    private class AIResult {
        public String summary;
        public String tone;
        public String recommendation;
    }

    // -------- Configuración IA --------
    // Para repos públicos: mock por defecto.
    private static final Boolean USE_EXTERNAL_AI = false;

    // Placeholder seguro (NO expone tu key real)
    private static final String OPENROUTER_API_KEY = 'YOUR_OPENROUTER_API_KEY';

    // -------- Método Invocable para Flow --------

    @InvocableMethod(
        label='Analyze Cases with AI',
        description='Analyzes case descriptions and returns summary, tone and recommendation.'
    )
    public static List<Response> analyzeCases(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) return responses;

        Set<Id> ids = new Set<Id>();
        for (Request r : requests)
            if (r != null && r.caseId != null) ids.add(r.caseId);

        if (ids.isEmpty()) return responses;

        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, Description FROM Case WHERE Id IN :ids]
        );

        for (Request r : requests) {
            if (r == null || !caseMap.containsKey(r.caseId)) continue;

            Case c = caseMap.get(r.caseId);
            AIResult result = analyzeText(c.Description);

            Response res = new Response();
            res.caseId = c.Id;
            res.summary = result.summary;
            res.tone = result.tone;
            res.recommendation = result.recommendation;

            responses.add(res);
        }

        return responses;
    }

    // -------- Selección Mock / IA real --------

    private static AIResult analyzeText(String text) {
        if (String.isBlank(text)) {
            AIResult empty = new AIResult();
            empty.summary = 'No description provided.';
            empty.tone = 'Unknown';
            empty.recommendation = 'Ask the customer for more details before proceeding.';
            return empty;
        }

        if (USE_EXTERNAL_AI) {
            try { return callExternalAI(text); }
            catch (Exception e) { return mockAnalyzeText(text); }
        }

        return mockAnalyzeText(text);
    }

    // -------- Lógica MOCK segura --------

    private static AIResult mockAnalyzeText(String text) {
        AIResult r = new AIResult();
        String lower = text.toLowerCase();

        // Determinar tono
        if (lower.contains('angry') || lower.contains('frustrado') || lower.contains('enojado') || lower.contains('reclamo'))
            r.tone = 'Negative';
        else if (lower.contains('gracias') || lower.contains('thank') || lower.contains('excelente'))
            r.tone = 'Positive';
        else
            r.tone = 'Neutral';

        // Resumen
        r.summary = (text.length() > 300)
            ? text.substring(0, 300) + '...'
            : text;

        // Recomendación
        if (r.tone == 'Negative')
            r.recommendation = 'Empathize with the customer and provide a clear next step.';
        else if (r.tone == 'Positive')
            r.recommendation = 'Thank the customer and offer follow-up.';
        else
            r.recommendation = 'Provide a clear and concise response confirming next steps.';

        return r;
    }

    // -------- IA Real (opcional) --------

    private static AIResult callExternalAI(String text) {

        // Si alguien instala sin key → fallback automático
        if (String.isBlank(OPENROUTER_API_KEY)) {
            return mockAnalyzeText(text);
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://openrouter.ai/api/v1/chat/completions');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + OPENROUTER_API_KEY');

        // Prompt que solo pide JSON
        String userPrompt =
            'Return ONLY a JSON object with: summary, tone, recommendation. ' +
            'Analyze this case description: ' + text;

        Map<String,Object> body = new Map<String,Object>{
            'model' => 'deepseek/deepseek-r1:free',
            'messages' => new List<Object>{
                new Map<String,Object>{ 'role' => 'system', 'content' => 'Support assistant.' },
                new Map<String,Object>{ 'role' => 'user', 'content' => userPrompt }
            }
        };

        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HttpResponse res = http.send(req);

        Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        Map<String,Object> msg = (Map<String,Object>) ((List<Object>) parsed.get('choices'))[0];
        String content = (String) ((Map<String,Object>) msg.get('message')).get('content');

        Map<String,Object> json = (Map<String,Object>) JSON.deserializeUntyped(content);

        AIResult r = new AIResult();
        r.summary = (String) json.get('summary');
        r.tone = (String) json.get('tone');
        r.recommendation = (String) json.get('recommendation');

        return r;
    }
}
