# Notes for my ICFP talk on "Compiling to Categories"

## Misc notes

*   Perhaps start with my Lambda Jam 2017 keynote talk "Teaching new tricks to old programs" (TNT)

*   EDSLs
    *   Add vocabulary to a domain-independent host language.
    *   Simplest form is a "shallow" embedding:
        *   "Just a library", but with a suitable host language.
        *   In particular, use the host language abstraction & application, as well as booleans, numbers, etc.
        *   Great fit, and easy to implement; but restricts optimization.
        *   Also inherits host language *limitations*, e.g., precluding some useful operations on functions:
            *   Differentiation and integration
            *   Incremental evaluation
            *   Optimization
            *   Constraint solving
        *   Also precludes alternative implementations, e.g., GPU code, circuits, Javascript
*   Overloading
    *   Solves a related problem: alternative interpretation of common vocabulary.
    *   Laws for modular reasoning.
    *   Doesn't apply to most basic language "operations": lambda, variables, and application.

## Outline

*   Shallow and deep DSELs
    *   Deep DSELs: extended functions and alternative implementations.
        Requires vocabulary changes; unfortunate, since no change to denotation.
*   "Overloading lambda":
    *   Overloading allows familiar notation with novel interpretations.
    *   Laws for modular programming and reasoning.
    *   Doesn't apply to the most fundamental "operations" of the $\lambda$-calculus: lambda, variables, and application.
    *   We could program purely algebraically (no lambda), but awkward.
    *   Instead, have the compiler automatically translate to algebraic form.
*   Eliminating lambda
    *   TNT 13
    *   TNT 12 with different title
    *   Examples: TNT 14
*   Abstract algebra for functions
    *   TNT 15--19
*   Example interpretations
    *   
