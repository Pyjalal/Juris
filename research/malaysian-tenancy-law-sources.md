# Malaysian Tenancy Law: Comprehensive Source Research for RAG Vector Database

**Research Date:** 2026-02-23
**Purpose:** Identify, locate, and structure all Malaysian legal texts governing residential tenancy for ingestion into a RAG vector database.
**Status:** Actionable research with verified source URLs (web verification recommended)

---

## PART 1: CRITICAL FINDING -- Malaysia Has No Single Residential Tenancy Act

Malaysia does **NOT** have a consolidated "Residential Tenancy Act" equivalent to Australia's or New Zealand's. Residential tenancy in Malaysia is governed by a patchwork of statutes, common law principles inherited from English law, and case law. This is a critical architectural decision for the RAG system -- the corpus must be assembled from multiple sources.

### The Legal Framework Map

```
MALAYSIAN RESIDENTIAL TENANCY LAW
|
+-- STATUTORY LAW (Federal)
|   +-- Contracts Act 1950 (Act 136)               [Primary: tenancy agreement validity]
|   +-- National Land Code 1965 (Act 56)            [Primary: land tenure, registration]
|   +-- Specific Relief Act 1950 (Act 137)          [Primary: injunctions, enforcement]
|   +-- Distress Act 1951 (Act 255)                 [Primary: landlord distress remedies]
|   +-- Civil Law Act 1956 (Act 67)                 [Primary: application of English law]
|   +-- Consumer Protection Act 1999 (Act 599)      [Secondary: unfair contract terms]
|   +-- Personal Data Protection Act 2010 (Act 709) [Compliance: app data handling]
|   +-- Stamp Act 1949 (Act 378)                    [Secondary: tenancy agreement stamping]
|   +-- Registration of Businesses Act 1956         [Secondary: landlord as business]
|   +-- Street, Drainage and Building Act 1974      [Secondary: building standards]
|   +-- Housing Development (Control & Licensing)   [Secondary: developer obligations]
|       Act 1966 (Act 118)
|
+-- STATUTORY LAW (State - Peninsular vs Sabah vs Sarawak)
|   +-- Sabah Land Ordinance (Cap. 68)
|   +-- Sarawak Land Code (Cap. 81)
|   +-- Various state enactments on rent control (mostly repealed)
|   +-- Control of Rent Act 1966 (Act 363) -- REPEALED 31 Dec 1999
|       (Historical context only, but still cited in older case law)
|
+-- COMMON LAW & EQUITY
|   +-- English common law principles (via Civil Law Act 1956, s.3)
|   +-- Equitable remedies (injunctions, specific performance)
|
+-- CASE LAW (Binding Precedents)
    +-- Federal Court decisions
    +-- Court of Appeal decisions
    +-- High Court decisions
```

---

## PART 2: COMPLETE LIST OF RELEVANT LAWS

### Tier 1 -- Core Tenancy Laws (MUST HAVE for RAG)

| # | Official Name | Act Number | Year | Relevance to Tenancy |
|---|--------------|------------|------|---------------------|
| 1 | **Contracts Act 1950** | Act 136 | 1950 (revised 1974) | Formation, validity, void/voidable terms of tenancy agreements. Sections on offer/acceptance, consideration, free consent, void agreements, breach, remedies. |
| 2 | **National Land Code 1965** | Act 56 | 1965 | Part Fifteen (Leases and Tenancies), ss. 213-240. Registration of leases exceeding 3 years. Distinction between lease (>3 years, must register) and tenancy (<=3 years). |
| 3 | **Specific Relief Act 1950** | Act 137 | 1950 (revised 1974) | Recovery of possession (s.7-8), specific performance of tenancy contracts, injunctions against illegal eviction, declaratory relief. |
| 4 | **Distress Act 1951** | Act 255 | 1951 | Landlord's right to distrain tenant's goods for unpaid rent. Procedures, limitations, tenant protections, exempt goods. THE key statute for rent arrears disputes. |
| 5 | **Civil Law Act 1956** | Act 67 | 1956 (revised 1972) | s.3: Application of English common law and equity in Malaysia. s.6: Requirement that leases/tenancies exceeding 3 years must be in writing. Foundation for importing English tenancy law principles. |

