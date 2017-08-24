%% -*- latex -*-

% Presentation
%\documentclass[aspectratio=1610]{beamer} % Macbook Pro screen 16:10
%% \documentclass{beamer} % default aspect ratio 4:3
\documentclass[handout]{beamer}

% \setbeameroption{show notes} % un-comment to see the notes

\input{macros}

%include polycode.fmt
%include forall.fmt
%include greek.fmt
%include formatting.fmt

\title{Generic Functional Parallel Algorithms}
\subtitle{Scan and FFT}
\date{September 2017}

\setlength{\blanklineskip}{1.5ex}
\setlength\mathindent{4ex}

\begin{document}

% \large

\frame{\titlepage}
\institute{Target}


\framet{Arrays}{
\begin{itemize}
\tightlist
\item
  Dominant data type for parallel programming (even functional).
\item
  Unsafe (indexing is partial)
\item
  Obfuscates parallel algorithms (array encodings).
\end{itemize}
}

\framet{Generic programming}{
\begin{itemize}
\tightlist
\item
  Building blocks: functor sum, product, composition, and their identities.
\item
  Automatically convert from and to conventional types.
\item
  Data types give rise to (correct) algorithms.
\end{itemize}
}

\framet{Scan (parallel prefix)}{
\begin{itemize}
\tightlist
\item
  Linear left scan slide
\item
  Scan class
\item
  Easy instances
\item
  Product / vectors (right \& left)
\item
  Composition / perfect trees (right \& left). Two classic algorithms.
\item
  Log time polynomial evaluation
\end{itemize}
}

\framet{FFT}{
\begin{itemize}
\tightlist
\item
  DFT
\item
  Summation trick
\item
  Factoring DFT in pictures.
\item
  Basic insight: factor types, not numbers. (Composite functors, not composite numbers.)
\item
  Examples: DIT and DIF
\end{itemize}
}

\framet{Perfect bushes}{
\begin{itemize}
\tightlist
\item
  The type family
\item
  Examples and comparisons
\end{itemize}
}

\framet{Conclusions}{
\begin{itemize}
\tightlist
\item
  In contrast to array algorithms (FFT slide 41)
\item
  Four well-known parallel algorithms
\item
  Two possibly new ones
\end{itemize}
}

\end{document}
