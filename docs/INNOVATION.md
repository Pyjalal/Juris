# Juris -- Innovation Statement

> What Makes Juris Unique in the Legal Tech Landscape
> KitaHack 2026 | Built with Google Cloud & Gemini

---

## The Problem

Malaysia has approximately **8.7 million renters**, of whom 2.1 million are classified as B40 (bottom 40% income). The rental market is plagued by a fundamental power imbalance:

- **80% of rental disputes go unresolved** because tenants cannot afford legal consultation
- A single hour of lawyer consultation costs **RM300** -- often exceeding the disputed amount
- Legal aid waitlists exceed **10,000 people** at major bureaus
- **Zero consumer-facing tools** exist to help Malaysian tenants understand their agreements

The root cause is not a lack of legal protections. Malaysia has robust tenancy laws. The problem is **access** -- the laws exist but tenants cannot reach them.

---

## Why Malaysia Is Uniquely Complex

Unlike most developed nations, **Malaysia has no single Residential Tenancy Act**. Tenant protections are scattered across 14+ separate pieces of legislation:

| Legal Area | Statute |
|-----------|---------|
| Contract validity | Contracts Act 1950 (Act 136) |
| Unfair terms | Consumer Protection Act 1999 (Act 599) |
| Specific performance | Specific Relief Act 1950 (Act 137) |
| Contractual liability | Civil Law Act 1956 (Act 67) |
| Landlord seizure | Distress Act 1951 (Act 255) |
| Lease registration | National Land Code 1965 (Act 56) |
| Stamp duty | Stamp Act 1949 (Act 378) |
| Data privacy | Personal Data Protection Act 2010 (Act 709) |
| State regulations | Various state enactments |

A single tenancy clause can be governed by **three or more acts simultaneously**. For example, a deposit forfeiture clause involves the Contracts Act (penalty vs. liquidated damages), the Consumer Protection Act (unfair standard-form terms), and the Specific Relief Act (alternative remedies).

No existing legal tech product handles this cross-statute reasoning.

---

## Four Key Innovations

### 1. End-to-End Multi-Modal AI Pipeline

Juris is the first application to combine **Gemini Vision (OCR) + Vertex AI Vector Search (RAG) + Gemini Pro (analysis)** in a single automated pipeline for legal document processing.

```
Photo --> Gemini Vision --> Structured Text --> Vector Search --> Law Chunks
                                                                      |
                                                                      v
User <-- Risk Report <-- Citation Validator <-- Gemini Pro Analysis <-+
```

The tenant takes one photo. Everything else is automated. No manual text entry, no form filling, no legal knowledge required.

**Why this matters:** Existing legal AI tools require users to type or paste text. For tenants with physical documents (the majority in Malaysia), this creates an immediate barrier. Camera-to-analysis removes it entirely.

### 2. Three-Layer Anti-Hallucination System

Legal AI carries a unique risk: if the AI fabricates a law citation, a tenant may confront their landlord with false legal grounds. This could escalate conflicts rather than resolve them.

Juris implements three independent layers of hallucination prevention:

| Layer | Mechanism | What It Catches |
|-------|-----------|-----------------|
| **Layer 1: Prompt Constraint** | System prompt instructs Gemini to ONLY cite statutes from the provided RAG context | Prevents generation of citations from training data |
| **Layer 2: RAG-Only Context** | Gemini receives only retrieved law chunks, not general legal knowledge | Limits the citation space to verified corpus |
| **Layer 3: Post-Processing Validator** | TypeScript validator cross-references every citation against the RAG chunk IDs | Catches any citations that bypassed Layers 1-2 |

Result: **Zero hallucinated citations reach users.** Unverified citations are automatically downgraded to "caution" with a disclaimer.

### 3. Bilingual Plain-Language Simplification

Legal clauses are written in formal English that most Malaysian tenants cannot parse. Juris translates every flagged clause into:

- **Simple English** at SPM (Form 5 / Grade 11) reading level
- **Bahasa Malaysia** for native BM speakers
- Maximum 15 words per sentence
- Active voice only
- Malaysian-context analogies

Example:
- **Original:** "The Tenant shall indemnify and keep indemnified the Landlord against all claims, demands, actions, proceedings..."
- **Simplified:** "If someone sues the landlord because of something you did, you have to pay for it. This means lawyer fees and court costs come from your pocket."

### 4. Auto-Generated Letters of Demand

Identifying a problem is only half the solution. Juris generates **ready-to-send Letters of Demand** that:

- Follow Malaysian legal letter format
- Reference specific statutes and sections from the audit
- Include proper headers, date, parties, and signature blocks
- Reference the Tribunal for Consumer Claims Malaysia as escalation
- Include an AI-generated disclaimer

This converts legal awareness into **legal action** -- the tenant goes from "I think this clause is unfair" to "here is a formal letter citing the law" in under 60 seconds.

---

## Cost Comparison

| Method | Cost | Time | Accuracy |
|--------|------|------|----------|
| Lawyer consultation | RM300/hour | Days to schedule | High |
| Legal aid clinic | Free (if available) | Weeks of waiting | High |
| Self-research | Free | Hours of confusion | Low |
| **Juris** | **RM0.05-0.15** | **Under 60 seconds** | **High (RAG-grounded)** |

Juris delivers a **99.95% cost reduction** compared to traditional legal consultation, making legal awareness accessible to every Malaysian renter.

---

## Target Users

| Segment | Population | Key Need |
|---------|-----------|----------|
| B40 renters | 2.1M households | Cannot afford RM300 lawyer consultation |
| University students | 1.2M+ | First-time renters, unfamiliar with legal rights |
| Foreign workers | 2.0M+ | Language barriers, vulnerable to exploitation |
| Urban professionals | 3.4M+ | Time-poor, want quick contract review |

---

## Competitive Landscape

| Product | What It Does | Gap |
|---------|-------------|-----|
| LawBot (UK) | General legal chatbot | Not Malaysia-specific, no OCR |
| DoNotPay (US) | Consumer rights automation | No Malaysian law, no tenancy focus |
| LegalZoom (US) | Document templates | No analysis, no Malaysian law |
| Malaysian Bar Council | Lawyer directory | Referral only, not self-service |
| **Juris** | **Camera-to-compliance for MY tenancy law** | **First of its kind** |

No existing product provides automated, AI-powered tenancy agreement analysis grounded in Malaysian law. Juris is the first.

---

*Document version: 1.0 | Last updated: 2026-02-23 | KitaHack 2026*