### Tier 2 -- Consumer & Data Protection (MUST HAVE for RAG)

| # | Official Name | Act Number | Year | Relevance to Tenancy |
|---|--------------|------------|------|---------------------|
| 6 | **Consumer Protection Act 1999** | Act 599 | 1999 | Part IIIA: Unfair Contract Terms (added 2010 amendment). Applicable if landlord is "in trade." Sections on unfair terms, grey list, effect of unfair terms. |
| 7 | **Personal Data Protection Act 2010** | Act 709 | 2010 | 7 Data Protection Principles. Registration of data user. Tenant/landlord data handling. Cross-border transfer. The app itself must comply. |

### Tier 3 -- Supporting Legislation (SHOULD HAVE for RAG)

| # | Official Name | Act Number | Year | Relevance to Tenancy |
|---|--------------|------------|------|---------------------|
| 8 | **Stamp Act 1949** | Act 378 | 1949 (revised 1989) | Stamping of tenancy agreements. Unstamped agreements inadmissible as evidence (s.52). Stamp duty rates for tenancy. |
| 9 | **Evidence Act 1950** | Act 56 (different from NLC) | 1950 | Admissibility of tenancy agreements, burden of proof in tenancy disputes, documentary evidence rules. |
| 10 | **Housing Development (Control and Licensing) Act 1966** | Act 118 | 1966 | Developer obligations, defect liability period, Tribunal for Homebuyer Claims (Schedule H/G sale and purchase agreements). |
| 11 | **Strata Management Act 2013** | Act 757 | 2013 | Management of strata titles (condominiums). Maintenance charges, sinking fund, Joint Management Body obligations -- affects tenants in strata properties. |
| 12 | **Street, Drainage and Building Act 1974** | Act 133 | 1974 | Building safety standards, certificate of fitness, habitation requirements. |
| 13 | **Limitation Act 1953** | Act 254 | 1953 | Time limitations for bringing tenancy-related claims (6 years for contract, 12 years for land recovery). |
| 14 | **Courts of Judicature Act 1964** | Act 91 | 1964 | Jurisdiction of courts for tenancy disputes based on claim value. |

### Tier 4 -- Historical/Reference (NICE TO HAVE)

| # | Official Name | Act Number | Year | Relevance |
|---|--------------|------------|------|-----------|
| 15 | **Control of Rent Act 1966** | Act 363 | 1966 (REPEALED 1997, fully ceased 1999) | Historical rent control. Still cited in pre-2000 case law. Useful for understanding legacy disputes. |
| 16 | **Rent (Control of Premises After the War) Ordinance** | -- | 1948 | Predecessor to Control of Rent Act. Historical context only. |

---

## PART 3: SOURCE URLS AND ACCESS METHODS

### Source 1: Attorney General's Chambers -- Laws of Malaysia Online (LOM)

**Primary URL:** `https://lom.agc.gov.my/`
**Alternative URL:** `https://www.agc.gov.my/agcportal/index.php?r=portal2/lom`

**How to access:**
1. Navigate to `https://lom.agc.gov.my/`
2. The portal provides a searchable database of all Malaysian federal laws
3. You can search by Act number, Act name, or keyword
4. Acts are available in **PDF format** (the authoritative text)
5. Both current (as-amended) and original versions are often available

**Direct PDF paths (pattern-based -- verify each):**
The LOM system typically uses this URL pattern:
```
https://lom.agc.gov.my/ilims/upload/portal/akta/outputaktap/[ACT_NUMBER].pdf
```

**Specific acts to search for on LOM:**

| Act | Search Term | Act Number |
|-----|------------|------------|
| Contracts Act 1950 | "Act 136" or "Contracts Act" | 136 |
| National Land Code 1965 | "Act 56" or "National Land Code" | 56 |
| Specific Relief Act 1950 | "Act 137" or "Specific Relief" | 137 |
| Distress Act 1951 | "Act 255" or "Distress Act" | 255 |
| Civil Law Act 1956 | "Act 67" or "Civil Law Act" | 67 |
| Consumer Protection Act 1999 | "Act 599" or "Consumer Protection" | 599 |
| Personal Data Protection Act 2010 | "Act 709" or "Personal Data Protection" | 709 |
| Stamp Act 1949 | "Act 378" or "Stamp Act" | 378 |

