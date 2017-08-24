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
\begin{itemize}\itemsep3ex
\item
  Dominant data type for parallel programming (even functional).
\item
  Unsafe (indexing is partial).
\item
  Obfuscates parallel algorithms (array encodings).
\end{itemize}
}

\framet{Generic building blocks}{
\vspace{2ex}
\begin{code}
data     V1           a                        -- void
newtype  U1           a = U1                   -- unit
newtype  Par1         a = Par1 a               -- singleton

data     (f  :+:  g)  a = L1 (f a) | R1 (g a)  -- sum
data     (f  :*:  g)  a = f a :*: g a          -- product
newtype  (g  :.:  f)  a = Comp1 (g (f a))      -- composition
\end{code}

\pause
\vspace{1ex}

Plan:

\begin{itemize}
\item Define algorithm for each.
\item Use directly, \emph{or}
\item \hspace{2ex}automatically via (derived) encodings.
\item Data types give rise to (correct) algorithms.
\end{itemize}
}

\framet{Some data types}{

}

\partframe{Scan}

\framet{Prefix sum (left scan)}{
\vspace{5ex}
Given $a_1,\ldots,a_n$, compute

\vspace{3ex}
$$ {\Large b_k = \sum\limits_{1 \le i < k}{a_i}}\qquad\text{for~} k=1,\ldots, n+1$$

%% \vspace{3ex}
%% efficiently in work and depth (ideal parallel time).

\vspace{5ex}

Note that $a_k$ does \emph{not} influence $b_k$.
}

\framet{Linear left scan}{
\vspace{-2ex}
\wfig{4.5in}{circuits/lsums-lv8}

\vspace{-1ex} \pause
\emph{Work:} $O(n)$

%% \pause
\emph{Depth}: $O(n)$ (ideal parallel ``time'')

\vspace{2ex}
\pause
Linear \emph{dependency chain} thwarts parallelism (depth $<$ work).
}

\framet{Scan class}{
%% \vspace{10ex}
\begin{code}
class Functor f => LScan f where
  lscan :: Monoid a => f a -> f a :* a
\end{code}

%if False
\pause\vspace{10ex}
Specification (if |Traversable f|):
\begin{code}
lscan == swap . mapAccumL (\ acc a -> (acc <> a,acc)) mempty
\end{code}
%% where
%% \begin{code}
%% mapAccumL  :: Traversable t
%%            => (b -> a -> b :* c) -> b -> t a -> b :* t c
%% \end{code}
%endif

}

\framet{Easy instances}{

\begin{code}
instance LScan V1    where lscan = \ SPC case

instance LScan U1    where lscan U1 = (U1, mempty)

instance LScan Par1  where lscan (Par1 a) = (Par1 mempty, a)
\end{code}
%if False
\vspace{-6ex}
\begin{center}
\ccap{|U1|}{1.2in}{lsums-u}
\ccap{|Par1|}{1in}{lsums-i}
\end{center}
\vspace{-3ex}
%endif
\pause
\begin{code}
instance (LScan f, LScan g) => LScan (f :+: g) where
  lscan (L1  fa  ) = first L1  (lscan fa  )
  lscan (R1  ga  ) = first R1  (lscan ga  )
\end{code}
}

%format Vec = LVec

%% $a^{16} = a^5 \times a^{11}$
\framet{Product example: |Vec N5 :*: Vec N11|}{
\vspace{-2ex}
\wfig{2.3in}{circuits/lsums-lv5}
\vspace{-5ex}
\wfig{4.5in}{circuits/lsums-lv11}

\emph{Then what?}
}

\ccircuit{Combine?}{0}{lsums-lv5-lv11-unknown-no-hash}
\ccircuit{Combine?}{0}{lsums-lv5-lv11-unknown-no-hash-highlight}
\ccircuit{Right adjustment}{0}{lsums-lv5xlv11-highlight}

