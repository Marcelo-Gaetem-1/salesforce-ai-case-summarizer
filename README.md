# 🤖 AI Case Summarizer & Tone Analyzer (Salesforce)

Proyecto desarrollado en Salesforce que analiza la descripción de un Case, genera un resumen automático, detecta el tono del cliente y recomienda la acción siguiente para el agente.  
Construido con **Apex, Flow y Lightning Web Components**, funciona en modo **mock** por defecto, pero está preparado para usar IA real si se activa.

---

## 🚀 Overview

Cuando se actualiza la Description de un Case:

1. Un **Record-Triggered Flow** llama a `AI_CaseSummarizer`.
2. El texto se analiza (mock o IA real).
3. Se generan:  
   - Summary  
   - Tone (Positive, Neutral, Negative, Unknown)  
   - Recommendation
4. Se actualizan campos AI_* del Case.
5. El LWC `aiCaseInsights` muestra los resultados con:  
   - Badge de tono + emoji  
   - Sentiment bar  
   - Summary  
   - Recommendation  
   - Last analyzed  
   - Refresh button  

---

## 🧱 Arquitectura

### **Apex — AI_CaseSummarizer**
- Método invocable usado por Flow.
- Analiza descripción (mock o IA externa).
- Devuelve summary, tone, recommendation.

### **Apex — AI_CaseInsightsController**
- Expone datos AI del Case para el LWC.
- Cacheable y optimizado.

### **Record-Triggered Flow**
- Se activa al cambiar la Description.
- Invoca al summarizer.
- Actualiza campos personalizados.

### **LWC — aiCaseInsights**
- UI moderna, responsiva y auto-refresh.
- Incluye badge, emoji y barra de sentimiento.

---

## 📁 Estructura del proyecto