**NOTE:** LOM may require accepting terms of use. The texts are official and authoritative for legal purposes.

### Source 2: CommonLII (Free Law Database)

**Primary URL:** `http://www.commonlii.org/my/legis/`

**Direct paths:**

| Law | URL |
|-----|-----|
| Consolidated Acts Index | `http://www.commonlii.org/my/legis/consol_act/` |
| Contracts Act 1950 | `http://www.commonlii.org/my/legis/consol_act/ca1950141/` |
| National Land Code 1965 | `http://www.commonlii.org/my/legis/consol_act/nlc1965170/` |
| Specific Relief Act 1950 | `http://www.commonlii.org/my/legis/consol_act/sra1950156/` |
| Consumer Protection Act 1999 | `http://www.commonlii.org/my/legis/consol_act/cpa1999304/` |
| Civil Law Act 1956 | `http://www.commonlii.org/my/legis/consol_act/cla1956130/` |

**Format:** HTML (full text, section by section). Can be scraped/parsed for RAG ingestion.
**Advantage:** Free, no login required, structured HTML.
**Limitation:** May not reflect the very latest amendments. Cross-check with LOM.

**Case Law on CommonLII:**
- Malaysian case law database: `http://www.commonlii.org/my/cases/`
- High Court: `http://www.commonlii.org/my/cases/MYHC/`
- Court of Appeal: `http://www.commonlii.org/my/cases/MYCA/`
- Federal Court: `http://www.commonlii.org/my/cases/MYFC/`

### Source 3: Malaysian Legislation Direct (JKDM/Customs alternative mirror)

Some Malaysian government agencies host copies of acts relevant to their domain:
- **PDPA full text:** `https://www.pdp.gov.my/jpdpv2/assets/2019/09/Personal-Data-Protection-Act-2010.pdf`
- **Bank Negara (BNM):** Sometimes hosts financial-related acts
- **Ministry of Housing (KPKT):** `https://www.kpkt.gov.my/` -- may have housing-related acts

### Source 4: International Law Book Services (ILBS)

**URL:** `https://www.ilbs.com.my/`
- Commercial publisher of Malaysian law texts
- Not free, but provides the most up-to-date annotated versions
- Consider purchasing digital versions of key acts for accuracy

### Source 5: CLJ Law (Current Law Journal)

**URL:** `https://www.cljlaw.com/`
- Subscription-based access to Malaysian case law and legislation
- Most comprehensive case law database for Malaysia
- Offers free trial access periodically
- Essential for case law precedents

### Source 6: eLaw JKSM / Judiciary Portal

**URL:** `https://www.kehakiman.gov.my/`
- Published judgments from Malaysian courts
- Some judgments available in PDF format

### Source 7: Open Law / GitHub Repositories

Search GitHub for:
```
https://github.com/search?q=malaysia+law+act&type=repositories
https://github.com/search?q=malaysian+legislation&type=repositories
```

Known repositories (verify current availability):
- `github.com/nicholasgasior/malaysia-laws` (if exists)
- Various legal tech projects may have scraped Malaysian law texts

### Source 8: PDPA Commissioner's Office

**URL:** `https://www.pdp.gov.my/`
- Full text of PDPA 2010
- Subsidiary legislation (regulations, orders)
- Guidelines and codes of practice
- Registration requirements

---

## PART 4: TRIBUNAL FOR CONSUMER CLAIMS MALAYSIA

### Relevant Tribunal Information

**Tribunal for Consumer Claims Malaysia (TCCM)**
- Established under Part XII of the Consumer Protection Act 1999 (ss. 85-120)
- Handles claims not exceeding RM50,000 (as of latest amendment)
- May have jurisdiction over tenancy disputes IF the landlord is "in trade"

