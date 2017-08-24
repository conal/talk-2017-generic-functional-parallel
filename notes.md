# Notes for my ICFP talk on "Compiling to Categories"

## Outline

*   Arrays:
    *   Dominant data type for parallel programming (even functional).
    *   Unsafe (indexing is partial)
    *   Obfuscates parallel algorithms (array encodings).
*   Generic programming:
    *   Building blocks: functor sum, product, composition, and their identities.
    *   Automatically convert from and to conventional types.
    *   Data types give rise to (correct) algorithms.
*   Scan ("parallel prefix"):
    *   Linear left scan slide
    *   Scan class
    *   Easy instances
    *   Product / vectors (right & left)
    *   Composition / perfect trees (right & left).
        Two classic algorithms.
    *   Log time polynomial evaluation
*   FFT:
    *   DFT
    *   Summation trick
    *   Factoring DFT in pictures.
    *   Basic insight: factor types, not numbers.
        (Composite functors, not composite numbers.)
    *   Examples: DIT and DIF
*   Perfect bushes:
    *   The type family
    *   Examples and comparisons
*   Conclusions:
    *   In contrast to array algorithms (FFT slide 41)
    *   Four well-known parallel algorithms
    *   Two possibly new ones

## Misc notes

