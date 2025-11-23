public with sharing class AI_CaseInsightsController {

    public class CaseAIData {
        @AuraEnabled public String summary;
        @AuraEnabled public String tone;
        @AuraEnabled public String recommendation;
        @AuraEnabled public Datetime lastAnalyzed;
        @AuraEnabled public String source;
    }

    @AuraEnabled(cacheable=true)
    public static CaseAIData getCaseAIData(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case Id is required.');
        }

        Case c = [
            SELECT AI_Summary__c,
                   AI_Tone__c,
                   AI_Recommendation__c,
                   AI_Last_Analyzed__c,
                   AI_Source__c
            FROM Case
            WHERE Id = :caseId
        ];

        CaseAIData dto = new CaseAIData();
        dto.summary = c.AI_Summary__c;
        dto.tone = c.AI_Tone__c;
        dto.recommendation = c.AI_Recommendation__c;
        dto.lastAnalyzed = c.AI_Last_Analyzed__c;
        dto.source = c.AI_Source__c;

        return dto;
    }
}