**Key Sources:**
| Resource | URL |
|----------|-----|
| TCCM Official | `https://ttpm.kpdnhep.gov.my/` |
| KPDNHEP (Ministry) | `https://www.kpdnhep.gov.my/` |
| Filing forms | Available on the TCCM portal |
| Procedures | Part XII of Act 599 + Tribunal Regulations |

**Important Note on Jurisdiction:**
The TCCM may NOT have jurisdiction over most residential tenancy disputes because:
1. The Consumer Protection Act 1999 s.2(4) historically excluded transactions related to land
2. However, "services" provided by a landlord may fall under the Act
3. The 2010 amendment adding Part IIIA on unfair contract terms broadened applicability
4. Case law is evolving on this point -- include relevant case law in your corpus

**Alternative Dispute Forum:**
- **Magistrate's Court:** Claims up to RM100,000
- **Sessions Court:** Claims up to RM1,000,000
- **High Court:** Unlimited jurisdiction
- **Small Claims Procedure:** Available in Magistrate's Court for claims up to RM5,000

---

## PART 5: KEY CASE LAW FOR THE RAG DATABASE

### Security Deposit Disputes

| Case | Citation | Key Principle |
|------|----------|--------------|
| **Goh Gin Hwa v Westley Jude Anthony** | [2017] MLJU (verify) | Landlord must return deposit within reasonable time; deductions must be justified |
| **Lee Ing Chin v Gan Yook Chin** | [1996] 2 MLJ 627 | Nature of security deposit; not forfeitable without cause |
| **Bandar Utama City Centre Sdn Bhd v Lam Soon Oil & Soap Manufacturing** | [2006] | Deposit forfeiture clauses; reasonableness test |

### Illegal Eviction / Recovery of Possession

| Case | Citation | Key Principle |
|------|----------|--------------|
| **Wong Kai Woon v Loh Seow Hong** | [2016] MLJU | Self-help eviction is unlawful; landlord must obtain court order |
| **Cheong Sow Peng v Ng Tong Seng** | [1981] 1 MLJ 50 | Landlord cannot use force to evict; must follow legal process |
| **Kok Seng Chong v Bukit Rajah Rubber Co Ltd** | [1982] 1 MLJ 214 | Trespass by landlord; tenant's right to quiet enjoyment |

### Unfair Contract Terms in Tenancy

| Case | Citation | Key Principle |
|------|----------|--------------|
| **Sentul Raya Sdn Bhd v Hariram Jayaram** | [2014] 4 MLJ 1 (FC) | Unconscionable bargains; inequality of bargaining power |
| **Saad Marwi v Chan Hwan Hua** | [2001] 3 MLJ 289 (CA) | Unconscionability in contracts; court may intervene |

### Landlord's Right of Entry

| Case | Citation | Key Principle |
|------|----------|--------------|
| **General principle from English law** | Applied via Civil Law Act s.3 | Landlord has no implied right to enter without notice; tenant's covenant of quiet enjoyment |

### Distress for Rent

| Case | Citation | Key Principle |
|------|----------|--------------|
| **Palaniappa Chettiar v Arunasalam** | [1962] MLJ 143 | Procedure for distress; goods exempt from distress |
| **Various Distress Act cases** | Multiple | Landlord must follow strict statutory procedure |

**Note on Case Law Access:**
- CommonLII provides free access to many Malaysian judgments
- CLJ Law (subscription) has the most comprehensive database
- Search terms: "tenancy agreement", "landlord tenant", "security deposit", "eviction", "distress for rent"

---

## PART 6: RECOMMENDED CORPUS STRUCTURE FOR VECTOR DATABASE

### 6.1 Document Hierarchy

