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

\title{Compiling to categories}
\date{September 2017}

\setlength{\blanklineskip}{1.5ex}
\setlength\mathindent{4ex}

\begin{document}

% \large

\frame{\titlepage}
\institute{Target}

\framet{Embedded domain-specific languages}{

\emph{New vocabularies, not new languages}.

\vspace{6ex}

\begin{textblock}{180}[1,0](400,40)
\wpicture{1.5in}{peter-landin}
\end{textblock}

\wpicture{4.5in}{next-700-title}

\vspace{3ex}
% \pause
Can we create fewer new vocabularies as well?
}

\framet{Shallow embeddings}{
\begin{itemize} \itemsep2ex
\item
  ``Just a library'', but with a suitable host language.
\item
  Use host language lambda \& application, booleans, numbers, etc.
\item
  Great fit, and easy to implement; but restricts optimization.
\item
  Inherits host language \& compiler \emph{limitations}, e.g., no
  \begin{itemize} \itemsep2ex
  \item differentiation or integration
  \item incremental evaluation
  \item optimization
  \item constraint solving
  \item novel back-ends, e.g., GPU, circuits, JavaScript
  \end{itemize}
\end{itemize}
}

\framet{Deep embeddings}{
\begin{itemize}\itemsep2ex
\item Syntactic representation.
\item More room for analysis and optimization.
\item Harder to implement; redundant with host compiler.
\item Requires some vocabulary changes.
\end{itemize}

Violates a design principle:
\begin{center} \it
languages serve expression; compilers serve implementation.
\end{center}
}

\framet{Overloading}{
\begin{itemize} \itemsep3ex
\item Alternative interpretation of common vocabulary.
\item Laws for modular reasoning.
\item Doesn't apply to lambda, variables, and application.
\item Instead, \emph{eliminate} them.
\end{itemize}
}

\framet{Eliminating lambda}{

%format :=> = "\dashrightarrow"
%format := = "\coloneq"

{\setstretch{1.25}
\begin{code}
(\ p -> k)         :=>  const k

(\ p -> p)         :=>  id

(\ p -> u v)       :=>  apply . ((\ p -> u) &&& (\ p -> v))

(\ p -> \ q -> u)  :=>  curry (\ (p,q) -> u)
                   :=>  curry (\ r -> u[p := fst r, q := snd r])
\end{code}
}

\vspace{0ex}

Automate via a compiler plugin.

}

%if False
\framet{... where}{

\pause
\begin{code}

const :: b -> (a -> b)
const b = \ a -> b

id :: a -> a
id = \ a -> a

(.) :: (b -> c) -> (a -> b) -> (a -> c)
g . f = \ a -> g (f a)

(&&&) :: (a -> c) -> (a -> d) -> (a -> c :* d)
f &&& g = \ a -> (f a, g a)

curry :: (a :* b -> c) -> (a -> b -> c)
curry f = \ a -> \ b -> f (a,b)

apply :: (a -> b) :* a -> b
apply  = \ (f,a) -> f a

\end{code}

}
%endif

\framet{Examples}{

\begin{code}
sqr :: Num a => a -> a
sqr a = a * a

magSqr :: Num a => a :* a -> a
magSqr (a,b) = sqr a + sqr b

cosSinProd :: Floating a => a :* a -> a :* a
cosSinProd (x,y) = (cos z, sin z) where z = x * y
\end{code}

After |\ |-elimination:

\begin{code}
sqr = mulC . (id &&& id)

magSqr = addC . (mulC . (exl &&& exl) &&& mulC . (exr &&& exr))

cosSinProd = (cosC &&& sinC) . mulC
\end{code}

}

%format ProductCat = Cartesian
%format CoproductCat = Cocartesian
%format ClosedCat = Closed

\out{
\framet{Abstract algebra for functions}{
\begin{itemize}\itemsep2ex
\item
  |Category|
\item
  |Cartesian|
\item
  |Closed|
\end{itemize}
}
}

