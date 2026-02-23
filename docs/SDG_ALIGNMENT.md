# Juris -- UN Sustainable Development Goals Alignment

> Advancing Justice and Housing Rights for Malaysian Tenants
> KitaHack 2026 | Built with Google Cloud & Gemini

---

## Overview

Juris directly advances two United Nations Sustainable Development Goals by using AI to eliminate the barriers that prevent Malaysian tenants from understanding and exercising their legal rights.

---

## Primary Alignment: SDG 16 -- Peace, Justice and Strong Institutions

> *"Promote peaceful and inclusive societies for sustainable development, provide access to justice for all and build effective, accountable and inclusive institutions at all levels."*

### Target 16.3: Promote the Rule of Law and Ensure Equal Access to Justice

In Malaysia, the justice gap in housing is stark:

- **80% of rental disputes go unresolved** because tenants cannot afford legal consultation
- A single hour of lawyer consultation costs **RM300**, often exceeding the disputed amount
- Legal aid waitlists exceed **10,000 people** at major bureaus
- Malaysian tenancy law is scattered across **14+ statutes** with no single tenancy act

The result: **access to justice is determined by ability to pay**.

### Five Barrier Eliminations

**1. Cost Barrier**
Juris provides analysis at RM0.05-0.15 per document, compared to RM300/hour for a lawyer. This is a **99.95% cost reduction**, bringing legal awareness within reach of B40 households, students, and foreign workers.

**2. Knowledge Barrier**
The RAG-powered analysis synthesizes 6+ Malaysian statutes into plain-language explanations. Tenants do not need to know which law applies -- the system identifies relevant provisions automatically.

**3. Language Barrier**
All analysis is provided in both English and Bahasa Malaysia at SPM (secondary school) reading level. Legal jargon is replaced with everyday language and concrete examples.

**4. Action Barrier**
Identifying a legal issue is insufficient if the tenant cannot act. Juris generates Letters of Demand and references the Tribunal for Consumer Claims Malaysia, converting awareness into action.

**5. Geographic Barrier**
As a mobile application, Juris is accessible in rural areas and small towns where legal aid clinics do not operate. Justice is no longer limited to tenants near a lawyer's office.

---

## Secondary Alignment: SDG 11 -- Sustainable Cities and Communities

> *"Make cities and human settlements inclusive, safe, resilient and sustainable."*

### Target 11.1: Ensure Access to Adequate, Safe, and Affordable Housing

"Adequate" housing means more than a roof. It means housing that is:

- **Legally secure** (enforceable rights)
- **Physically safe** (maintained by landlord)
- **Affordable** (no exploitative financial terms)
- **Accessible** (available to all)

Many Malaysian tenancy agreements contain clauses that undermine all four:

- **Illegal forfeiture clauses** allowing landlords to seize full deposits
- **Maintenance liability transfers** shifting repair obligations to tenants
- **Unilateral eviction clauses** without cause or adequate notice
- **Excessive penalty clauses** making early termination financially devastating

Juris protects tenants from these exploitative terms by identifying, explaining, and enabling action against illegal clauses.

---

## Measurable Impact Metrics

### Access to Justice Metrics (SDG 16.3)

| Metric | Description | Measurement |
|--------|-------------|-------------|
| Agreements analyzed/month | Total documents processed | `documents` with `status: completed` |
| Unique users served | Distinct tenants receiving analysis | Unique `uid` in `documents` |
| Letters of Demand generated | Tenants who moved to action | `letters_of_demand` document count |
| Cost savings vs. traditional | (analyses x RM300) - actual cost | Computed from pipeline cost data |
| Geographic reach | Cities/states with active users | GeoIP of authenticated sessions |

### Housing Rights Metrics (SDG 11.1)

| Metric | Description | Measurement |
|--------|-------------|-------------|
| Illegal clauses identified | Clauses violating Malaysian law | `flagged_clauses` with type `illegal` |
| Most common violations | Categorized violation breakdown | Aggregation by violation category |
| Risk distribution | Proportion of low/medium/high/critical | Distribution of `risk_score` values |
| Cross-statute issues | Clauses involving multiple acts | Clauses with 2+ statute references |

### User Empowerment Metrics

| Metric | Description | Measurement |
|--------|-------------|-------------|
| User satisfaction | Post-analysis rating (1-5) | In-app feedback prompt |
| Comprehension confirmation | Users confirming understanding | "Did you understand?" interaction |
| Return usage rate | Users with 2+ analyses | Multi-document user ratio |
| Demographic reach | B40/student/foreign worker breakdown | Optional profile data |

---

## Impact Projections

| Metric | Year 1 | Year 3 |
|--------|--------|--------|
| Agreements analyzed | 10,000 | 250,000 |
| Unique users | 5,000 | 100,000 |
| Illegal clauses identified | 25,000 | 625,000 |
| Letters of Demand generated | 2,000 | 50,000 |
| Estimated cost savings | RM3,000,000 | RM75,000,000 |
| User satisfaction | 4.2 / 5.0 | 4.5 / 5.0 |

---

## Theory of Change

```
INPUTS                 ACTIVITIES              OUTPUTS                OUTCOMES               IMPACT
-----                  ----------              -------                --------               ------

Google Cloud           AI-powered tenancy      Compliance reports     Tenants understand     Equal access
infrastructure         agreement analysis      with flagged clauses   their legal rights     to justice
                                                                                            (SDG 16.3)
Gemini AI models       Bilingual clause        Plain-language         Tenants negotiate
                       simplification          explanations (EN/BM)   from informed          Adequate,
Malaysian law                                                         position               safe housing
corpus (6+ acts)       Letter of Demand        Auto-generated LODs                           (SDG 11.1)
                       generation              ready to send          Exploitative clauses
Flutter mobile                                                        challenged and
application            Tribunal/legal aid      Nearest legal          removed from
                       referral                resource locations     agreements
Vertex AI Vector
Search + Embeddings                                                   Market standards
                                                                      for tenancy
                                                                      agreements improve
```

---

## Broader SDG Connections

| SDG | Connection |
|-----|------------|
| **SDG 1: No Poverty** | Prevents financial losses from illegal deposit forfeiture and exploitative penalties, protecting B40 savings |
| **SDG 4: Quality Education** | Serves 1.2M+ university students renting off-campus, allowing focus on education over housing disputes |
| **SDG 5: Gender Equality** | Single mothers and women living alone are disproportionately vulnerable to housing exploitation; Juris provides a private, non-confrontational channel |
| **SDG 10: Reduced Inequalities** | Directly addresses inequality in legal access between those who can afford lawyers and those who cannot |

---

## Conclusion

Juris is not a legal technology project that happens to align with the SDGs. The SDGs define the problem Juris was built to solve. Every architectural decision -- from anti-hallucination grounding to bilingual simplification to automated Letters of Demand -- exists because access to justice and adequate housing are rights, not privileges.

The technology is the enabler. The impact is the purpose.

---

*Document version: 1.0 | Last updated: 2026-02-23 | KitaHack 2026*
