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

\setlength{\itemsep}{2ex}
\setlength{\parskip}{1ex}
\setlength{\blanklineskip}{1.5ex}
\setlength\mathindent{4ex}

\begin{document}

% \large

\frame{\titlepage}
\institute{Target}

\framet{Arrays}{
\begin{itemize}\itemsep5ex
\item
  Dominant data type for parallel programming (even functional).
\item
  Unsafe (indexing is partial).
\item
  Obfuscate parallel algorithms (array encodings).
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

Plan:

\begin{itemize}
\item Define algorithm for each.
\item Use directly, \emph{or}
\item \hspace{2ex}automatically via (derived) encodings.
\item Data types give rise to (correct) algorithms.
\end{itemize}
}

\partframe{Some data types}

\framet{Vectors}{

\begin{center}
\Large $n = \overbrace{I \btimes \cdots \btimes I\:}^{n \text{~times}}$
\end{center}
% \vspace{0ex}

\pause%\vspace{2ex}

Left-associated:
\begin{code}
type family (LVec n) where
  LVec Z      = U1
  LVec (S n)  = LVec n :*: Par1
\end{code}

Right-associated:
\begin{code}
type family (RVec n) where
  RVec Z      = U1
  RVec (S n)  = Par1 :*: RVec n
\end{code}

%if False
\pause%\vspace{2ex}

Also convenient:
\begin{code}
type Pair = Par1 :*: Par1   -- or |RVec N2| or |LVec N2|
\end{code}
%endif

}

\framet{Perfect trees}{
\begin{center}
\Large $h^n = \overbrace{h \bcomp \cdots \bcomp h\:}^{n \text{~times}}$
\end{center}

%% \vspace{0ex}

Left-associated/bottom-up:
\begin{code}
type family (LPow h n) where
  LPow h Z      = Par1
  LPow h (S n)  = LPow h n :.: h
\end{code}

Right-associated/top-down:
\begin{code}
type family (RPow h n) where
  RPow h Z      = Par1
  RPow h (S n)  = h :.: RPow h n
\end{code}

% \vspace{6ex}

}

%if False
\framet{Bushes}{
\vspace{5ex}
\begin{code}
type family (Bush n) where
  Bush Z      = Pair
  Bush (S n)  = Bush n :.: Bush n
\end{code}
\vspace{3ex}
%\pause

% Notes:
\begin{itemize}\itemsep2ex
\item
Composition-balanced counterpart to
|LPow Pair (pow 2 n)| and |RPow Pair (pow 2 n)|.
% |LPow h n| and |RPow h n|.
% \item Variation of |Bush| type in \href{http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.184.8120}{\emph{Nested Datatypes}} by Bird \& Meertens.
\item
Size $2^{2^n}$, i.e., $2, 4, 16, 256, 65536, \ldots$.
\item
Easily generalizes beyond pairing and squaring.
\end{itemize}
}
%endif

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
%\pause
Linear \emph{dependency chain} thwarts parallelism\out{ (depth $<$ work)}.
}

\framet{Scan interface}{\mathindent12ex
\vspace{5ex}
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
%\pause
\begin{code}
instance (LScan f, LScan g) => LScan (f :+: g) where
  lscan (L1  fa  ) = first L1  (lscan fa  )
  lscan (R1  ga  ) = first R1  (lscan ga  )
\end{code}
}

%format Vec = LVec

