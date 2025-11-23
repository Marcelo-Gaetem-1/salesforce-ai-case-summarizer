import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getCaseAIData from '@salesforce/apex/AI_CaseInsightsController.getCaseAIData';

export default class AiCaseInsights extends LightningElement {
    @api recordId;

    @track summary;
    @track tone;
    @track recommendation;
    @track lastAnalyzed;
    @track source;
    @track error;
    @track isLoading = true;

    wiredResult;
    recordDataInitialized = false;

    //  Datos de IA desde Apex
    @wire(getCaseAIData, { caseId: '$recordId' })
    wiredCaseAIData(value) {
        this.wiredResult = value;
        const { error, data } = value;
        this.isLoading = false;

        if (data) {
            this.summary = data.summary;
            this.tone = data.tone;
            this.recommendation = data.recommendation;
            this.lastAnalyzed = data.lastAnalyzed;
            this.source = data.source;
            this.error = undefined;
        } else if (error) {
            this.error = this.normalizeError(error);
            this.summary = undefined;
            this.tone = undefined;
            this.recommendation = undefined;
            this.lastAnalyzed = undefined;
            this.source = undefined;
        }
    }

    //  Suscribirse a cambios del Case (cuando se guarda)
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            'Case.Description',
            'Case.AI_Summary__c',
            'Case.AI_Tone__c',
            'Case.AI_Recommendation__c'
        ]
    })
    wiredCaseRecord({ error, data }) {
        if (error) {
            // solo es para detectar cambios
            return;
        }

        if (data) {
            // La primera vez solo marcamos inicialización
            if (!this.recordDataInitialized) {
                this.recordDataInitialized = true;
            } else {
                // En cambios posteriores al registro -> refrescamos IA automáticamente
                this.autoRefreshAI();
            }
        }
    }

    get hasData() {
        return !!(this.summary || this.recommendation || this.tone);
    }

    get toneLabel() {
        return this.tone ? this.tone : 'Unknown';
    }

    get toneClass() {
        switch (this.tone) {
            case 'Positive':
                return 'tone-badge tone-positive';
            case 'Negative':
                return 'tone-badge tone-negative';
            case 'Neutral':
                return 'tone-badge tone-neutral';
            default:
                return 'tone-badge tone-unknown';
        }
    }

    // Emoji dinámico según tono
    get toneEmoji() {
        switch (this.tone) {
            case 'Positive':
                return '🙂';
            case 'Negative':
                return '😡';
            case 'Neutral':
                return '😐';
            default:
                return '😶';
        }
    }

    // Score 1-100 derivado del tono (simple mock)
    get sentimentScore() {
        switch (this.tone) {
            case 'Positive':
                return 80;
            case 'Negative':
                return 20;
            case 'Neutral':
                return 50;
            default:
                return 50;
        }
    }

    // Estilo de la barra de sentimiento
    get sentimentBarStyle() {
        const value = this.sentimentScore || 0;
        return `width: ${value}%;`;
    }

    get lastAnalyzedFormatted() {
        if (!this.lastAnalyzed) {
            return null;
        }

        try {
            const date = new Date(this.lastAnalyzed);
            return new Intl.DateTimeFormat('es-CL', {
                dateStyle: 'short',
                timeStyle: 'short'
            }).format(date);
        } catch (e) {
            return this.lastAnalyzed;
        }
    }

    // Botón Refresh manual
    async handleRefresh() {
        await this.refreshAIData();
    }

    // Auto-refresh cuando el Case cambia
    async autoRefreshAI() {
        await this.refreshAIData();
    }

    // Lógica central de refresco
    async refreshAIData() {
        if (!this.wiredResult) {
            return;
        }
        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.error = this.normalizeError(e);
        } finally {
            this.isLoading = false;
        }
    }

    normalizeError(error) {
    if (error && Array.isArray(error.body)) {
        return error.body.map(e => e.message).join(', ');
    } else if (error && error.body && error.body.message) {
        return error.body.message;
    }
    return 'Unexpected error loading AI insights.';
    }

}