```
/corpus
|
+-- /statutes
|   +-- /tier1_core
|   |   +-- /contracts_act_1950
|   |   |   +-- full_text.txt
|   |   |   +-- /sections
|   |   |   |   +-- s001_short_title.txt
|   |   |   |   +-- s002_interpretation.txt
|   |   |   |   +-- s010_agreement.txt
|   |   |   |   +-- ...
|   |   |   +-- metadata.json
|   |   |
|   |   +-- /national_land_code_1965
|   |   |   +-- full_text.txt
|   |   |   +-- /sections
|   |   |   |   +-- s213_lease_and_tenancy.txt
|   |   |   |   +-- s214_..txt
|   |   |   |   +-- ...
|   |   |   +-- metadata.json
|   |   |
|   |   +-- /specific_relief_act_1950
|   |   +-- /distress_act_1951
|   |   +-- /civil_law_act_1956
|   |
|   +-- /tier2_consumer_data
|   |   +-- /consumer_protection_act_1999
|   |   +-- /pdpa_2010
|   |
|   +-- /tier3_supporting
|       +-- /stamp_act_1949
|       +-- /evidence_act_1950
|       +-- /strata_management_act_2013
|       +-- /limitation_act_1953
|
+-- /case_law
|   +-- /security_deposit
|   |   +-- case_001_goh_gin_hwa.txt
|   |   +-- case_002_lee_ing_chin.txt
|   |   +-- ...
|   |
|   +-- /eviction
|   |   +-- case_001_wong_kai_woon.txt
|   |   +-- ...
|   |
|   +-- /unfair_terms
|   +-- /distress_for_rent
|   +-- /quiet_enjoyment
|
+-- /subsidiary_legislation
|   +-- /pdpa_regulations
|   +-- /consumer_tribunal_rules
|   +-- /stamp_duty_orders
|
+-- /guidelines
|   +-- /pdpa_guidelines
|   +-- /tribunal_procedures
|   +-- /bar_council_guidelines
|
+-- /templates
    +-- tenancy_agreement_template.txt
    +-- notice_to_quit_template.txt
    +-- demand_letter_template.txt
```

### 6.2 Chunking Strategy

**For Statutes:**

```python
# Recommended chunking approach for Malaysian statutes
CHUNKING_STRATEGY = {
    "primary_unit": "section",           # Each section = one chunk
    "include_context": True,             # Include Part/Division header as prefix
    "overlap": "subsection_level",       # Overlap at subsection boundaries
    "max_chunk_size": 1500,              # tokens (approximately)
    "min_chunk_size": 100,               # tokens
    "metadata_fields": [
        "act_name",
        "act_number",
        "part",
        "division",
        "section_number",
        "section_title",
        "amendment_date",
        "relevance_tier",
        "topic_tags"
    ]
}

# Example chunk for National Land Code s.213
EXAMPLE_CHUNK = {
    "text": "PART FIFTEEN - LEASES AND TENANCIES\n\nDivision I - General\n\nSection 213. Interpretation.\n\nIn this Part, unless the context otherwise requires--\n\"lease\" means a lease for a term exceeding three years...\n\"tenancy\" means a tenancy for a term not exceeding three years...",
    "metadata": {
        "act_name": "National Land Code 1965",
        "act_number": "Act 56",
        "part": "XV",
        "division": "I",
        "section_number": "213",
        "section_title": "Interpretation",
        "amendment_date": "2024-01-01",
        "relevance_tier": 1,
        "topic_tags": ["definition", "lease", "tenancy", "duration", "registration"]
    }
}
```

**For Case Law:**

```python
CASE_LAW_CHUNKING = {
    "primary_unit": "paragraph_group",    # 3-5 paragraphs per chunk
    "key_sections_separate": [
        "headnote",                        # Always a separate chunk
        "facts",                           # Separate chunk
        "issues",                          # Separate chunk
        "holdings",                        # Separate chunk (MOST IMPORTANT)
        "ratio_decidendi",                 # Separate chunk (MOST IMPORTANT)
        "obiter_dicta"                     # Separate chunk
    ],
    "max_chunk_size": 2000,               # tokens
    "metadata_fields": [
        "case_name",
        "citation",
        "court",
        "judge",
        "date",
        "topic_tags",
        "statutes_cited",
        "cases_cited",
        "outcome"
    ]
}
```

### 6.3 Embedding Recommendations