%% $a^{16} = a^5 \times a^{11}$
\framet{Product example: |LVec N5 :*: LVec N11|}{
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

%% \circuit{|LVec N8| (unoptimized)}{0}{lsums-lv8-no-hash-no-opt}{16}{8}
\circuit{|LVec N8|}{0}{lsums-lv8}{7}{7}
%% \circuit{|LVec N16|}{0}{lsums-lv16}{15}{15}
%% \circuit{|LVec N8 :*: LVec N8|}{0}{lsums-p-lv8}{22}{8}
%% \circuit{|RVec N8| (unoptimized)}{-1}{lsums-rv8-no-hash-no-opt}{36}{8}
\circuit{|RVec N8|}{-1}{lsums-rv8}{28}{7}


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
\ccircuit{|(LVec N4 :*: LVec N4) :*: LVec N4|}{0}{lsums-lv3olv4}
\ccircuit{|LVec N3 :.: LVec N4|}{0}{lsums-lv3olv4}
\ccircuit{|LVec N3 :.: LVec N4|}{0}{lsums-lv3olv4-highlight}

%% \ccircuit{|LVec N5 :.: LVec N7|}{-1.5}{lsums-lv5olv7}
%% \ccircuit{|LVec N5 :.: LVec N7|}{-1.5}{lsums-lv5olv7-highlight}

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

\circuit{|Pow (LVec N4) N2|}{0}{lsums-lpow-4-2}{24}{6}

\circuit{|RPow Pair 4|}{-1}{lsums-rb4}{32}{4}
\circuit{|LPow Pair 4|}{-1}{lsums-lb4}{26}{6}

%% \circuit{$2^4 = (2^2)^2 = (2 \times 2) \times (2 \times 2)$}{-1}{lsums-bush2}{29}{5}


\partframe{FFT}

\framet{Discrete Fourier Transform (DFT)}{
\vspace{0.5in}

{\Large
$$
X_k =  \sum\limits_{n=0}^{N-1} x_n e^{\frac{-i2\pi kn}{N}}
{ \qquad k = 0,\ldots,N-1}
$$
}

%\vspace{0.75in}
~

Direct implementation does $O(N^2)$ work.\\[4ex]
FFT computes DFT in $O(N \log N)$ work.

}

\TPGrid{364}{273} %% roughly page size in points

%% \setlength{\fboxsep}{0pt}

\newcommand{\upperDFT}{
%if False
\begin{textblock}{100}[1,0](348,13)
{\colorbox{shadecolor}{{\large $X_k = \sum\limits_{n=0}^{N-1} x_n e^{\frac{-i2\pi kn}{N}}$}}}
\end{textblock}
%else
\begin{textblock}{120}[1,0](348,9)
\begin{tcolorbox}
\large $X_k = \sum\limits_{n=0}^{N-1} x_n e^{\frac{-i2\pi kn}{N}}$
\end{tcolorbox}
\end{textblock}
%endif
}


%if False
\framet{DFT in Haskell}{\upperDFT 

\pause

> dft :: forall f a. ... => Unop (f (Complex a))
> dft xs = omegas (size @f) $@ xs
> 
> omegas :: ... => Int -> g (f (Complex a))
> omegas n = powers <$> powers (exp (- i * 2 * pi / fromIntegral n))

\pause
\vspace{-2ex}
\hrule

%% Utility:

> powers :: ... => a -> f a
> powers = fst . lscanAla Product . pure
>
> ($@) :: ... => n (m a) -> m a -> n a   -- matrix $\times$ vector
> mat $@ vec = (NOP <.> vec) <$> mat
>
> (<.>) :: ... => f a -> f a -> a        -- dot product
> u <.> v = sum (liftA2 (*) u v)

%% No arrays!

}

%endif

\framet{Factoring DFT --- pictures}{

\wfig{3.25in}{cooley-tukey-general}
%if False
\begin{center}
\vspace{-5ex}
\sourced{https://en.wikipedia.org/wiki/Cooley\%E2\%80\%93Tukey_FFT_algorithm\#General_factorizations}
\end{center}
%else
\begin{flushright}
\vspace{-5ex}
{\tiny \href{https://en.wikipedia.org/wiki/Cooley\%E2\%80\%93Tukey_FFT_algorithm\#General_factorizations}{Johnson [2010]}\hspace{10ex}\ }
\end{flushright}
%endif

\vspace{-2ex}
\pause
How might we express generically?
}

\setlength{\fboxsep}{1.5pt}

%% \definecolor{white}{rgb}{1,1,1}

\newcommand{\upperCT}{
%if True
\begin{textblock}{193}[1,0](353,7)
\begin{tcolorbox}
\wpicture{1.9in}{cooley-tukey-general}
\end{tcolorbox}
\end{textblock}
%else
\begin{textblock}{149}[1,0](353,12)
\colorbox{white}{\fbox{\wpicture{2in}{cooley-tukey-general}}}
\end{textblock}
%endif
}

\framet{Factoring DFT\out{ --- Haskell}}{\upperCT

\pause

\vspace{4ex}
Factor types, not numbers!

\vspace{4ex}

%% \vspace{1ex}

> newtype (g :.: f) a = Comp1 (g (f a))

\pause
\vspace{-4ex}

> instance (Sized g, Sized f) => Sized (g :.: f) where
>   size = size @g * size @f

%if False

\vspace{-4ex}

\pause
Also closed under composition:
% |Functor|, |Applicative|, |Foldable|, |Traversable|.

\vspace{-1.5ex}
\begin{itemize}
\item |Functor|
\item |Applicative|
\item |Foldable|
\item |Traversable|
\end{itemize}

%% \vspace{1ex}
%% Exercise: work out the instances.

%endif

}

\framet{Factoring DFT\out{ --- Haskell}}{\upperCT
\mathindent2ex
\vspace{6ex}

> class FFT f where
>   type FFO f :: * -> *
>   fft :: f C -> FFO f C

%\pause
\vspace{-2ex}

> instance NOP ... => FFT (g :.: f) where
>   type FFO (g :.: f) = FFO f :.: FFO g
>   fft = Comp1 . ffts' . transpose . twiddle . ffts' . unComp1

> ffts' :: ... => g (f C) -> FFO g (f C)
> ffts' = transpose . fmap fft . transpose

}

%% >
%% > twiddle :: ... => g (f C) -> g (f C)
%% > twiddle = (liftA2.liftA2) (*) (omegas (size @(g :.: f)))


%if False
\framet{Typing}{

> ffts' :: ... => g (f C) -> FFO g (f C)
> ffts' = transpose . fmap fft . transpose
>
> transpose  :: g (f C)      -> f (g C)
> fmap fft   :: f (g C)      -> f (FFO g C)
> transpose  :: f (FFO g C)  -> FFO g (f C)

> instance NOP ... => FFT (g :.: f) where
>   type FFO (g :.: f) = FFO f :.: FFO g
>   fft = Comp1 . ffts' . transpose . twiddle . ffts' . unComp1
>
> ffts'      :: g (f C)      -> FFO g (f C)
> twiddle    :: FFO g (f C)  -> FFO g (f C)
> transpose  :: FFO g (f C)  -> f (FFO g C)
> ffts'      :: f (FFO g C)  -> FFO f (FFO g C)

}
%endif

%if False
\framet{Optimizing |fft| for |g :.: f|}{

>     ffts' . transpose . twiddle . ffts'
> ==     
>        transpose . fmap fft . transpose
>     .  transpose
>     .  twiddle
>     .  transpose . fmap fft . transpose
> ==  
>     transpose . fmap fft . twiddle . transpose . fmap fft . transpose
> ==  
>     traverse fft . twiddle . traverse fft . transpose

}

\framet{Binary FFT}{

Uniform pairs:

> data Pair a = a :# a deriving (Functor,Foldable,Traversable)

> instance Sized Pair where size = 2
>
> instance FFT Pair where
>   type FFO Pair = Pair
>   fft = dft

Equivalently,

> SPACE fft (a :# b) = (a + b) :# (a - b)

}
%endif

%if False
\framet{|fft @(RPow Pair N0)|}{\vspace{ 2.0ex}\wfig{4.0in}{circuits/fft-rb0}}
\framet{|fft @(LPow Pair N0)|}{\vspace{ 2.0ex}\wfig{4.0in}{circuits/fft-lb0}}
\framet{|fft @(RPow Pair N1)|}{\vspace{-0.0ex}\wfig{4.4in}{circuits/fft-rb1}}
\framet{|fft @(LPow Pair N1)|}{\vspace{-0.0ex}\wfig{4.4in}{circuits/fft-lb1}}
\framet{|fft @(RPow Pair N2)|}{\vspace{-0.5ex}\wfig{4.2in}{circuits/fft-rb2}}
\framet{|fft @(LPow Pair N2)|}{\vspace{-0.5ex}\wfig{4.2in}{circuits/fft-lb2}}
\framet{|fft @(RPow Pair N3)|}{\vspace{-0.5ex}\wfig{4.6in}{circuits/fft-rb3}}
\framet{|fft @(LPow Pair N3)|}{\vspace{-0.5ex}\wfig{4.6in}{circuits/fft-lb3}}
%endif
\framet{|fft @(RPow Pair N4)|}{\vspace{-2.0ex}\wfig{4.6in}{circuits/fft-rb4}}
\framet{|fft @(LPow Pair N4)|}{\vspace{-1.0ex}\wfig{4.6in}{circuits/fft-lb4}}
%if False
\framet{|fft @(RPow Pair N5)|}{\vspace{-4.0ex}\wfig{4.8in}{circuits/fft-rb5}}
\framet{|fft @(LPow Pair N5)|}{\vspace{ 0.0ex}\wfig{4.8in}{circuits/fft-lb5}}
\framet{|fft @(RPow Pair N6)|}{\vspace{-2.0ex}\wfig{4.6in}{circuits/fft-rb6}}
\framet{|fft @(LPow Pair N6)|}{\vspace{-3.0ex}\wfig{4.8in}{circuits/fft-lb6}}
%endif

\framet{More goodies in the paper}{
\begin{itemize}\itemsep3ex
\item Scan and FFT on |Bush n|.
\item Log time polynomial evaluation via scan.
\item Complexity, generically.
\item Additional examples.
\item Details.
\end{itemize}
}

\framet{Conclusions}{
\rnc{\baselinestretch}{2.0}
\begin{itemize}
\item Alternative to array programming:
  \begin{itemize}
  \item Elegantly compositional.
  \item Uncluttered by index computations.
  \item Safe from out-of-bounds errors.
  \item Reveals algorithm essence and connections.
  \end{itemize}
\item Four well-known parallel algorithms: |RPow h n|, |LPow h n|. % perfect trees
\item Two possibly new and useful algorithms: |Bush n|. % bushes
\end{itemize}
}

\end{document}