\framet{Products}{
\begin{textblock}{200}[1,0](350,5)
\begin{tcolorbox}
\wfig{2.5in}{circuits/lsums-lv5xlv11-highlight}
\end{tcolorbox}
\end{textblock}
\pause\vspace{23ex}
\begin{code}
instance (LScan f, LScan g) => LScan (f :*: g) where
  lscan (fa :*: ga) = (fa' :*: ((fx <> NOP) <#> ga'), fx <> gx)
   where
     (fa'  , fx)  = lscan fa
     (ga'  , gx)  = lscan ga
\end{code}
}

\circuit{|RVec N8| (unoptimized)}{-1}{lsums-rv8-no-hash-no-opt}{36}{8}
\circuit{|RVec N8| (optimized)}{-1}{lsums-rv8}{28}{7}
\circuit{|LVec N8| (unoptimized)}{0}{lsums-lv8-no-hash-no-opt}{16}{8}
\circuit{|LVec N8| (optimized)}{0}{lsums-lv8}{7}{7}
\circuit{|LVec N16| (optimized)}{0}{lsums-lv16}{15}{15}
\circuit{|LVec N8 :*: LVec N8|}{0}{lsums-p-lv8}{22}{8}


\framet{Composition example: |LVec N3 :.: LVec N4|}{
\vspace{-3ex}
\wfig{2.5in}{circuits/lsums-lv4}
\vspace{-5ex}
\wfig{2.5in}{circuits/lsums-lv4}
\vspace{-5ex}
\wfig{2.5in}{circuits/lsums-lv4}
\vspace{-5ex}
\emph{Then what?}
}

\ccircuit{Combine?}{-1}{lsums-lv3olv4-unknown-no-hash}
\ccircuit{|LVec N3 :.: LVec N4|}{0}{lsums-lv3olv4}
\ccircuit{|LVec N3 :.: LVec N4|}{0}{lsums-lv3olv4-highlight}

\ccircuit{|LVec N5 :.: LVec N7|}{-1.5}{lsums-lv5olv7}
\ccircuit{|LVec N5 :.: LVec N7|}{-1.5}{lsums-lv5olv7-highlight}

\framet{Composition}{
\begin{textblock}{200}[1,0](350,5)
\begin{tcolorbox}
\wfig{2.5in}{circuits/lsums-lv3olv4-highlight}
\end{tcolorbox}
\end{textblock}
\pause\vspace{24ex}
\begin{code}
instance (LScan g, LScan f, Zip g) =>  LScan (g :.: f) where
  lscan (Comp1 gfa) = (Comp1 (zipWith adjustl tots' gfa'), tot)
   where
     (gfa', tots)  = unzip (lscan <#> gfa)
     (tots',tot)   = lscan tots
     adjustl t     = fmap (t <> NOP)
\end{code}
}

\circuit{|Pair :.: LVec N8|}{0}{lsums-p-lv8}{22}{8}
\circuit{|LVec N8 :.: Pair|}{0}{lsums-lv8-p}{22}{8}
\circuit{|LVec N4 :.: LVec N4|}{0}{lsums-lv4olv4}{24}{6}

\circuit{|RPow (LVec N4) N2|}{0}{lsums-lpow-4-2}{24}{6}

\circuit{|RPow Pair 4|}{-1}{lsums-rb4}{32}{4}
\circuit{|LPow Pair 4|}{-1}{lsums-lb4}{32}{4}

%% \circuit{$2^4 = (2^2)^2 = (2 \times 2) \times (2 \times 2)$}{-1}{lsums-bush2}{29}{5}


\partframe{FFT}

\framet{Perfect bushes}{
\begin{itemize}\itemsep3ex
\item
  The type family
\item
  Examples and comparisons
\end{itemize}
}

\framet{Conclusions}{
\begin{itemize}\itemsep3ex
\item
  In contrast to array algorithms (FFT slide 41)
\item
  Four well-known parallel algorithms
\item
  Two possibly new ones
\end{itemize}
}

\end{document}