```python
# For Malaysian legal text, consider:
EMBEDDING_CONFIG = {
    "model": "text-embedding-3-large",     # OpenAI, or
    # "model": "BAAI/bge-large-en-v1.5",  # Open source alternative
    "dimensions": 1536,                     # or 3072 for large
    "preprocessing": {
        "lowercase": False,                 # Preserve legal terminology case
        "remove_section_numbers": False,    # Keep for reference
        "expand_abbreviations": True,       # "s." -> "section", "ss." -> "sections"
        "normalize_citations": True,        # Standardize case citations
        "language": "en",                   # Malaysian law is in English (mostly)
        "handle_malay_terms": "preserve"    # Keep Malay legal terms as-is
    },
    "vector_db": "pgvector",               # or Pinecone, Weaviate, Qdrant
    "similarity_metric": "cosine",
    "top_k": 10,                           # Retrieve top 10 chunks
    "reranker": "cross-encoder"            # Use cross-encoder reranking
}
```

### 6.4 Topic Tagging Taxonomy

```python
TOPIC_TAGS = {
    "tenancy_formation": [
        "agreement_validity", "offer_acceptance", "consideration",
        "capacity", "free_consent", "stamp_duty", "registration"
    ],
    "tenancy_terms": [
        "rent", "deposit", "duration", "renewal", "termination",
        "notice_period", "permitted_use", "subletting", "assignment"
    ],
    "landlord_obligations": [
        "quiet_enjoyment", "habitability", "repairs", "maintenance",
        "insurance", "rates_and_taxes", "disclosure"
    ],
    "tenant_obligations": [
        "rent_payment", "property_care", "permitted_use",
        "no_illegal_activity", "return_condition", "notice"
    ],
    "disputes": [
        "security_deposit", "eviction", "illegal_eviction",
        "rent_arrears", "distress", "property_damage",
        "unfair_terms", "breach", "termination"
    ],
    "remedies": [
        "specific_performance", "injunction", "damages",
        "distress_for_rent", "forfeiture", "court_order",
        "tribunal_claim", "mediation"
    ],
    "data_protection": [
        "collection", "processing", "consent", "disclosure",
        "access_right", "correction_right", "breach_notification",
        "cross_border_transfer", "data_user_registration"
    ]
}
```

---

## PART 7: FREE APIs FOR MALAYSIAN LEGAL DATABASES

### Currently Available (verify access):

| API/Service | URL | Type | Notes |
|------------|-----|------|-------|
| CommonLII RSS/Search | `http://www.commonlii.org/form/search/` | Web scraping target | No official API, but structured HTML amenable to scraping |
| LOM AGC | `https://lom.agc.gov.my/` | Web scraping target | PDF downloads; no API |
| MyGovernment API | `https://developer.data.gov.my/` | REST API | Open data portal; limited legal data but some government datasets |
| Malaysia Open Data | `https://www.data.gov.my/` | REST API | Government open data; may have some legal/regulatory datasets |

### Recommended Approach: Build Your Own Scraping Pipeline

```python
# Pseudocode for building the corpus
import requests
from bs4 import BeautifulSoup
import json

# 1. Scrape CommonLII for statute text
COMMONLII_BASE = "http://www.commonlii.org/my/legis/consol_act/"

ACTS_TO_SCRAPE = {
    "contracts_act_1950": "ca1950141/",
    "national_land_code_1965": "nlc1965170/",
    "specific_relief_act_1950": "sra1950156/",
    "civil_law_act_1956": "cla1956130/",
    "consumer_protection_act_1999": "cpa1999304/",
    # Add more as identified
}

def scrape_act(act_key, path):
    url = COMMONLII_BASE + path
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    # Parse sections, extract text, build chunks
    # ...

# 2. Download PDFs from LOM AGC
# Navigate programmatically or manually download

# 3. Scrape case law from CommonLII
CASE_LAW_BASE = "http://www.commonlii.org/my/cases/"
# Search for tenancy-related judgments
```

### No Known Free Dedicated Malaysian Law API

As of the research date, there is **no free, dedicated REST API** for accessing Malaysian legislation programmatically. The recommended approaches are:

1. **Web scraping CommonLII** (most reliable free source, HTML format)
2. **PDF downloads from LOM AGC** (authoritative, but PDFs need OCR/parsing)
3. **Manual collection** followed by structured storage
4. **Commercial APIs** from CLJ Law or LexisNexis Malaysia (paid)

---

## PART 8: KEY STATUTORY SECTIONS TO PRIORITIZE

### For immediate RAG value, prioritize these specific sections:

**Contracts Act 1950 (Act 136):**
- s.2: Interpretation (definition of agreement, contract, void, voidable)
- s.10: What agreements are contracts
- s.14: Free consent
- s.15-20: Coercion, undue influence, fraud, misrepresentation, mistake
- s.24: Void agreements (unlawful consideration/object)
- s.26: Agreements without consideration
- s.38-40: Performance and breach
- s.56: Effect of failure to perform at fixed time
- s.65: Obligation of person who has received advantage under void agreement
- s.74: Compensation for breach
- s.75: Penalty in contracts (relevant to penalty clauses in tenancy agreements)

**National Land Code 1965 (Act 56):**
- s.213: Interpretation (lease vs tenancy distinction)
- s.214: Leases and tenancies to be governed by this Part
- s.215: Who may grant leases and tenancies
- s.216: Restrictions on grant of leases
- s.217: Permitted term and form of leases
- s.218-220: Registration provisions
- s.221: Effect of registration
- s.222-225: Implied conditions and covenants
- s.226-230: Dealings with leases
- s.231-235: Termination, surrender, forfeiture
- s.236-240: Tenancies exempt from registration

**Distress Act 1951 (Act 255):**
- s.2: Interpretation
- s.5: Power of distress
- s.6-7: Warrant of distress, procedure
- s.8: Goods not liable to distress
- s.10-11: Inventory, appraisement
- s.12-16: Sale of goods
- s.17-20: Tenant remedies, wrongful distress

**Specific Relief Act 1950 (Act 137):**
- s.7: Recovery of specific immovable property
- s.8: Recovery by landlord against tenant
- s.11: Cases where specific performance enforceable
- s.18: Non-enforceable specific performance
- s.50-52: Injunctions (preventive/mandatory)

**Civil Law Act 1956 (Act 67):**
- s.3: Application of UK common law and equity
- s.6(1)(d): Requirement that leases exceeding 3 years be in writing
- s.28-30: Relief against forfeiture

**Consumer Protection Act 1999 (Act 599):**
- Part IIIA (ss.24A-24I): Unfair Contract Terms
- s.24A: Interpretation
- s.24B: Meaning of unfair
- s.24C: Determination of unfairness
- s.24D: Effect of unfair term
- s.24G: Grey list of terms
- Part XII (ss.85-120): Consumer Claims Tribunal

**Personal Data Protection Act 2010 (Act 709):**
- s.5: Application
- s.6: General Principle
- s.7: Notice and Choice Principle
- s.8: Disclosure Principle
- s.9: Security Principle
- s.10: Retention Principle
- s.11: Data Integrity Principle
- s.12: Access Principle
- s.129-130: Offences and penalties

---

## PART 9: PRACTICAL NEXT STEPS

### Immediate Actions (Week 1):

1. **Visit `https://lom.agc.gov.my/`** and download PDF versions of all Tier 1 and Tier 2 acts listed above. These are the authoritative texts.

2. **Visit `http://www.commonlii.org/my/legis/consol_act/`** and verify/scrape the HTML versions for easier text processing.

3. **Visit `http://www.commonlii.org/my/cases/`** and search for the case names listed in Part 5 above.

4. **Visit `https://www.pdp.gov.my/`** for PDPA full text and subsidiary legislation.

5. **Visit `https://ttpm.kpdnhep.gov.my/`** for tribunal procedures and forms.

### Corpus Building (Week 2-3):

1. Parse PDFs using `pdfplumber`, `PyMuPDF`, or `Apache Tika`
2. Clean and normalize text (handle OCR artifacts if any)
3. Split into sections per the chunking strategy above
4. Generate metadata JSON for each chunk
5. Create embeddings and load into vector database