% \nc\bq{\texttt{`}}
\nc\bq{\mbox{\`{}}}

%format `k` = "\mathbin{\bq\! k\;\!\!\bq}\!"

\framet{Abstract algebra for functions}{

\pause
Interface:

> class Category k where
>   id   :: a `k` a
>   (.)  :: (b `k` c) -> (a `k` b) -> (a `k` c)
>   infixr 9 .
>   NOP
>   NOP

Laws:

> id . f       == f
> g . id       == g
> (h . g) . f  == h . (g . f)

}

\setlength{\fboxsep}{-1ex}

\nc\scrk[1]{_{\hspace{#1}\scriptscriptstyle{k\!}}}

%format Prod (k) a b = a "\times\scrk{-0.25ex}" b
%format Coprod (k) a b = a "+\scrk{-0.3ex}" b
%format Exp (k) a b = a "\Rightarrow\scrk{-0.2ex}" b

\framet{Products}{

Interface:

> class Category k => ProductCat k where
>   type Prod k a b
>   exl    ::  (Prod k a b) `k` a
>   exr    ::  (Prod k a b) `k` b
>   (&&&)  ::  (a `k` c)  -> (a `k` d)  -> (a `k` (Prod k c d))
>   infixr 3 &&&

Laws:

> exl  .  (f &&& g)      == f                
> exr  .  (f &&& g)      == g                
> exl  .  h &&& exr . h  == h                

}

{
\framet{Coproducts}{

Dual to product.

> class Category k => CoproductCat k where
>   type Coprod k a b
>   inl    ::  a `k` (Coprod k a b)
>   inr    ::  b `k` (Coprod k a b)
>   (|||)  ::  (a `k` c)  -> (b `k` c)  -> ((Coprod k a b) `k` c)
>   infixr 2 |||

Laws:

> (f ||| g) . inl      == f
> (f ||| g) . inr      == g
> h . inl ||| h . inr  == h

}
}

\framet{Exponentials}{
First-class ``functions'' (morphisms):
\begin{code}
class ProductCat k => ClosedCat k where
  type Exp k a b
  apply    :: (Prod k (Exp k a b) a) `k` b
  curry    :: ((Prod k a b) `k` c) -> (a `k` (Exp k b c))
  uncurry  :: (a `k` (Exp k b c)) -> ((Prod k a b) `k` c)
  NOP
\end{code}
Laws:

\begin{code}

uncurry (curry f)                == f
curry (uncurry g)                == g
apply . (curry f . exl &&& exr)  == f

\end{code}
}

\framet{Misc operations}{

\begin{code}
class NumCat k a where
  negateC          :: a `k` a
  addC, sub, mulC  :: (Prod k a a) `k` a
  ...

...
\end{code}
}

\framet{Changing interpretations}{
\begin{itemize}\itemsep3ex
\item
  We've eliminated lambdas and variables
\item
  and replaced them with an algebraic vocabulary.
\item
  What happens if we \emph{replace |(->)| with other instances?}\\
  (Via compiler plugin.)
\end{itemize}
}

\framet{Computation graphs --- example}{

> magSqr (a,b) = sqr a + sqr b

> magSqr = addC . (mulC . (exl &&& exl) &&& mulC . (exr &&& exr))

\begin{center}\wpicture{4.5in}{magSqr}\end{center}
}

\framet{Computation graphs --- example}{
\vspace{-1.5ex}

> cosSinProd (x,y) = (cos z, sin z) where z = x * y

> cosSinProd = (cosC &&& sinC) . mulC

\vspace{1ex}
\begin{center}\wpicture{4.6in}{cosSinProd}\end{center}
}

\framet{Computation graphs --- example}{
\vspace{1ex}

> \ x y -> x + 3 * y

> curry (addC . (exl &&& mulC . (const 3.0 &&& exr)))

\pause
\vspace{-2ex}
\begin{center}\wpicture{4.6in}{xp3y-curried}\end{center}
}

\framet{Computation graphs --- implementation sketch}{
%\small
\vspace{-0.5ex}
\begin{code}
newtype Graph a b = Graph (Ports a -> GraphM (Ports b))

type GraphM = State (PortNum,[Comp])

data Comp = forall a b. Comp (Template a b) (Ports a) (Ports b)

data Template :: * -> * -> * NOP where
  Prim      :: String -> Template a b
  Subgraph  :: Graph a b -> Template () (a -> b)

instance Category Graph where
  id = Graph return
  Graph g . Graph f = Graph (g <=< f)

instance BoolCat Graph where
  notC  = genComp  ldq not rdq
  andC  = genComp  ldq && rdq
  orC   = genComp  ldq || rdq
\end{code}

}

\framet{Computation graphs --- fold}{

> sum :: Tree N4 Int -> Int

\vspace{-4ex}
\begin{center}\wpicture{4.5in}{sum-t4}\end{center}

}

\framet{Computation graphs --- scan}{

> lsums :: Tree N4 Int -> Tree N4 Int :* Int

\vspace{-7ex}

\begin{center}\wpicture{4.25in}{lsums-rb4}\end{center}

}

\framet{Haskell to hardware}{

Convert graphs to Verilog:

\begin{textblock}{180}[1,0](350,95)
\begin{tcolorbox}

\small \mathindent1.8in
\vspace{-2.7ex}

> magSqr

\vspace{-7ex}

\wpicture{2.2in}{magSqr}
\end{tcolorbox}
\end{textblock}
\pause

\begin{verbatim}
   module magSqr (In_0, In_1, Out);
     input [31:0] In_0;
     input [31:0] In_1;
     output [31:0] Out;
     wire [31:0] Plus_I0;
     wire [31:0] Times_I3;
     wire [31:0] Times_I4;
     assign Plus_I0 = Times_I3 + Times_I4;
     assign Out = Plus_I0;
     assign Times_I3 = In_0 * In_0;
     assign Times_I4 = In_1 * In_1;
   endmodule
\end{verbatim}
}

\nc\lm[1]{\mathop{\multimap}_{#1}}
%format LM a b = a "\multimap" b

\out{
\framet{Linear maps}{(maybe omit)}
}

%% \nc\ad[1]{\mathop{\leadsto}_{#1}}
%% %format DF s a b = a "\ad{"s"}" b
%% %format DF' s = "\ad{"s"}"

\framet{Example --- graphics}{\mathindent2ex
\small
\vspace{0.75ex}

\begin{textblock}{150}[1,0](350,45)
\begin{tcolorbox} \mathindent0ex
\vspace{-1ex}
\begin{code}
type Region = R :* R -> Bool
\end{code}
\vspace{-3ex}
\end{tcolorbox}
\end{textblock}

%format / = "/"
\begin{code}
disk :: R -> Region
disk r p = magSqr p <= sqr r

wobbly t = disk (3/4 + 1/4 * cos t)
\end{code}

\pause
\vspace{-3.5ex}
\begin{center}\wpicture{4.1in}{wobbly-disk-color}\end{center} 
\pause
\vspace{-4.5ex}
%if False
\begin{verbatim}
 bool wobbly (float in0, float in1, float in2)  // Generated GLSL
 { float v17 = 1.0;
   float v23 = v17 / (0.75 + 0.25 * cos (in0));
   float v24 = in1 * v23;
   float v26 = in2 * v23;
   return v24 * v24 + v26 * v26 <= v17;
 }
 vec4 effect (vec2 p) { return bw(wobbly(time,p.x,p.y)); }
\end{verbatim}
%else
\begin{verbatim}
uniform float in0;
vec4 effect (float in1, float in2)
{ float v5 = 0.75 + 0.25 * cos (in0);  // TODO: hoist
  float v24 = in1 * in1 + in2 * in2 <= v5 * v5 ? 0.0 : 1.0;
  return vec4 (v24, v24, v24, v24);
}
\end{verbatim}
%endif
}

\framet{Automatic differentiation}{
\mathindent-1ex
\begin{code}
data D a b = D (a -> b :* (LM a b)) -- Derivatives are linear maps.
\end{code}
\pause
\vspace{-4ex}
\begin{code}
linearD f = D (\ a -> (f a, linear f))

instance Category D where
  id = linearD id
  D g . D f = D (\ a -> let { (b,f') = f a ; (c,g') = g b } in (c, g' . f'))

instance Cartesian D where
  exl  = linearD exl
  exr  = linearD exr
  D f &&& D g = D (\ a -> let { (b,f') = f a ; (c,g') = g a } in ((b,c), f' &&& g'))

instance NumCat D where
  negateC = linearD negateC
  addC  = linearD addC
  mulC  = D (mulC &&& \ (a,b) -> linear (\ (da,db) -> da * b + db * a))

\end{code}
}

\framet{Composing interpretations (|Graph| and |D|)}{

\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\small \mathindent1.5in
\vspace{-3ex}

> magSqr

\vspace{-7ex}
\wpicture{2in}{magSqr}
\end{tcolorbox}
\end{textblock}
\pause

\vspace{8ex}
\begin{center}\wpicture{4.5in}{magSqr-ad}\end{center}

%% \figoneW{0.51}{cosSinProd-ad}{|andDeriv cosSinProd|}{\incpic{cosSinProd-ad}}}
}

\framet{Composing interpretations (|Graph| and |D|)}{

\begin{textblock}{165}[1,0](173,41)
\begin{tcolorbox}
\small \mathindent-1ex
\vspace{-3ex}

> cosSinProd

\vspace{-6ex}

\wpicture{2in}{cosSinProd}
\end{tcolorbox}
\end{textblock}
\pause

\vspace{10ex}
\begin{center}\wpicture{4.5in}{cosSinProd-ad}\end{center}
}

%% \framet{Incremental computation}{}

\framet{Interval analysis}{
\mathindent1ex
\small

%format Iv = Interval
%format IF = IFun

%format al = a"_"lo
%format ah = a"_"hi
%format bl = b"_"lo
%format bh = b"_"hi
%format min4
%format max4

\begin{code}
data IF a b = IF (Iv a -> Iv b)
\end{code}
\pause
\vspace{-4ex}
\begin{code}
type family Iv a
type instance Iv Double      = Double :* Double
type instance Iv (a  :*  b)  = Iv a  :*  Iv b
type instance Iv (a  ->  b)  = Iv a  ->  Iv b
\end{code}

\begin{minipage}[b]{0.47\textwidth}
\begin{code}
instance Category IF where
  id = IF id
  IF g . IF f = IF (g . f)
NOP
\end{code}
\end{minipage}
\begin{minipage}[b]{0ex}{\ \ \rule[1.9ex]{0.5pt}{11ex}}\end{minipage}
\begin{minipage}[b]{0.3\textwidth}\setlength\mathindent{2ex}
\begin{code}
instance Cartesian IF where
  exl = IF exl
  exr = IF exr
  IF f &&& IF g = IF (f &&& g)
\end{code}
\end{minipage}
\vspace{-7ex}
\begin{code}
...
NOP
\end{code}
\pause
\vspace{-4ex}
\begin{code}
instance (Iv a ~ (a :* a), Num a, Ord a) => NumCat IF a where
  addC = IF (\ ((al,ah),(bl,bh)) -> (al+bl,ah+bh))
  mulC = IF (\ ((al,ah),(bl,bh)) ->
    minmax [al*bl,al*bh,ah*bl,ah*bh]
  ...
\end{code}
}

\framet{Interval analysis --- example}{

\begin{textblock}{165}[1,0](360,220)
\begin{tcolorbox}
\wpicture{1.45in}{xp3y}
\small \mathindent15ex
\vspace{-5.5ex}

> \ (x,y) -> x + 3 * y

\vspace{-4.5ex}

\end{tcolorbox}
\end{textblock}
\pause

\vspace{-4ex}
\begin{center}\wpicture{4.6in}{xp3y-iv}\end{center}
}

%if False
\framet{Interval analysis --- example}{

%if True

\begin{textblock}{165}[1,0](173,41)
\begin{tcolorbox}
\small \mathindent-1ex
\vspace{-3ex}

> horner [1,3,5]

\vspace{-6ex}

\wpicture{2in}{horner}
\end{tcolorbox}
\end{textblock}

%else
\vspace{3ex}

> horner [1,3,5]

\vspace{-12ex}
%endif
\begin{center}\wpicture{4.6in}{horner-iv}\end{center}
}
%endif

%if False
\framet{Constraint solving (with John Wiegley)}{ \small

%format Z3Cat = SMT
%format runZ3Cat = runSMT
%format ArrE = FunE
%format liftE1
%format liftE2

\begin{code}
newtype Z3Cat a b = Z3Cat (Kleisli Z3 (E a) (E b))

data E :: * -> * NOP where
    PrimE  :: AST -> E a
    PairE  :: E a -> E b -> E (a :* b)

instance Category Z3Cat where
    id  = Z3Cat id
    Z3Cat g . Z3Cat f = Z3Cat (g . f)

instance ProductCat Z3Cat where
    exl   = Z3Cat (arr (exl . unpairE))
    exr   = Z3Cat (arr (exr . unpairE))
    Z3Cat f &&& Z3Cat g = Z3Cat (arr PairE . (f &&& g))

instance Num a => NumCat Z3Cat a where
    negateC  = liftE1 mkUnaryMinus
    addC     = liftE2 mkAdd
    subC     = liftE2 mkSub
    mulC     = liftE2 mkMul
\end{code}
}

\framet{Constraint solving (with John Wiegley)}{
\begin{code}
pred :: (Num a, Ord a) => a :* a -> Bool
pred (x,y) =
    x < y &&
    y < 100 &&
    0 <= x - 3 + 7 * y &&
    (x == y || y + 20 == x + 30)
\end{code}

\vspace{4ex}

Solution: |(-8,2)|.

}
%endif

\framet{Other examples}{
\begin{itemize}\itemsep3ex
\item Constraint solving via SMT
\item Linear maps
\item Incremental evaluation
\item Polynomials
\item Nondeterministic and probabilistic programming
\end{itemize}
}

\definecolor{procolor}{rgb}{0,0.4,0}
\definecolor{concolor}{rgb}{0.7,0,0}

\nc\pro[1]{\item \textcolor{procolor}{#1}}
\nc\con[1]{\item \textcolor{concolor}{#1}}

\framet{Domain-specific embedded languages (DSELs)}{

\begin{itemize}\itemsep0.375ex\parskip0.375ex
\item \emph{Shallow} (just a library):
  \begin{itemize}\itemsep0.375ex
  \pro{Great fit with host language.}
  \pro{Easy to implement and use.}
  \con{Hard to optimize.}
  \item Good choice for \emph{expressing ideas}.
  \end{itemize}
\item \emph{Deep} (syntactic representation):
  \begin{itemize}\itemsep0.375ex
  \pro{More room for analysis and optimization.}
  \con{Harder to implement; redundant with host compiler.}
  \con{Less semantic guidance.}
  \con{Syntactically awkward in places.}
  \item Good choice for \emph{efficient implementation}.
  \end{itemize}
\pitem \emph{Compiling to categories}\out{ (library plus compiler plugin):}:
  %% \\Best of both.
  \begin{itemize}\itemsep0.375ex
    \pro{Great fit with host language.}
    \pro{Semantic guidance.}
    \pro{Easy to implement.}
    \pro{Analysis, optimization, non-standard target architectures.}
  \end{itemize}
\end{itemize}
}

\end{document}
