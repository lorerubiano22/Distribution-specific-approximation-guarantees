# EC (Error Components) – Instances (GDX + TXT)

This repository contains **only input data instances** for the **Error Components (EC)** experimental setting described in the companion paper (EC correlation structures + σ-normalization regimes).

The instances are provided in two equivalent formats:

- **`.gdx`**: canonical machine-readable input for GAMS-based experiments

---

## 1. Naming convention (the filename is the metadata)

Each instance file follows:

`input_EC_I_<n>_corr_<c>_revscheme_<r>_seed_<s>_sigmaRel_<k>.gdx`

and the corresponding text export:

`input_EC_I_<n>_corr_<c>_revscheme_<r>_seed_<s>_sigmaRel_<k>.txt`

### Meaning of tokens

- **`EC`**  
  Error Components (EC) instance family (correlated unobserved utilities via component structure).

- **`I_<n>`**  
  Number of products (cardinality of set `i`).

- **`corr_<c>`**  
  Correlation / Error-Component-Structure (ECS) identifier.  
  It selects the *structural pattern* that determines how products share error components through `corr(i,ec)`.

- **`revscheme_<r>`**  
  Revenue scheme identifier.  
  It selects the revenue construction rule used in the experimental design (and any revenue-based ordering/assortment logic).

- **`seed_<s>`**  
  Fixed random seed used in the instance generator to produce stochastic samples (realizations `g`).

- **`sigmaRel_<k>`**  
  σ-normalization regime identifier (“Dev normalization” in the paper).  
  It selects which standard-deviation normalization rule is applied to the EC components (e.g., normalization variant 1 vs 2 as defined in the paper).

### Example

`input_EC_I_10_corr_1_revscheme_1_seed_105_sigmaRel_1.gdx`

= EC instance, 10 products, ECS type 1, revenue scheme 1, seed 105, σ-normalization regime 1.

**Important:** Do not rename files manually—renaming breaks traceability between experimental results and instance configuration.

---

## 2. What is inside each instance (GDX content)

Each `input_EC_*.gdx` stores a standardized set of symbols (sets + parameters).
The `.txt` export mirrors these symbols and values exactly.

### Sets

- `i`      : products
- `O`      : index for revenue-ordered assortment positions (ordering dimension used by the experiment design)
- `G`      : Monte Carlo realizations / samples
- `level`  : variance / scenario levels used in the generator
- `ec`     : error components

### Parameters

- `V_Sample(i,g,level)`  
  Sampled systematic utility component for product `i` under realization `g` and variance level `level`.

- `VV_Sample(g,level)`  
  Sampled realization-level term (e.g., a baseline / outside-option-related component or a normalization term), by `g` and `level`.

- `W_Sample(i,g,level)`  
  Additional sampled utility component by product and realization (e.g., random taste/noise component defined by the experiment generator).

- `sigma_sample(level)`  
  Standard deviation scalar by level. This reflects the σ scaling regime selected by `sigmaRel_<k>`.

- `eta(ec,g)`  
  Realizations of error components by `ec` and `g` (the stochastic driver of correlation across products).

- `corr(i,ec)`  
  Product-to-component loading / membership structure. This is the **core EC input** that induces correlation consistent with the chosen ECS (`corr_<c>`).

---

## 3. How instances are generated (conceptual recipe)

The paper’s EC setting creates **correlated unobserved utility** by combining:
1) a product-specific utility component, and  
2) one or more shared error components that couple products into correlated groups.

At a high level, each instance is generated as follows:

1. **Select configuration** from the filename tokens:  
   - number of products `I_<n>`  
   - ECS / correlation structure `corr_<c>`  
   - revenue scheme `revscheme_<r>`  
   - σ-normalization regime `sigmaRel_<k>`  
   - random seed `seed_<s>`

2. **Generate structural correlation inputs (ECS):**  
   The ECS determines which products share which component(s).  
   This is encoded in `corr(i,ec)` (and the set of components `ec`).

3. **Generate stochastic realizations:**  
   For each realization `g` (and each `level`), draw the error components `eta(ec,g)` under the fixed seed.  
   Apply the σ scaling regime (via `sigma_sample(level)` and the normalization rule indexed by `sigmaRel_<k>`).

4. **Assemble sampled utilities:**  
   The generator produces sampled utility pieces stored as:
   - `V_Sample(i,g,level)` (systematic/product-specific part),
   - `W_Sample(i,g,level)` (additional product-level stochastic part, if used),
   - `VV_Sample(g,level)` (realization-level / baseline term, if used).

These stored components are designed so that the downstream model can evaluate expected performance metrics (e.g., expected revenue) by Monte Carlo aggregation over `g`, and sensitivity analysis over `level`.

---

## 4. How the stored inputs are used in the EC model (conceptual mapping)

In the EC formulation, the latent utility of product `i` for a given realization typically takes the form:

**Utility decomposition (conceptual):**

`U(i,g,level) = V_Sample(i,g,level) + W_Sample(i,g,level) + Σ_{ec} corr(i,ec) * eta(ec,g) * sigma_sample(level) + (optional) VV_Sample(g,level)`

Notes:
- `corr(i,ec)` + `eta(ec,g)` are the *mechanism that induces correlation* across products.
- `sigma_sample(level)` governs the overall magnitude of the EC effect under each `level`.
- `VV_Sample(g,level)` is included if the experimental design uses a global (realization-level) term.

The optimization model (not stored here) uses these utility samples inside the choice/revenue evaluation (as defined in the paper), aggregating across `g` to approximate expectations.

---

## 5. Quantities that are part of the experimental design but not stored explicitly

Some quantities referenced in the paper and/or used internally by the generator may **not** be explicitly stored in the GDX because they are either:
- derivable from the stored symbols, or
- fully determined by the configuration tokens (revenue scheme, ECS type, σ-regime, seed).

Common examples include:

- **Raw σ parameters prior to normalization**  
  Only the post-normalization scaling needed by the model is stored (`sigma_sample(level)`), while intermediate σ values used to compute it may be omitted.

- **Full covariance/correlation matrix across products**  
  The EC approach represents correlation implicitly via `corr(i,ec)` and component draws `eta(ec,g)`, rather than storing an explicit product-by-product covariance matrix.

- **Revenue vector and/or revenue ordering construction details**  
  The token `revscheme_<r>` identifies the rule used to generate revenues and ordering.  
  The model can apply the scheme internally (or the generator can) without duplicating these details in each instance file.

- **Derived utility totals**  
  The final assembled `U(i,g,level)` is not stored as a separate parameter because it can be reconstructed from the components above.

This repository therefore stores the **minimal sufficient statistics** required to reproduce the EC experiment outcomes, while keeping instances compact and versionable.

---

## Contact / provenance

Instances were generated as part of the EC experimental design described in the companion paper.
For any result reporting, always cite the paper and reference the exact instance filename used.