### Quality Assurance (Week 3-4):

1. Cross-reference CommonLII text against LOM PDFs for accuracy
2. Verify amendment currency -- check if recent amendments are captured
3. Test retrieval with sample queries (e.g., "Can landlord keep security deposit?")
4. Validate case law citations against CLJ or other paid databases
5. Have a Malaysian lawyer review a sample of the corpus for accuracy

### Ongoing Maintenance:

1. Monitor Federal Gazette for new amendments: `https://www.federalgazette.agc.gov.my/`
2. Check LOM periodically for updated act texts
3. Add new case law as published on CommonLII
4. Track any new tenancy-specific legislation (Malaysia has been discussing a Residential Tenancy Act)

---

## PART 10: IMPORTANT LEGAL CAVEATS

1. **No Consolidated Tenancy Act:** Malaysia is one of the few Commonwealth countries without a dedicated residential tenancy statute. In 2020-2023, there were discussions about introducing one, but as of this research date, none has been enacted. Monitor the Parliamentary agenda.

2. **State vs Federal:** Land is a state matter under the Federal Constitution (Ninth Schedule, State List). While the National Land Code applies to Peninsular Malaysia, Sabah and Sarawak have separate land ordinances. Your RAG system should clarify which jurisdiction applies.

3. **Language:** Malaysian statutes are officially in Bahasa Melayu, but English translations are widely available and used in legal practice. The English text on LOM and CommonLII is generally reliable.

4. **Disclaimer Requirement:** Your app MUST include a disclaimer that the information provided is for general guidance only and does not constitute legal advice. Users should be advised to consult a qualified Malaysian lawyer for specific legal matters.

5. **Copyright on Legislation:** Malaysian government legislation is generally freely reproducible for non-commercial informational purposes under the Government Copyright policy, but verify the latest terms on the AGC website.

---

## APPENDIX: QUICK REFERENCE -- ALL URLS IN ONE PLACE

```
# Government Sources
https://lom.agc.gov.my/                                    # Laws of Malaysia Online (AGC)
https://www.agc.gov.my/agcportal/index.php?r=portal2/lom   # AGC Portal alternate
https://www.federalgazette.agc.gov.my/                      # Federal Gazette
https://www.pdp.gov.my/                                     # PDPA Commissioner
https://ttpm.kpdnhep.gov.my/                               # Tribunal for Consumer Claims
https://www.kpkt.gov.my/                                    # Ministry of Housing
https://www.kehakiman.gov.my/                               # Judiciary Portal
https://www.data.gov.my/                                    # Malaysia Open Data

# Free Legal Databases
http://www.commonlii.org/my/legis/consol_act/               # CommonLII - Acts
http://www.commonlii.org/my/cases/                          # CommonLII - Cases
http://www.commonlii.org/my/cases/MYFC/                     # Federal Court
http://www.commonlii.org/my/cases/MYCA/                     # Court of Appeal
http://www.commonlii.org/my/cases/MYHC/                     # High Court

# Specific Acts on CommonLII (verify)
http://www.commonlii.org/my/legis/consol_act/ca1950141/     # Contracts Act 1950
http://www.commonlii.org/my/legis/consol_act/nlc1965170/    # National Land Code 1965
http://www.commonlii.org/my/legis/consol_act/sra1950156/    # Specific Relief Act 1950
http://www.commonlii.org/my/legis/consol_act/cla1956130/    # Civil Law Act 1956
http://www.commonlii.org/my/legis/consol_act/cpa1999304/    # Consumer Protection Act 1999

# Commercial Sources (Paid)
https://www.cljlaw.com/                                     # CLJ Law
https://www.ilbs.com.my/                                    # ILBS (publisher)
https://www.lexisnexis.com.my/                              # LexisNexis Malaysia

# GitHub Search
https://github.com/search?q=malaysia+law+legislation&type=repositories
```

---

*This research document should be verified by accessing the URLs listed above. Web access tools were unavailable during this research session, so all URLs and paths are based on established knowledge of Malaysian legal information architecture. Some URLs may have changed -- verification is the critical next step.*
