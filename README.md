# t1-readmes-nav-2026 COP

*description of the COP*

**COP timeframe** 2026-03-02 - 2026-06-08

## Overview

This repository was created via the **Design Assistant**.  
It contains the template files and in-scope pages needed to get started.

GitHub Pages: [https://cra-proto.github.io/t1-readmes-nav-2026](https://cra-proto.github.io/t1-readmes-nav-2026)

---
## Update procedures

Add information on how to manage your repo here.

---
## Design phase roadmap:

- [x] Initial content inventory and repo setup
- [ ] Prototype: co-design navigation and content
- [ ] SME review and accuracy check
- [ ] Validation usability testing (including accessibility review)
- [ ] Refine prototype (if required)
- [ ] Spot check usability (if required)

**Updated:**  2026-03-16

## Information Architecture
```mermaid
flowchart TD;
    node1(Canada.ca)
    node2(Canada Revenue Agency #40;CRA#41;)
    node3(Forms and publications - CRA)
    node4(All personal income tax packages)
    node5(Get a T1 income tax package)
    node6(Alberta - 2025 Income tax package)
    node7(Federal Income Tax and Benefit Information for 2025)
    node8(Manitoba - 2025 Income tax package)
    node9(Manitoba tax information for 2025)
    node10(ARCHIVED - Income tax package for 2018)
    node11(ARCHIVED - Alberta - 2018 Income Tax Package)
    node12(ARCHIVED - Manitoba - 2018 Income Tax Package)
    node13(ARCHIVED - Get a T1 income tax package for 2024)
    node14(ARCHIVED - Alberta - 2024 Income tax package)
    node15(5000-S2 Schedule 2 - Federal Amounts Transferred from your Spouse or Common-Law Partner #40;for all except QC and non-residents#41;)
    node16(5000-R Income Tax and Benefit Return #40;for PE, NS, NB, MB and SK only#41;)
    node17(5009-R Income Tax and Benefit Return #40;for AB#41; – T1 General – 2025)
    node1 --x node2
    node2 --> node3
    node3 --> node4
    node4 --> node5
    node5 --> node6
    node5 --x node7
    node5 --> node8
    node8 --> node9
    node4 --> node10
    node10 --> node11
    node10 --> node12
    node4 --> node13
    node13 --> node14
    node3 --x node15
    node3 --x node16
    node3 --> node17
    click node1 "https://www.canada.ca/en.html" _blank
    click node2 "https://www.canada.ca/en/revenue-agency.html" _blank
    click node3 "https://www.canada.ca/en/revenue-agency/services/forms-publications.html" _blank
    click node4 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years.html" _blank
    click node5 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package.html" _blank
    click node6 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/alberta.html" _blank
    click node7 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/5000-g.html" _blank
    click node8 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/manitoba.html" _blank
    click node9 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/manitoba/5007-pc.html" _blank
    click node10 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-2018.html" _blank
    click node11 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-2018/alberta.html" _blank
    click node12 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-2018/manitoba.html" _blank
    click node13 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-2024.html" _blank
    click node14 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-2024/alberta.html" _blank
    click node15 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/5000-s2.html" _blank
    click node16 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/5000-r.html" _blank
    click node17 "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/general-income-tax-benefit-package/alberta/5009-r.html" _blank
    classDef inscope stroke:#7636ab,stroke-width:3px
    class node4,node5,node6,node7,node9,node10,node11,node12,node13,node14,node15,node16,node17 inscope
    classDef ismoved fill:#eab308,color:#000
    class node15,node16,node17 ismoved
```
