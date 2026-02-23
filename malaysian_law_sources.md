# Malaysian Law Sources for Juris RAG Corpus

## Direct PDF Downloads (Official Government Sources)

### 1. Contracts Act 1950 (Act 136) - PRIMARY
- **URL:** https://lom.agc.gov.my/ilims/upload/portal/akta/LOM/EN/Act%20136.pdf
- **Source:** Attorney General's Chambers (Official)
- **Relevance:** Governs all contract formation, void agreements, unfair terms

### 2. Consumer Protection Act 1999 (Act 599) - PRIMARY
- **URL:** https://lom.agc.gov.my/ilims/upload/portal/akta/outputaktap/1690994_BI/011121_Act%20599_final.pdf
- **Source:** Attorney General's Chambers (Official)
- **Relevance:** Unfair contract terms, consumer rights, tribunal procedures

### 3. National Land Code (Act 828 - Revised 2020) - PRIMARY
- **URL:** https://lom.agc.gov.my/ilims/upload/portal/akta/outputaktap/20201015_828_BI_WJW015175%20National%20Land%20Code%20Act%20828%20(Pewartaan).pdf
- **Source:** Attorney General's Chambers (Official)
- **Relevance:** Land ownership, tenancy provisions, landlord obligations

### 4. Specific Relief Act 1950 (Act 137)
- **URL:** https://faolex.fao.org/docs/pdf/mal197811.pdf
- **Alt:** https://www.commonlii.org/my/legis/consol_act/sra19501974207/
- **AGC Page:** https://lom.agc.gov.my/act-detail.php?lang=BI&act=137
- **Relevance:** Specific performance, injunctions, contract enforcement

### 5. Civil Law Act 1956 (Act 67)
- **URL:** https://tcclaw.com.my/wp-content/uploads/2020/12/Civil-Law-Act-1956.pdf
- **Alt:** https://lom.agc.gov.my/ilims/upload/portal/akta/LOM/EN/Act%2067.pdf
- **Relevance:** Section 28(4) - double rental for holding over, landlord remedies

### 6. Consumer Protection Act 1999 (with 2019 amendments)
- **URL:** https://aseanconsumer.org/file/pdf_file/CONSUMER%20PROTECTION%20ACT%201999%20AMENDMENT%202019%20.pdf
- **Relevance:** Updated unfair terms provisions

## Secondary Legal Resources

### 7. Academic Paper: "THE LAWS GOVERNING THE LANDLORD AND TENANT"
- **URL:** https://ir.uitm.edu.my/id/eprint/47092/1/47092.pdf
- **Relevance:** Comprehensive overview of all tenancy laws in Malaysia

### 8. Distress Act 1951
- **CommonLII:** Search at https://www.commonlii.org/my/legis/
- **Relevance:** Landlord's right to distrain tenant's goods for unpaid rent

## Key Legal Concepts for RAG

### Malaysia has NO single "Residential Tenancy Act"
Tenancy law is scattered across multiple acts:
- **Contracts Act 1950** - contract validity, void terms
- **Specific Relief Act 1950** - enforcement remedies
- **Distress Act 1951** - landlord distress actions
- **Civil Law Act 1956** - double rental, limitation periods
- **National Land Code** - land registration, tenancy registration
- **Consumer Protection Act 1999** - unfair contract terms

### Common Illegal Clauses in Malaysian Tenancy
1. Forfeiting deposit for "normal wear and tear" (violates CPA 1999)
2. Landlord entering without notice (no statutory provision, but implied covenant)
3. Automatic renewal without consent
4. Excessive penalty clauses (void under Contracts Act s.74)
5. Waiver of all landlord obligations
6. Unilateral rent increase without notice period

## Recommended RAG Chunking Strategy
1. Chunk by SECTION (each section of each Act = one document)
2. Include metadata: act_name, section_number, section_title, keywords
3. Priority ranking: Contracts Act > Consumer Protection > Specific Relief > Civil Law > NLC
4. Create synthetic "FAQ" documents for common tenant scenarios
