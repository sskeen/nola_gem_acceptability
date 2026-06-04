# src/

Source code for NOLA Gem acceptability, feasibility, and user experience analyses.

| File | Description |
|------|-------------|
| `coding_schema.yaml` | Deductive qualitative coding schema: _k_ = 7 codes (aliases `lgth`, `tmng`, `attn`, `gltc`, `prfc`, `ftrs`, `strs`) with definitions, worked examples of edge cases, and human-validated examples for LLM-assisted few-shot classification. |
| `qualitative.py` | Functions for LLM-based deductive coding: `load_coding_schema()` for .YAML parsing, `build_prompt_from_schema()` for prompt construction, `code_texts_deductively_ollama()` for local Ollama inference, and inter-rater reliability metrics (Cohen's kappa, % agreement). |
| `visualize.py` | Visualization functions. `plot_acceptability_scatter()` generates jittered scatter plots with mean ± SD overlays for Likert-scale acceptability data. |
| `nola_gem_acceptability.ipynb` | IPython notebook to orchestrate primary pre-registered and exploratory analyses: paradata aggregation & descriptives, acceptability viz., qualitative data transformation, LLM-human dual coding, and inter-rater reliability computation. |
| `nola_gem_acceptability.do` | Stata `.do` script to wrangle, clean, transform, and merge baseline and immediate post-assessment data contributed by NOLA Gem Aim III pilot participants, with pre-registered and exploratory analyses and usability viz. |
