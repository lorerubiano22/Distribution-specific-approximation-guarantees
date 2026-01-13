
# Random Parameters (RP) –  Instances (GDX + TXT)

This repository contains **only input data** for the **Random Parameters (RP)** model family used in the computational study.  

Each instance is provided in two equivalent formats:
Link: https://rwth-aachen.sciebo.de/s/C6dMXZwxZCNYQwD

- **`.gdx`**: canonical machine-readable input file (intended to be read by a GAMS-based implementation of the RP model).
---

## 1) File naming convention (the filename is the metadata)

Each RP instance follows the pattern:

`input_RP_I_<n>_corr_0_revscheme_<r>_seed_<s>.gdx`

and the corresponding text export:

`input_RP_I_<n>_corr_0_revscheme_<r>_seed_<s>.txt`

### Meaning of tokens

- **`input_RP`**  
Instance belongs to the **Random Parameters / Random Taste Heterogeneity** specification.

- **`I_<n>`**  
Number of products in the instance (cardinality of set `i`).  
Note: in the study design, the **opt-out alternative is treated as the last “product” index** (for convenience in indexing).

- **`corr_0`**  
Correlation identifier. For RP instances this is **always `0`** because **correlation structures do not apply** in the Random Parameters setting. (Correlation is handled in a separate instance family, e.g., Error Components.)

- **`revscheme_<r>`**  
Revenue scheme identifier. It specifies which revenue construction rule/scenario is used for the instance.

- **`seed_<s>`**  
Fixed random seed used by the instance generator. This ensures the utility samples (and any other stochastic draws) are exactly reproducible.

### Example

`input_RP_I_10_corr_0_revscheme_2_seed_136.gdx`

means: Random Parameters instance with 10 products, revenue scheme 2, seed 136 (with correlation token fixed to 0).

---

## 2) What is inside each `.gdx` file

Each `input_RP_*.gdx` stores the sets and parameters needed to evaluate the RP model objective under Monte Carlo sampling.

### Sets (typical)

- **`i`**: products (including the opt-out alternative as the last index)
- **`g`**: realizations / Monte Carlo samples (e.g., `g1* g500`)

Depending on the generator/export configuration, an additional index may appear (e.g., a variance level dimension) when multiple variance regimes are packaged into one file.

### Parameters

The RP instances are designed to represent **random taste heterogeneity**. Concretely, the generator produces **sampled utility components** per product and realization, and stores them in the GDX (often directly as utility samples, or as components from which total utility is reconstructed).

Common parameter content includes:

- **sampled utilities or utility components** indexed by `(i, g)` (and optionally by a variance level index),
- **instance-level scalars** controlling the variance/scale of the samples (if not embedded directly in the samples),
- **revenue information** consistent with the selected `revscheme_<r>` (if the downstream implementation reads revenue from the input; otherwise the revenue scheme is applied internally by the model using the scheme ID).

The accompanying `.txt` file prints exactly these symbols and values.

---

## 3) How RP instances are generated and used

### Generation logic (conceptual)
For a given configuration `(I_<n>, revscheme_<r>, seed_<s>)`, the instance generator:

1. Creates the product index set `i` (including opt-out as the last index).
2. Creates the realization set `g` (Monte Carlo samples).
3. Generates **random-parameter utility samples** for each `(i, g)` according to the RP design described in the paper:
- utilities are sampled with a controlled dispersion/variance,
- expectations in the objective are approximated by averaging over `g`.
4. Assigns revenues according to the selected revenue scheme `revscheme_<r>` (either stored explicitly as parameters or applied internally by the downstream code, depending on implementation).

### Use in the RP model (conceptual mapping)
The RP model evaluates expected performance measures (e.g., expected revenue) by computing choice outcomes under each realization `g` and aggregating across `g`.

A typical conceptual structure is:

- construct/obtain per-realization utilities `U(i,g)` from stored inputs,
- compute choice probabilities (or deterministic choice under each draw, depending on the formulation),
- aggregate across realizations to approximate expectations.

---

## 4) Quantities that may be derived in the model but not stored in the `.gdx`

To keep instance files compact and implementation-agnostic, some quantities used by a downstream model may be computed on the fly and therefore are not necessarily stored explicitly. Examples include:

- **exponentiated utilities** (e.g., `exp(U(i,g))`) used by logit-style probability calculations,
- **normalization constants** (e.g., denominators per realization),
- **opt-out baseline terms** if the opt-out utility is fixed by convention rather than sampled,
- **revenue ordering or dominance filters** if these are applied by the solver code rather than stored.

All such quantities are deterministically reconstructible from the stored inputs plus the modeling conventions stated in the paper.
---

## Provenance / citation

These instances correspond to the Random Parameters (RP) experimental setting described in the companion paper.  
When reporting results, always reference the exact instance filename used (including `I`, `revscheme`, and `seed`).

