# Research References

Literature survey for the AutoQuantum project. Organized by theme.

---

## Lean 4 Quantum Formalization (Primary)

### LeanQuantum
- **Type:** GitHub library (active)
- **URL:** https://github.com/inQWIRE/LeanQuantum
- **Summary:** Lean 4 quantum computing library built on Mathlib. Formalizes quantum gates, Hilbert spaces, unitary operators. Proves gate identities (H²=I, Pauli² = I), Hermiticity of Pauli gates. Uses `Matrix.unitaryGroup n ℂ` for unitary constraints.
- **Relevance:** Most direct reference for our gate formalization approach. Check before duplicating gate proofs.

### Lean-QuantumInfo
- **Type:** GitHub library (active)
- **URL:** https://github.com/Timeroot/Lean-QuantumInfo
- **Summary:** Quantum information theory in Lean 4. Tensor products of Hilbert spaces, unitary operators, Hermitian matrices as first-class types. Main goal: sorry-free proof of the Generalized Quantum Stein's Lemma. Also covers quantum protocols (teleportation, key distribution, blind QC).
- **Relevance:** Good reference for the Lean 4 / Mathlib interface for quantum information.

### Formalization of Generalized Quantum Stein's Lemma (2025)
- **Authors:** Alex Meiburg, Leonardo A. Lessa, Rodolfo R. Soldati
- **URL:** https://arxiv.org/abs/2510.08672
- **Summary:** Computer-verified proof of a major quantum information theorem in Lean 4. Created 2,050 Lean declarations spanning topology, analysis, and operator algebra.
- **Relevance:** Demonstrates Lean is capable of sophisticated quantum physics results; useful guide to available Mathlib infrastructure.

### Formalizing CHSH Rigidity in Lean 4 (2026)
- **Authors:** Tianrun Zhao, Nengkun Yu
- **URL:** https://arxiv.org/abs/2604.03884
- **Summary:** Lean 4 formalization of the CHSH rigidity theorem. Formal verification caught gaps in prior pen-and-paper reasoning.
- **Relevance:** Case study showing formal verification adds value over informal proofs in quantum settings.

---

## LLM + Quantum Formalization

### MerLean: Agentic Autoformalization for Quantum Computation (2026)
- **Authors:** Yuanjie Ren, Jinzheng Li, Yidi Qi
- **URL:** https://arxiv.org/abs/2602.16554
- **Summary:** End-to-end pipeline: extract math statements from LaTeX → LLM formalizes in Lean 4 on Mathlib → translate back to human-readable LaTeX. Tested on three quantum computing papers with successful end-to-end formalization.
- **Relevance:** Closest prior work to AutoQuantum's approach. Study their feedback loop design carefully.

### QUASAR: Quantum Assembly Code Generation via Agentic RL (2025)
- **Authors:** Cong Yu, Valter Uotila, Shilong Deng, et al.
- **URL:** https://arxiv.org/abs/2510.00967
- **Summary:** Agentic RL with external quantum simulator verification. 99.31% Pass@1 validity on 4B LLM, outperforms GPT-4o/GPT-5/DeepSeek-V3.
- **Relevance:** Shows LLM + verifier feedback loop works well for quantum circuits; our system targets formal proof rather than simulation.

### Agent-Q: Fine-Tuning LLMs for Quantum Circuit Generation (2025)
- **Authors:** Linus Jern, Valter Uotila, Cong Yu, Bo Zhao
- **URL:** https://arxiv.org/abs/2504.11109
- **Summary:** Fine-tunes LLMs on 14,000 quantum circuits (QAOA, VQE, adaptive VQE) for OpenQASM 3.0 generation. Better parameter initialization than baseline LLMs.
- **Relevance:** Fine-tuning approach complementary to our verification approach; could provide a strong generator to pair with the Lean checker.

---

## Coq Quantum Formalization (Translatable Patterns)

### QWIRE: Formal Verification of Quantum Circuits in Coq (2018)
- **Authors:** Robert Rand, Jennifer Paykin, Steve Zdancewic
- **URL:** https://arxiv.org/abs/1803.00699
- **GitHub:** https://github.com/inQWIRE/QWIRE
- **Summary:** Embeds QWIRE quantum circuit language in Coq with HOAS, linear wire types, and denotational semantics as superoperators on density matrices. The inQWIRE group later built LeanQuantum on the same ideas.
- **Relevance:** Foundational patterns for circuit semantics.

### CoqQ: Foundational Verification of Quantum Programs (2022)
- **Authors:** Li Zhou, Gilles Barthe, Pierre-Yves Strub, Junyi Liu, Mingsheng Ying
- **URL:** https://arxiv.org/abs/2207.11350
- **Summary:** Deeply embedded quantum programming language in Coq with expressive program logic. Finite-dimensional Hilbert spaces via linear maps. Soundness verified relative to denotational semantics.
- **Relevance:** Reference for how to reason about quantum program correctness at the program logic level.

---

## QFT Verification

### Rotational Abstractions for QFT Circuit Verification (2023)
- **Authors:** Arun Govindankutty, Sudarshan K. Srinivasan, Nimish Mathure
- **URL:** https://arxiv.org/abs/2301.00737
- **Summary:** Reduces QFT verification from Hilbert space reasoning to quantifier-free bit-vector logic via rotational abstractions. Scales to 10,000 qubits and 50 million gates.
- **Relevance:** Directly relevant to our QFT correctness proof. The abstraction technique may reduce the Lean proof burden for large n.

---

## Additional Resources

- `lean-quantum` (duckki): https://github.com/duckki/lean-quantum — early Lean formalization of quantum computing
- Mathlib `Analysis.InnerProductSpace` — inner product spaces, unitary operators
- Mathlib `LinearAlgebra.Matrix.Hermitian` — Hermitian matrices
- Mathlib `LinearAlgebra.UnitaryGroup` — unitary group
- Mathlib `RingTheory.RootsOfUnity` — roots of unity, geometric sum identities
- Note: `Mathlib.LinearAlgebra.Matrix.DFT` does not appear to exist in v4.29.0; DFT-related results are proven from scratch or via roots-of-unity machinery.
