/*
*
*  $Header: /disc9/sniff/repository/BNRProlog/build_base/RCS/crias6.p,v 1.3 1996/02/08 23:04:32 yanzhou Exp $
*
*  $Log: crias6.p,v $
 * Revision 1.3  1996/02/08  23:04:32  yanzhou
 * The eval() clauses for '=:=' and '=\=' are slightly modified to use
 * "==" and "<>", respectively.
 *
 * Revision 1.2  1996/02/08  05:03:12  yanzhou
 * In BNRProlog version 4.3, boolean operators and relational operators
 * (in an eval) were implemented in Prolog.  They are now moved into the
 * WAM-based BNRProlog core.
 *
 * The supported boolean operators are:
 *
 *              WAM BODY ESCAPE   InCore Loader
 *   OPERATOR            OPCODE      HASH ENTRY   COMMENT
 *   --------   ---------------   -------------   ---------------------
 *   ~                       F8             127   boolean negation
 *   and                     F9              21   boolean and
 *   or                      FA             170   boolean or
 *   xor                     FB             242   boolean xor
 *   ->                      FC              19   boolean if
 *   nand                  F9F8             201   negation of and
 *   nor                   FAF8              92   negation of or
 *
 * The supported relational operators are:
 *
 *              WAM BODY ESCAPE   InCore Loader
 *   OPERATOR            OPCODE      HASH ENTRY   COMMENT
 *   --------   ---------------   -------------   ---------------------
 *   ==                      FD             201
 *   =:=                     FD              26   same as ==
 *   <>                    FDF8             221   negation of ==
 *   =\=                   FDF8              84   same as <>
 *   >                       FE              63
 *   =<                    FEF8             200   negation of >
 *   <                       FF              61
 *   >=                    FFF8             214   negation of <
 *
 * Modifed files are:
 *   cmp_arithmetic.p   - new $func1()/$func2() clauses
 *   compile.p          - new $esc() entries for each of the operators
 *   core.c             - new WAM F8-FF entries in the body escape op-code
 *                        table (both normal and in-clause modes)
 *   crias6.p           - revised eval() clauses for the operators
 *   loader.c           - new hash entries in scanList(),
 *                        -80 entries in remEscBytes[]
 *   core.h             - new BOOLEANREQUIRED run-time error
 *   base5.p            - new $error_string() clause for the BOOLEANREQUIRED
 *                        run-time error
 *   prim.[hc]          - new atoms for ~, and, or, and xor.
 *
 * Revision 1.2  1996/02/08  04:59:10  yanzhou
 * In BNRProlog version 4.3, boolean operators and relational operators
 * (in an eval) were implemented in Prolog.  They are now moved into the
 * WAM-based BNRProlog core.
 *
 * The supported boolean operators are:
 *
 *              WAM BODY ESCAPE   InCore Loader
 *   OPERATOR            OPCODE      HASH ENTRY   COMMENT
 *   --------   ---------------   -------------   ---------------------
 *   ~                       F8             127   boolean negation
 *   and                     F9              21   boolean and
 *   or                      FA             170   boolean or
 *   xor                     FB             242   boolean xor
 *   ->                      FC              19   boolean if
 *   nand                  F9F8             201   negation of and
 *   nor                   FAF8              92   negation of or
 *
 * The supported relational operators are:
 *
 *              WAM BODY ESCAPE   InCore Loader
 *   OPERATOR            OPCODE      HASH ENTRY   COMMENT
 *   --------   ---------------   -------------   ---------------------
 *   ==                      FD             201
 *   =:=                     FD              26   same as ==
 *   <>                    FDF8             221   negation of ==
 *   =\=                   FDF8              84   same as <>
 *   >                       FE              63
 *   =<                    FEF8             200   negation of >
 *   <                       FF              61
 *   >=                    FFF8             214   negation of <
 *
 * Modifed files are:
 *   cmp_arithmetic.p   - new $func1()/$func2() clauses
 *   compile.p          - new $esc() entries for each of the operators
 *   core.c             - new WAM F8-FF entries in the body escape op-code
 *                        table (both normal and in-clause modes)
 *   crias6.p           - revised eval() clauses for the operators
 *   loader.c           - new hash entries in scanList(),
 *                        -80 entries in remEscBytes[]
 *   core.h             - new BOOLEANREQUIRED run-time error
 *   base5.p            - new $error_string() clause for the BOOLEANREQUIRED
 *                        run-time error
 *   prim.[hc]          - new atoms for ~, and, or, and xor.
 *
 * Revision 1.1  1995/09/22  11:23:44  harrisja
 * Initial version.
 *
*
*/
%
%
%               Relational Interval Arithmetic Subsystem
%
%
%                 August 27 1992  W. J. Older
%
%
%    an interval constraint looks like:
%       Type(Variable, Nodelist,  Lower, Upper)
%           where Lower, Upper: Float
%                  Type : { $interval, $integral}
%        or
%       $boolean(Variable, Nodelist)
%
%    a node looks like:
%       Opcode( Z,X,Y )  
%           where X,Y,Z are interval variables
%       2nd character of Opcode name is used to discriminate operations
%      (for implementation reasons, all nodes must have the same arity (3)
%           they may be padded out with symbols e.g. nil )
%
%		for debugging - uncomment lines calling :
%					trace_crias1  - prints inputs to interval relations
%					trace_crias2  - prints transformed relations 
%       			(trace_enumerate - removed Dec 9 )
%					trace_solve
%
%		Aug 17 1992 -  point intervals used for reals
%       Aug 26 1992 -  bool => boolean, integral=> integer
%					-  add   additional relational boolean functions
%		Dec 09 1992 -  complicated fix to semantics of //
%					-  add range/2
%					-  add median pseudo-function
%					-  remove  interval/1 filter
% 					-  fix to $in_interval
%					-  fix & performance improvements in enumeration preds
%					-  add new predicate:  absolve
%       Nov 12 1993 -  interval data structure change 
%                       - node list now precedes bounds
%                       - booleans no longer have bounds
%                   -  $diophantine nodes no longer created/needed
%                   -  boolean operations mapped directly to boolean op nodes 
%       Dec  14 1993
%                   -  boolean wakeup var same as original & constrained to be 0 or 1
%                   -  enumeration revised extensively
%                   -  number of changes to $domain/domain to accomodate booleans
%       Dec 21  1993 - modified to use $iterate(Node,link) 
%       Mar  2  1994 - added cardinality predicate card/3
%                    - replace {} arithmetic with CLP(BNR)   ( needs corr. change in {} code )
%       Mar 10  1994 - code reorganized to support common subexpression consolidation
%                    - wrap(X,N) primitive added
%       Jun 05  1994 - fixed lower_bound/upper_bound to instantiate (no fuzz)
%		Jun 13  1994 - misc fixes to permit freeze constraints on intervals
%       Jun 23  1994 - add interval_control/3 
%		Oct 25  1994 - add :: operator, fix to {  }
%					 - fix for  11.1:real(0,20) etc.
%       Jan  8  1995 - fix for is, ==  with interval on left side
%                    - fix for  {X is (2;3)}
%                    - fix for  { 1 is B and C}
%       Jan 20  1995 - fix for  Y:integer, {Y is X}
%					 - global common subexpressions folding always done
%					 - trace_comex facility removed
%					 - remove contagion model
%					 - remove card/3 (cardinality)
%      				 - various fixes to solve, absolve,& accumulate (adding {}'s}
%       Jan 23  1995 - replace $domain calls with domain where possible
%					   ( which can handle freeze constraints)
%					 - handle extra freeze constraints in set_upper_bound
%						set_lower_bound, and accumulate
%       Mar     1995 - support for { B is (P->Q)} (boolean conditional constraint)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%					operator definitions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
op(700,xfy, '::').  % alias for :
op(700,xfx,':=').   % definition   (inherits type from rhs)
 	% boolean operations
op(400,xfy, and).   % and
op(400,xfy, nand).  % nand
op(500,xfy, xor).   % xor
op(500,xfy, or).    % or
op(500,xfy, nor).   % nor
op(300, fy, '~').   % negation
    % relations
op(600,xfx,'<=').   % subinterval, member, "diode"
op(600,xfx,'|=').   % starts together
op(600,xfx,'=|').   % ends together

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%					error messages
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
$error_string( run_time, 2000, 'Unknown arithmetic function').
$error_string( run_time, 2001, 'Arithmetic type error').
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%					X:Type (or X::Type)
%					X:Type(Lower,Upper)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%       new  "declaration" predicates
%       Sept 12 -   X:real, X:real  etc. now works
%                   and X:real(L,U), X:real(L1,U1)  results in intersection 
%
%  both : and :: supported, the latter for future compatibility with Prolog standard

L::T:- list(L),!, $dcl(L,T).
X::T:- symbol(T),!, $dc(T,X).
X::T:- structure(T),!, $dcr(T,X).


L:T:- list(L),!, $dcl(L,T).
X:T:- symbol(T),!, $dc(T,X).
X:T:- structure(T),!, $dcr(T,X).
 
$dc(real,X)   :- var(X), $new_interval(X,L,U),!.
$dc(real,X)   :- var(X),!, domain(X, real(_,_)).
$dc(real,X)   :- float(X),!.
$dc(integer,X):- var(X), $new_integral(X,L,U),!.
$dc(integer,X):- var(X),!, domain(X, integer(_,_)).
$dc(integer,X):- integer(X),!.
$dc(boolean,X):- var(X),  $new_boolean(X),!.
$dc(boolean,X):- var(X),!, domain( X, boolean(_,_)).
$dc(boolean,X):- integer(X), boolean(X),!.

% current restriction: no other constraints
$dcr(real(L,U),X)   :- var(X),   $new_interval(X,L,U),!.
$dcr(real(L,U),X)   :- var(X),!, domain(X,real(_,_)), $restrict(X,L,U).
$dcr(real(L,U),X)   :- float(X),!,$in_interval(X,L,U, $interval). 
$dcr(integer(L,U),X):- var(X),   $new_integral(X,L,U),!.
$dcr(integer(L,U),X):- var(X),!, domain(X,integer(_,_)), $restrict(X,L,U).
$dcr(integer(L,U),X):- integer(X),!, $in_interval(X,L,U,$integral).
$dcr(boolean(0,1),X):- var(X),   $new_boolean(X),!.    % added Nov 93 (permit bds on bools)
$dcr(boolean(0,1),X):- var(X),!,  domain( X, boolean(_,_)).
$dcr(boolean(0,1),X):- integer(X), boolean(X),!.

$dcl([],T) :-!.
$dcl([X,Xs..],T) :- X:T, $dcl(Xs,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%			range( Var, [Lower,Upper])  :- query range
%			lower_bound(X)  :- narrow to lower bound
%			upper_bound(X)  :- narrow to upper bound
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	
range(X, [L,L]):- numeric(X),!, L is float(X).
range(X, [L,U]):- domain(X,_(L,U)).

% misc primitives: set interval to either bound
lower_bound( X ):- numeric(X),!.
lower_bound( X ):- domain(X,T(L,U)),!,$set(T,X,L).
upper_bound( X ):- numeric(X),!.
upper_bound( X ):- domain(X,T(L,U)),!,$set(T,X,U).

%  uses $iterate directly to avoid fuzzing
$set(real,X,T):- !,$iterate($equal(X,T,nil)).
$set(integer,X,T):- !,T1 is round(T), $iterate($equal(X,T1,nil)).
$set(boolean ,X,T):- !,T1 is round(T), $iterate($equal(X,T1,nil)).

% query type
$interval_type(X,Type):- domain(X,Type(_..)).  %June 1994
         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%       for arithmetic relations in {  }  (added march 1994, modified Oct 94)
%
%		$braced_arithmetic( Arith_Rel(Left, Right))
%
%		$arithmetic_relation( Arith_Rel).
%
%       these predicate called from base1
%
%       when used in {}, all arithmetic is treated as CLP(BNR)
%       (contagion rule does not apply) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

$arithmetic_relation( is).
$arithmetic_relation( ':=').
$arithmetic_relation( '==').
$arithmetic_relation( '=<').
$arithmetic_relation( '>=').
$arithmetic_relation( '<>').
$arithmetic_relation( '>' ).
$arithmetic_relation( '<' ).
$arithmetic_relation( '<=').
$arithmetic_relation( '|=').
$arithmetic_relation( '=|').

$braced_arithmetic( F(X,Y) ):- $ria_relation( X,Y,F).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%       basic arithmetic relations (constraints not in {} )
%            "contagion" semantics
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
/*    removed Jan 1995  : no longer supported
Y is X :-   Y:= X.
Y := X  :-  nonvar(Y),!, Y==X.
Y := X  :-  var(Y),($interval_expression( X) ; ground(X)), !,		% Sept 8
            $define_int(Y,X),!.
%  Y := X   :-  nl, write('Type error in ', Y:=X), fail.

% June 94 (moved into ria-relation ) X == Y :- var(X), $virgin(X),!, Y := X.   % mar 94
X == Y :- $interval_expression([X,Y]),!, $ria_relation(X,Y, '=='),!.
X >= Y :- $interval_expression([X,Y]),!, $ria_relation(X,Y, '>='),!.
Y =< X :- $interval_expression([X,Y]),!, $ria_relation(X,Y, '>='),!.     
Y <> X :- $interval_expression([X,Y]),!, $ria_relation(X,Y, '<>'),!.
Y <= X :- $interval_expression(X),$interval_expression(Y),!, $ria_relation(X,Y, '<='),!.
Y |= X :- $interval_expression(X),$interval_expression(Y),!, $ria_relation(X,Y, '|='),!.
Y =| X :- $interval_expression(X),$interval_expression(Y),!, $ria_relation(X,Y, '=|'),!.
X > Y  :- $interval_expression([X,Y]),!, $ria_relation(Y,X, '<'),!.
Y < X  :- $interval_expression([X,Y]),!, $ria_relation(Y,X, '<'),!.     



% "default model" -  any expression with unbound variables(and no tailvars)
% $interval_expression( T ):- variables(T,Vs,[],_), not(Vs=[]).
%

%  "contagion model"  - to be an interval expression it must contain at least one interval already
$interval_expression( T ):-  variables(T,Vs,[],Cs),
							 $contains_interval(Vs).
$contains_interval([T, _..]):-$interval_type(T,_),!.   % Dec 93
$contains_interval([_,Ts..]):-$contains_interval(Ts).

end of removed */   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%                         Implementation 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  interval constructors and access routines

$new_interval(X,L,U):- $new_interval$(X,L,U,$interval),!.
$new_integral(X,L,U):- $new_interval$(X,L,U,$integral),!.  % Nov 93 $newnode($diophantine,X,nil,nil),!.
$new_boolean(X):- freeze(X, $boolean(X,[ Nodelist..]) ).      

$new_interval$(X,L1,U1, Type ):- % $virgin(X),     % Type is internal name- except $boolean        
       $lower(L1,L,Type), $upper(U1,U,Type),
       freeze(X,  Type(X, [ Nodelist..], L, U)).  % Nov 93

$lower( V, N, Type ):- var(V),!, $maxbd(Type,M), N is -M.      % defines universal interval
$lower( N, N1, _   ):- N1 is float(N),!.
$upper( V, M,Type  ):- var(V),!, $maxbd(Type,M).
$upper( N, N1,_    ):- N1 is float(N),!.
$maxbd( $interval,M):- !, M is  1.0e100 .
$maxbd( $integral,M):- M is float(maxint).

%           $virgin(X)    removed Jan 1995 (not used)
%            X must be  unbound and unconstrained
%     $virgin(X) :-var(X), variables(X,[X],[],L), L=[].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
% 					domain( Var, Type(Lower,Upper))
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% $domain( Var,  Type(Var,List,_..) )  
%         - principal internal routine used to get at interval attributes

$domain(V,Dom):- var(V), variables(V,_,_,[freeze(_,Dom),_..]).		
%  interval entry must be first item on list of frozen goals
%  (this property is maintained by var-var binding of frozen vars) 
%  generally do not use $domain directly- need to copy bounds-so use domain 

domain( V, Descriptor) :- $domain(V, Dom),
		$valid_domain(Dom, Descriptor),!.
$valid_domain( InType(V, _ , L,U), Type(LB,UB) ):- 
		$$interval_type(InType,Type),!,  LB is L, UB is U.
%  need to copy bounds because they may be changing subsequently 
$valid_domain( $boolean(V,List), boolean(0.0,1.0) ):-!. 
$valid_domain( [X,_..],D):- $valid_domain(X,D).  % Jun 94 in case of extra constraints

$$interval_type( $interval, real ).
$$interval_type( $integral, integer ).
$$interval_type( $boolean,  boolean  ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%  when interval variable is bound by Prolog, these predicates are fired
%
%   constraint network does not usually wakeup these goals when
%   it instantiates a variable , except when there is more than one frozen goal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
$interval(X,List,L,U):- X1 is float(X), X1==L, X1==U,!. 
$interval(X,List,L,U):- float(X), $in_interval(X,L,U,$interval), $iterate(List). 
$integral(X,List,L,U):- integer(X), X1 is float(X), X1==L, X1==U,!.
$integral(X,List,L,U):- integer(X), $in_interval(X,L,U,$integral), $iterate(List). 
$boolean(X,List):- boolean(X), $iterate(List).   %  Dec 21 93

boolean(0).
boolean(1).

$in_interval(X,L,U,Type):- $lower(L,L1,Type), $upper(U,U1,Type), L1=<X,X=<U1. % Dec 3 92

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%                  node constructors & miscellaneous stuff
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 		restrict- narrows range without linking nto network

$restrict(X,L,U):- Y:real(L,U), $iterate($equal(X,Y,nil)). 

%  Note:
%    assignments of values and inequalities (with constants) can be done by
%    calling:   $iterate( Name(Z,X,Y) 
%    (this avoids overheads of linking the node)

% point intervals
$point_interval( N,  N):- integer(N),!.
$point_interval( 0.0,0):- !.    % dont fuzz 0.0
$point_interval( X, PX):-  $fuzz(X,XL,XH), PX:real(XL,XH).

% standard node constructor and link into constraint structure
$newnode(N) :- $iterate( N,link).
        


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%                  node constructors & miscellaneous stuff
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%       analysis section -
%         - type inferencing
%         -decomposes constraint into "atomic" pieces (in good evaluation order)
%         -simplifies where possible
%         -coalesces some common subexpressions
%         -determines type information  (real,integer,bool)
%
$ria_relation( X, Y, Def):- var(X),$defining(Def), !, % Jan 1995
		$define_int(X,Y).  % June 94 
$ria_relation( X, Y, Lastop):-
%		predicate(trace_crias1) -> print(Lastop(X,Y)),
        $flatrel( Lastop(X,Y)),!. 

$defining('is').
$defining(':=').
$defining('==').
%
%  $flatrel( Arith_rel)
%     may fail if Arith_rel is always false
%     may reeturn [] if Arith_rel is always true
%     otherwise returns optimized (indefinite) list of arithmetic operations

$flatrel(R(X, Y)):- 
        $flatexpr(X,  XE, T1), 
        $flatexpr(Y,  YE, T2),
		$rel_type(R, T1, T2),
		!,
        $add_rel(R(XE, YE)).
$flatrel(R(X, Y)) :- 				% can't flatten it, so
		error(2001).						% moved from $ria_relation 93/03/03 JR

$rel_type(<>, T1,  T2):-!, $discrete(T1), $discrete(T2),!.
$rel_type(R , T1 , T2).
$discrete( boolean).
$discrete( integer).

$add_rel( R(X,Y)):- X@=Y,!,  not(R@='<>').        % tautologically true (or false)
$add_rel( R(X,Y)):- nonvar(X,Y),!,  R(X,Y).       % evaluate if possible
$add_rel( Rel)   :- $eval( Rel).


%
%       This handles case where left side of equation is just a variable
%
$define_int(Y,X):- $flatexpr( X,  YE,T),
			$interval_def(Y, YE,T).
$interval_def( Y,Y1,Type):- $interval_type(Y,T2),!,  % T2 / Jan 20 1995
		$add_rel(Y==Y1).			% different types may be equated
$interval_def( Y,Y,_).  % left hand side was not an interval

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  
%  					$flatexpr( Expr,  Value )
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
% Input:  -Expr is an arithmetic expression with either variables or numeric constants at leaves
%               or a list of such expressions.
%         -List is an indefinite list of form  Var=Op(Args..), matched on rhs
% Output: -List is list of  X=Op where Op is a valid primitive operation,
%               in proper evaluation order
%         -Easily recognized common subexpressions have been coalesced.
%         -Value is output variable.
%   Mar 94 - list no longer used / nodes are evaluated directly  

                        
$flatexpr( V ,    V , T ):- var(V),!, $var_type(V, T).
$flatexpr( pi,    P,real):- P is pi,!.
$flatexpr( N,     N1, T) :- numeric(N),!, 
        $constype(N,T), $point_interval(N,N1),!.
$flatexpr( F(X),  Y,  T):- $flatexpr1(F,X,Y,T),!.  %special monadics
$flatexpr( F(X),  Res,Type):-!,  % rest of monadics
        $down_type1(F,T,Type),      % propagate bool, int downwards
        $flatexpr(X,XE,T),
        $type1( F, T, Type ),
        $add_one(F(XE),Res,Type),!.


$flatexpr1( sin,     X,Y, real ):- P is pi,  $trig(sin,X,Y,P).
$flatexpr1( cos,     X,Y, real ):- P is pi,  $trig(cos,X,Y,P).
$flatexpr1( tan,     X,Y, real ):- P is pi/2,$trig(tan,X,Y,P).
$flatexpr1( midpoint,X,Y, real) :- domain(X,_(L,U)), Y is (L + U)/2.0 .
$flatexpr1( delta,   X,Y, real) :- domain(X,_(L,U)), Y is (U - L) .
$flatexpr1( median,  X,Y, real) :- domain(X,_(L,U)), $median(L,U,Y).
$flatexpr1( float,   X,Y, real) :- !, numeric(X), Y is float(X).
$flatexpr1( round,   X,Y, integer) :- ground(X),!, Y is round(X).
$flatexpr1( round,   X,Y, integer) :- Y:integer, Y - 0.5 =< X, X =< Y + 0.5 .
$flatexpr1( floor,   X,Y, integer) :- numeric(X),!, Y is floor(X).
$flatexpr1( floor,   X,Y, integer) :- Y:integer, Y =< X, X < Y + 1  .
$flatexpr1( ceiling, X,Y, integer) :- ground(X),!, Y is ceiling(X).
$flatexpr1( ceiling, X,Y, integer) :- Y:integer, Y - 1 < X, X =< Y.

$trig( F, X, Res, Period):-
        $flatexpr( X, XE, real),
        $add_one( wrap(XE,Period), Y, real),
        $add_one( F(Y), Res, real).

%    dyadics

$flatexpr( F(X,Y),  Res,Type):- 
	not($exceptions(F)),
        $down_type2(F,T1,T2,Type),!,
        $flatexpr(X,XE,T1),
        $flatexpr(Y,YE,T2),
        $type2( F, T1,T2, Type),
        $normalform( F(XE,YE), NF),
        $add_one( NF,  Res,Type), !.
$flatexpr( X**0,    1,  integer):-!, $flatexpr(X,_,Type).
$flatexpr( X**1,    Res,  Type):-!, $flatexpr(X,Res,Type).
$flatexpr( X**N,    Res,Type):- N1 is N, integer(N1),N1<0,!, N2 is - N1,
        $flatexpr( (1/X)**N2, Res, Type).
$flatexpr( X**N,    Res,Type):-!, N1 is N, integer(N1),
		nonvar(Type)-> $typepow(N1,T,Type),
        $flatexpr( X,  XE, T),
		$typepow(N1, T, Type), 
        $odd_even( N, P),
		$add_one( P(XE,N1), Res,Type),!.
$flatexpr( X<>Y,  Res,boolean):- !, $flatexpr( ~(X==Y), Res, boolean).
$flatexpr( X< Y,  Res,boolean):- !, $flatexpr( ~(Y=<X), Res, boolean).
$flatexpr( X> Y,  Res,boolean):- !, $flatexpr( ~(X=<Y), Res, boolean).
$flatexpr( wrap(X,N), Res, real):- !, numeric(N), N1 is N,
        $flatexpr( X, XE, real),
        $add_one(  wrap(XE,N1), Res, real),!.

$exceptions('**').
$exceptions(wrap).
$exceptions('<>').
$exceptions('<').
$exceptions('>').

$odd_even(2,$root):-!.
$odd_even(N,$qpow_even):- 0 == N mod 2,!.  
$odd_even(N,$pow_odd ) :- 1 == N mod 2.  


$constype(N, boolean ):-boolean(N).
$constype(N, integer):-integer(N).
$constype(N, real ).

$var_type(V,Type):- $interval_type(V,Type1),!,$cftype(Type,Type1).  % get and/or match type
$var_type(V,Type):- $valid_type(Type), V:Type,!.
$cftype(T,T):-!.
$cftype(T1,T2):- error(2001).

$valid_type(real).  % default
$valid_type(integer).
$valid_type(boolean).


%  put operation into standard form  
%  (e.g. ordering arguments in commutative ops to ease finding of common subexpressions)
$normalform( X+Y , X*2 ):- breadth_first_compare(X,Y,'@='),!.
$normalform( X*Y , $root(X,2) ):- breadth_first_compare(X,Y,'@='),!.
$normalform( F(X,Y), F(Y,X) ):-$commutes(F), breadth_first_compare(X,Y,'@>'),  !.
$normalform( X=<Y, Y>=X):-!.
$normalform( F, F). 

$commutes( '+' ).
$commutes( '*' ).
$commutes( 'min').
$commutes( 'max').
$commutes( ';' ).
$commutes(  or).
$commutes(  nor).
$commutes(  and).
$commutes(  nand).
$commutes( '==').
$commutes( '<>').		% added Feb 19/93
$commutes(  xor ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  
%   $add_one( Primitive_expr, Result, Type_of_result):-
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%   strategy: 1. try to eliminate locally by symbolic rewriting
%             2. try to locate previously computed expressions (ig enabled)
%   else      3. generate new node

$add_one( F(X,Y),Res, _   ):- $reduce(F,X,Y,Res),!.  % operation can be eliminated
$add_one( F,     Res, Type):- 
  %    predicate(global_common_subexpressions_enabled), % diabled Jan 1995
         $find_existing( F, Res), !.  % found common sub expression
$add_one( F,     Res, Type):- Res:Type,     % make new interval variable
         tracing_crias -> [nl, write( Res=F)],
         $eval( Res=F),!.

%  expressions reducing to sub expressions or constants
$reduce(;,X,Y, X):- !, X@=Y.  % Jan 1995  avoids evaluating eg 2;3
$reduce(F,X,Y, Z):- numeric(X,Y), symbol(F),!, 
	             eval(F(X,Y),Z1),
	             $point_interval(Z1, Z).
$reduce('-', X,Y, 0):- X@=Y.    % X - X = 0
$reduce(+, X,Z, X):- Z@=0.      % X + 0 = X
$reduce('-', X,Z, X):- Z@=0.    % X - 0 = X
$reduce(/, X,Y, 1):- X@=Y.      % X / X = 1
$reduce(//,X,Y, 1):- X@=Y.      % X // X = 1
$reduce(*, Y,Z, 0):- Z@=0.      % Y *  0 = 0
$reduce(*, Y,U, Y):- U@=1.      % Y * 1 = Y
$reduce(/, Y,U, Y):- U@=1.      % Y / 1 = Y
$reduce(//,Y,U, Y):- U@=1.      % Y // 1= Y
$reduce(min,X,Y,X):- X@=Y.      % min(X,X)=X
$reduce(max,X,Y,X):- X@=Y.      % max(X,X)=X
$reduce(or, X,Z,1):- Z@=1.      % X or 1 = 1
$reduce(or, X,Z,X):- Z@=0.      % X or 0 = X
$reduce(or, X,Y,X):- X@=Y.      % X or X = X
$reduce(and,X,Z,0):- Z@=0.      % X and 0 = 0
$reduce(and,X,Z,X):- Z@=1.      % X and 1 = X
$reduce(and,X,Y,X):- X@=Y.      % X and X = X
$reduce(==, X,Y, B):- $eqop(X,Y,B).
$reduce(xor,X,Y,B):- $neqop(X,Y,B).
 
$eqop(X,Y,1):-X@=Y,!.         % same const or same var
$eqop(X,Y,0):- numeric(X,Y).  % different constants
$neqop(X,Y,0):-X@=Y,!.
$neqop(X,Y,1):- numeric(X,Y).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  
%           type propagation rules
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
%  up-tree propagation rules:
%  		$type1( Op, !InType,   ?OutType)
%  		$typepow(N, !InType,   ?Outtype)
%  		$type2( Op, !In1, !In2,?OutType)

$type1( '~', boolean,  boolean    ):-!.
$type1( '-', integer,  integer):-!.
$type1( abs, integer,  integer):-!.
$type1( floor,   T,    integer):-!.		% added Feb 19/93
$type1( ceiling, T,    integer):-!.		% added Feb 19/93
$type1( Op,      T,    real ):-!.  % generally output of unary ops is real

$typepow(N, integer,  integer):-N>0.
$typepow(N, T1,        real):-!.

$type2(or,   boolean, boolean, boolean):-!.
$type2(nor,  boolean, boolean, boolean):-!.
$type2(and,  boolean, boolean, boolean):-!.
$type2(nand, boolean, boolean, boolean):-!.
$type2(xor,  boolean, boolean, boolean):-!.
$type2(->,   boolean, boolean, boolean):-!.
$type2('+',  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2('-',  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2('*',  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2(min,  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2(max,  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2(';',  T1,      T2,      R) :- $type2_real(T1, T2, R), !.
$type2('==', T1,      T2,      boolean):-!.
$type2('>=', T1,      T2,      boolean):-!.
$type2('=<', T1,      T2,      boolean):-!.
% $type2('<',  T1,      T2,      boolean):-!.		% added Feb 19/93
% $type2('>',  T1,      T2,      boolean):-!.		% added Feb 19/93
% $type2('<>', integer, integer, boolean):-!.		% added Feb 19/93
$type2('/',  T1,      T2,      real):-!.  % division always produces real 
$type2('//', T1,      T2,      integer):-!. % int division always produces int 
$type2(divf, T1,      T2,      R) :- $type2_integer(T1, T2, R), !.	% added Feb 19/93
$type2(divc, T1,      T2,      R) :- $type2_integer(T1, T2, R), !.	% added Feb 19/93

$type2_real(boolean, boolean, integer).
$type2_real(boolean, integer, integer).
$type2_real(integer, boolean, integer).
$type2_real(integer, integer, integer).
$type2_real(_,       _,       real).

$type2_integer(boolean, boolean, integer).
$type2_integer(boolean, integer, integer).
$type2_integer(integer, boolean, integer).
$type2_integer(integer, integer, integer).

%     down tree rules - for propagating forced boolean/integer down the tree
%     these are derived from the rules above (but run backwards) 
%           when    outgoing type is determined
%              or   ~,and, or,.. <> are involved
$down_type1('~',boolean, boolean):-!.
$down_type1(F, T1,  T2  ):- nonvar(T2),!,$type1(F,T1,T2).  
$down_type1(_,_,_ ).

$down_type2(and, boolean, boolean, boolean):-!.
$down_type2(nand,boolean, boolean, boolean):-!.
$down_type2(or,  boolean, boolean, boolean):-!.
$down_type2(nor, boolean, boolean, boolean):-!.
$down_type2(xor, boolean, boolean, boolean):-!.
$down_type2(->,  boolean, boolean, boolean):-!.
$down_type2(F,  T1, T2, T      ):- nonvar(T),!,$type2(F,T1,T2,T).
$down_type2(_,_,_,_ ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  
%           normal arithmetic extensions
%      defining boolean operations ( and other extended arithmetic operators)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
eval( midpoint(X),X):- numeric(X),!.  % overload 'is' for bound intervals
eval( midpoint(X),Y):- domain(X,_(L,U)), Y is (L + U)/2.0,! .

eval( delta(X), 0.0):- numeric(X),!.
eval( delta(X), Y):- domain(X,_(L,U)), Y is (U - L) ,!.

eval( median(X), X):- numeric(X),!.
eval( median(X), Y):- domain(X,_(L,U)), $median(L,U,Y),!. 

/*
 * Feb 1996 modified by yanzhou@bnr.ca
 * boolean operators are now implemented in WAM op-codes
 */
eval(  ~    B, R) :- B1 is B, R is (~ B1), !.
eval(A and  B, R) :- A1 is A, B1 is B, R is (A1 and  B1), !.
eval(A or   B, R) :- A1 is A, B1 is B, R is (A1 or   B1), !.
eval(A xor  B, R) :- A1 is A, B1 is B, R is (A1 xor  B1), !.
eval(A nor  B, R) :- A1 is A, B1 is B, R is (A1 nor  B1), !.
eval(A nand B, R) :- A1 is A, B1 is B, R is (A1 nand B1), !.
eval(A ->   B, R) :- A1 is A, B1 is B, R is (A1 ->   B1), !.
eval(A ==   B, R) :- A1 is A, B1 is B, R is (A1 ==   B1), !.
eval(A =:=  B, R) :- A1 is A, B1 is B, R is (A1 ==   B1), !.
eval(A <>   B, R) :- A1 is A, B1 is B, R is (A1 <>   B1), !.
eval(A =\=  B, R) :- A1 is A, B1 is B, R is (A1 <>   B1), !.
eval(A <    B, R) :- A1 is A, B1 is B, R is (A1 <    B1), !.
eval(A =<   B, R) :- A1 is A, B1 is B, R is (A1 =<   B1), !.
eval(A >    B, R) :- A1 is A, B1 is B, R is (A1 >    B1), !.
eval(A >=   B, R) :- A1 is A, B1 is B, R is (A1 >=   B1), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%					$find_existing( Oper, Result) 
%
%        Searches for a node computing Oper in the interval constraint network
%        and returns the proper variable if found; else fails.
%        ( This predicate to be replaced largely by a primitive call.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
$find_existing( F(X,Y), Z):-
       		% trace_comex -> [nl, write( 'search for ', F(X,Y))],
       $map2(F,X,Y, Z, G, N),
       		% trace_comex -> [nl, write($findCommonSubex( G,N))],
       $findCommonSubex( G,N). % trace_comex -> [nl, write(foundit(Z))].

$find_existing( F(X), Z):-
       		% trace_comex -> [nl, write( 'search for ', F(X))],
       $map1(F,X, Z, G, N),!,
       		% trace_comex -> [nl, write($findCommonSubex( G,N))],
       $findCommonSubex( G,N).  % trace_comex -> [nl, write(foundit(Z))].

$find_existing( F(X), Z):-
       		% trace_comex -> [nl, write( 'search for ', F(X))],
       $map1r(F,X, Z, G, N, _),!,
       		% trace_comex -> [nl, write($findCommonSubex( G,N))],
       $findCommonSubex( G,N).     % trace_comex -> [nl, write(foundit)].


/*  Prolog version (replaced in early 1994)
$find_existing( F(X,Y) , Z):-
       $get_a_node_list([X,Y],L),   % get node list from X else from Y else fail
       $map2(F,X,Y,Z, G, N),        % figure out what to look for; N is position of output
       $locate_node( L, G, N),!.    % search list for target

$find_existing( F(X), Z ):-
       $domain( X, T(_,L,_..) ),    % this wont work if there are freeze constraints
       $map1(F,X, Z, G, N),
       $locate_node( L, G, N),!.


$get_a_node_list( [X,_..], L) :- $domain( X, T(_,L,_..) ),!. % no longer valid (see above)
$get_a_node_list( [_,Xs..],L) :- $get_a_node_list(Xs,L).


$locate_node(  [Ls..], _, _):- tailvar(Ls..),!,fail.
$locate_node(  [F(Z,X,Y), Ls..], F(Z1,X1,Y1),1 ):- X@=X1,Y@=Y1,!,Z=Z1.
$locate_node(  [F(Z,X,Y), Ls..], F(Z1,X1,Y1),2 ):- Z@=Z1,Y@=Y1,!,X=X1.
$locate_node(  [F(Z,X,Y), Ls..], F(Z1,X1,Y1),3 ):- Z@=Z1,X@=X1,!,Y=Y1.
$locate_node(  [_, Ls..], G ,N):- $locate_node( Ls,G,N). 
*/

$map2(+,  X,Y,   Z, $add(Z,X,Y)  ,1).
$map2(*,  X,Y,   Z, $mul(Z,X,Y)  ,1).
$map2(min,X,Y,   Z, $inf(Z,X,Y)  ,1).
$map2(max,X,Y,   Z, $lub(Z,X,Y)  ,1).
$map2('-',X,Y,   Z, $add(X,Y,Z)  ,3).
$map2(/,  X,Y,   Z, $mul(X,Y,Z)  ,3).
$map2(and,X,Y,   Z, $$conjunction(Z,X,Y) ,1).
$map2(or, X,Y,   Z, $$disjunction(Z,X,Y) ,1).
$map2(nand,X,Y,  Z, $$anynot(Z,X,Y) , 1).
$map2(nor,X,Y,   Z, $$bothnot(Z,X,Y) ,1).
$map2(xor,X,Y,   Z, $$exor(Z,X,Y),1).
$map2(->, X,Y,   Z, $$gconditional(Z,X,Y),1).  % Mar 95
$map2(';',X,Y,   Z, $or(Z,X,Y),   1).
$map2(==, X,Y,   B, $k_equal(X,Y,B),3).
$map2(>=, X,Y,   B, $j_less(X,Y,B), 3).
$map2(=<, Y,X,   B, $j_less(X,Y,B), 3).
$map2($root,X,N,      Z, $root(Z,X,nil),  1).
$map2($qpow_even,X,N, Z, $qpow_even(Z,X,N), 1).
$map2($pow_odd,  X,N, Z, $pow_odd(Z,X,N),   1).
$map2(wrap,      X,N, Z, $wrap(Z,X,N),      1).  % mar 94

$map1('-', X,     Z, $add(0,X,Z),   1).
$map1(exp, X,     Z, $xp(Z,X,nil),  1).
$map1(ln,  X,     Z, $xp(X,Z,nil),  2).
$map1(abs, X,     Z, $vabs(Z,X,nil),1).
$map1(sq,  X,     Z, $root(Z,X,nil),1).    
$map1(tan, X,     Z, $tan(Z,X,nil), 1).    
$map1('~', X,     Z, $$falseimplied(X,Z,nil),2).  % Nov 93

% these 2-ary primitives have additional domain restrictions

$map1r(sin, X,     Z, $sin(Z,X,nil), 1,$restrict(Z,-1,1) ).  % May 95
$map1r(cos, X,     Z, $cos(Z,X,nil), 1,$restrict(Z,-1,1) ).  % May 95
$map1r(sqrt, X,     Z, $root(X,Z,nil),  2,  $restrict(Z,0,_) ).
$map1r(asin, X,     Z, $sin(X,Z,nil),   2,  $restrict(Z,-pi/2,pi/2) ).
$map1r(acos, X,     Z, $cos(X,Z,nil),   2,  $restrict(Z,0,pi) ).
$map1r(atan, X,     Z, $tan(X,Z,nil),   2,  $restrict(Z,-pi/2,pi/2) ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%					$eval(Prim) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      evaluate operations
%          - construct constraint network from list of primitive operations
%          - periodic transcendental functions synthesized
%          - find first fixed point (incrementally during construction)
%  Note: this routine may be candidate for a primitive , as it is
%                     fundamentally straightforward
%
$eval( Z = F(X)   ):- $map1( F,X,Z, N,_ ),!,$newnode(N).
$eval( Z = F(X)   ):- $map1r( F,X,Z, N, _, Restrict ),!,					 
                      Restrict, 
                      $newnode(N).
$eval( Z = F(X,Y) ):- $map2( F,X,Y,Z,N, _),!,$newnode(N).
$eval( Rel(X,Y)   ):- $fmap_rel(Rel,R),!, $newnode(R(X,Y,nil)).        
$eval( X =< Y ):- !, $newnode( $greatereq(Y,X,nil)).
$eval( X > Y  ):- !, $newnode( $higher(Y,X,nil)).

$fmap_rel('==', $equal).
$fmap_rel('>=', $greatereq).
$fmap_rel('is', $equal).  				% added Jan 1995
$fmap_rel('<' , $higher).
$fmap_rel('<>', $unequal).
$fmap_rel('<=', $narrower).
$fmap_rel('|=', $begin_tog).
$fmap_rel('=|', $finish_tog).


$fmap2(  X // Y,N):-!,W:real,N1:integer,N2:integer,B:boolean,BN:boolean,
				$newnode( $mul,X,Y,W),				% W is X/Y
			    $newnode( $j_less,0,W,BN),			% B is (W>=0),
				$newnode( $$falseimplied,BN,B,nil), % Nov 93			
				$newnode( $add,N1,N,B),				%   N - ~B =< W
				$newnode( $add,N,N2,BN),			%   W =< N + B
				$newnode( $greatereq,W,N2,nil),
				$newnode( $greatereq,N1,W,nil).
$fmap2(  X divc Y, N) :-!,							% added Feb 19/93
%				$restrict(X,0,_),
				$restrict(Y,1,_),
				R:integer(0,_),
				X==Y*N-R,
				R<Y.				
$fmap2(  X divf Y, N) :-!,							% added Feb 19/93
%				$restrict(X,0,_),
				$restrict(Y,1,_),
				R:integer(0,_),
				X==Y*N+R,
				R<Y.				
$fmap2(  F , Z   ):- nl, write( 'bad expr:',F), error( 2000) .

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%						enumeration and solve
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%		enumeration for integer and boolean
%
%  enumerate( X ) and firstfail(X) are intended for either single (or lists of)
%  boolean or integer intervals, but will do solve on any real intervals
%  encountered.  The order is: booleans, integer, real.
%  Note that firstfail, which enumerates variables with the smallest
%  range (dynamically computed) first, will almost always be faster than enumerate
%  on a random list of int variables; only if the structure of the problem suggests
%  a 'natural' enumeration order will enumeration on this order likely be as good
%  as firstfail.  Firstfail will also always enumerate booleans
%  before integer or real domains.
%
%  The optional extra parameter Exec_on_Backtrack is mainly used for counting
%  backtracks and/or debugging  (e.g.using  break ).
%
%  Extensively rewritten december 1993 wjo
enumerate(List):- !,      % modified dec 93 to preseparate types
     $classify_intervals( List, Bs, Ns, Rs ),
     $bool_enumerate(Bs),   % do booleans first (smaller domains)
     $int_enumerate( Ns),
     $real_enumerate(Rs).


	% note: cut not required here, but it may sometimes eliminate the need 
	%  to copy the stat during the first interval update
	% In general, care must be taken in these predicates to avoid leaving any
	% unnecessary choicepoints for the same reason.
enumerate(List, Exec_on_Backtrack):- 
     $classify_intervals( List, Bs, Ns, Rs ),
     $bool_enumerate_act(Bs,Exec_on_Backtrack),   % do booleans first (smaller domains)
     $int_enumerate_act(Ns, Exec_on_Backtrack),
     $real_enumerate(Rs).

firstfail(List):- !, 
     $classify_intervals( List, Bs, Ns, Rs ),
     $bool_enumerate(Bs),   % do booleans first (smaller domains)
     $int_enumerateff( Ns),
     $real_enumerate(Rs).
firstfail(List, Exec_on_Backtrack):- 
     $classify_intervals( List, Bs, Ns, Rs ),
     $bool_enumerate_act(Bs, Exec_on_Backtrack),   % do booleans first (smaller domains)
     $int_enumerateff_act(Ns,Exec_on_Backtrack),
     $real_enumerate(Rs).

% classify the variables by type
$classify_intervals( [], [], [], [] ).
$classify_intervals( [X,Xs..], Bs, Is, Rs ):- nonvar(X),!,
    $classify_intervals( Xs, Bs, Is, Rs ).
$classify_intervals( [X,Xs..], Bs, Is, Rs ):-domain(X, T(_..)),  % Jan 95
    $classify_intervals_app(T, X, Xs, Bs, Is, Rs ).
$classify_intervals_app(integer, X, Xs, Bs,[X,Is..], Rs ):- !,
     $classify_intervals(Xs,Bs,Is,Rs).
$classify_intervals_app(boolean, X, Xs, [X,Bs..],Is, Rs ):- !,
     $classify_intervals(Xs,Bs,Is,Rs).
$classify_intervals_app(real, X, Xs, Bs,Is, [X,Rs..] ):- !,
     $classify_intervals(Xs,Bs,Is,Rs).

$real_enumerate([]):-!.
$real_enumerate( X ):- solve(X).

% C stands for code/counter to be executed on backtracking

$bool_enumerate([]):-!.
$bool_enumerate([X,Xs..]):- $boolean_generator(X), $bool_enumerate(Xs).

$bool_enumerate_act([],_):-!.
$bool_enumerate_act([X,Xs..],C):- $boolean_gen_act(X,C), 
               $bool_enumerate_act(Xs,C).

$int_enumerate([]):-!.
$int_enumerate([X,Xs..]):- $integer_generator(X), $int_enumerate(Xs).

$int_enumerate_act([],_):-!.
$int_enumerate_act([X,Xs..],C):- $integer_generator_act(X,C), 
               $int_enumerate_act(Xs,C).

% generators
$boolean_generator(B):- $iterate($equal(B,0,nil)).
$boolean_generator(B):- $iterate($equal(B,1,nil)).

$boolean_gen_act(B,_):- integer(B),!.
$boolean_gen_act(B,_):- $iterate($equal(B,0,nil)).
$boolean_gen_act(B,C):- C, $iterate($equal(B,1,nil)) .

$integer_generator(X):- integer(X),!.   
$integer_generator(X):- domain(X,_(L,_)), L1 is round(L),  % Jan 95
		$int_choice(X,L1).
$int_choice(X,L):- $iterate($equal(X,L,nil)).
$int_choice(X,L):-
		   $iterate($unequal(X,L,nil)),
           $integer_generator(X).

$integer_generator_act(X,_):- integer(X),!.  
$integer_generator_act(X,C):- domain(X,_(L,_)), L1 is round(L),
		$int_choice_act(X,L1,C).
$int_choice_act(X,L,_):- $iterate($equal(X,L,nil)).
$int_choice_act(X,L,C):-
           C,
		   $iterate($unequal(X,L,nil)),
           $integer_generator_act(X,C).

%  first fail  - find smallest non-zero range for candidate for enumeration
$int_enumerateff([]):-!.
$int_enumerateff(List):- M is maxreal,
	$smallest_range(List,List2,0,M,X),	!,
	$integer_generator(X), 
	$int_enumerateff(List2).

$int_enumerateff_act([],_):-!.
$int_enumerateff_act(List,C):- M is maxreal,
	$smallest_range(List,List2,0,M,X),!,
	$integer_generator_act(X,C), 
	$int_enumerateff_act(List2,C).

$smallest_range([],  [],   X,R, X):-!.   % need cut in case list is indefinite
$smallest_range([X,Xs..],Ys,Y,R, Cand):- nonvar(X),!, % drop from list when bound
		$smallest_range(Xs,Ys,Y,R,Cand).    
	% note: since most enumeration time is spent in endgame where bound values are common
	%  we expect it is better if this clause is done before the next one
$smallest_range([X,Xs..],[X,Ys..],Y,R, Cand):-
		 domain(X,T(L,U)), RX is U - L,
		 $smaller_range( R,RX, Y, X, MR, MX),!,
		 $smallest_range( Xs,Ys,MX,MR, Cand).   
$smaller_range( R1,R2, X1,X2, R1,X1):- R1=<R2.
$smaller_range( R1,R2, X1,X2, R2,X2). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                   solve( X)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Note: solve(X) is intended only for cases where a fixed point is a join of
%  several smaller fix points, e.g. "points".  If a point in the middle of the 
%  interval  ( e.g. median or midpoint) can be found which is not a solution, the
%  problem can be decomposed into two smaller problems. This is applied recursively
%  until the interval becomes pointliike, the depth of recursion is exceeded,
%  or no split point can be found.
   
solve(X):- solve(X,6,0.0001).		% upto 2**6 solutions

solve( X, _, RelErr  ):- $pointlike(X, RelErr),!. % bound or very small intervals
solve( X, N, RelErr ) :- var(X),!,$interval_type(X,_), N>=0, D is delta(X),
	Eps is min( 1.0e-100,  RelErr * D),
	$solve(N,X,Eps). 
solve( [], _,  _ ).
solve( [L..], N, RelErr ) :-
	$interval_list(L,Xs),
	N>0,
	[$widest( Xs, X), not( $pointlike(X, RelErr))] 
	->[	Eps is min( 1.0e-100,  RelErr * delta(X)),!,
%			predicate(trace_solve) -> [nl, write( multisolve(N,Xs,Eps))],
		$multi_solve( N,Xs, Eps)
	  ].

$interval_list([], []).
$interval_list([X,Xs..], [X,Ys..]):- $interval_type(X,_),!,$interval_list(Xs,Ys).
$interval_list([_,Xs..], Ys ):-$interval_list(Xs,Ys).

$pointlike( X, _) :- numeric(X),!.
$pointlike( X, RelErr) :- delta(X) < (RelErr * midpoint(X)).  
		% consider a point if bounds agree to so many digits
$pointlike( X ):- $pointlike( X, 1.0e-6).
%
%		multi_solve( List ,N, Eps)
%
$multi_solve(0, List,  Eps):- !.
$multi_solve(N, List,  Eps):-
	$widest( List, X),!,
	$multi_solve1( List, X,  Eps,N).

$multi_solve1( List, X,  Eps, N ):- $pointlike(X, Eps),!.
$multi_solve1( List, X,  Eps, N ):- N1 is N - 1,
	$solve(1, X, Eps),
	$multi_solve( N1, List,  Eps).

$widest([X,Xs..], W):- $widest1(Xs, X, W).
$widest1([],  W,  W).
$widest1([X,Xs..], Y, W):- $wider(X,Y),!, $widest1(Xs,X,W).
$widest1([X,Xs..], Y, W):- $widest1(Xs,Y,W).
$wider( X,Y):- Dx is delta(X), Dy is delta(Y), Dx>Dy.

$solve(N,X,Eps):- 0 < N ,  % split if possible
		N1 is N - 1, 
		$choose_split(X, M, Eps),!,
		predicate(trace_solve) -> [nl, write(N, 'split ',X,' at ',M)],
%		X =< M ; X >= M,      % replaced Jan 94
        $iterate( $greatereq(M,X,nil) ) ; $iterate( $greatereq(X,M,nil)),
		$solve(N1,X,Eps).

$solve(N,X,Eps).  	% N=0,too small, or no suitable split point found

$choose_split(X,M, RelErr):-   % fails if too small or not splittable
		domain(X,_(L,U)), 
		$median(L,U,M),
		(U - L)  >  RelErr * M,  % pointlike
		not( $iterate( $equal(X,M,nil) ) ), !.  % Jan 1995
										   % replaces % not({X==M}),!.  


$median( L, U, 0  ):- L<0,U>0.
$median( L, U, 1  ):- L<1.0,U>1.0.
$median( L, U, -1 ):- L< -1.0,U> -1.0.
$median( L, U,  M ):- L==0.0, M is U/3.0 .
$median( L, U,  M ):- U==0.0, M is L/3.0 .
$median( L, U,  M ):- L>0,U>0,  M is sqrt(L)*sqrt(U).
$median( L, U,  M ):- L<0,U<0,  M is -sqrt(-L)*sqrt(-U).
$median( L, U,  M ):- M is (L+U)/2.0 .   % default to midpoint

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%					absolve( X )  
%					absolve( X, Precision)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  absolve( X ), for X an interval or list of intervals, is intended 
%  solely to trim up the boundaries of what is essentially a single
%  (non-point)  solution to a problem. Hence absolve- unlike the rest
%  of the solve family -  is deterministic!
%	 The strategy used in absolve( derived from the old V 3 solve) is to 
%  work in from the edges of the interval ("nibbling away") until you
%  cannot go nay farther, then reduce step size and resume nibbling.
%  Control parameters limit the number of successive halvings of the 
%  step size, which is initially the interval width. 
%  		Note that absolve and solve each abstract a different part of
%  of the strategy used in the solve in BNRP V. 3. In this sense, the
%  combination: " solve(X), absolve(X) "  { in that order } does something
%  like what "solve(X)"did under the old system.


absolve( X ):- absolve(X,14).

absolve( X , Limit ):-
        domain(X, _(L, U)),!,	% nl,write( absolve,':'), print(X),
        Delta is delta(X)/2,
        $absolve_l(X,Delta,L,1,Limit),!,
        $absolve_r(X,Delta,U,1,Limit),!.

absolve( [], _).		% extends to lists
absolve( [X,Xs..],Lim):- absolve(X,Lim),!, absolve(Xs,Lim).

$absolve_l(X, DL, LB, NL, Limit) :- 
		not(not(lower_bound(X))),	% changed 93/06/01 WJO to avoid getting stuck on lower bound
		!.
$absolve_l(X, DL,LB, NL,Limit):- NL<Limit, % work on left side
        not( $pointlike( X ) ),   % added Jan 94
        $trim_point(NL,NL1,Limit, DL,DL1),
		domain(X, _(LB2, UB2)),
        Split is LB + DL1,  
		Split > LB2, Split < UB2,	% changed 93/06/01 WJO make sure that the interval can be split
        not( { X=<Split}),!,  % so X must be > split Jan 1995
        {X >= Split},
        domain(X, _(LB1, U)),!,  %  nl, print(X)
        $absolve_l(X, DL1, LB1,NL1,Limit).
$absolve_l(_, _, _,  _,_).
         
$absolve_r(X, DU, UB, NU, Limit) :-
		not(not(upper_bound(X))),	% changed 93/06/01 WJO to avoid getting stuck on upper bound
		!.
$absolve_r(X, DU,UB, NU,Limit):- NU<Limit, % work on right side
        not( $pointlike( X ) ),
        $trim_point(NU,NU1,Limit, DU,DU1),
		domain(X, _(LB2, UB2)),
        Split is UB - DU1,  
		Split > LB2, Split < UB2,	% changed 93/06/01 WJO make sure that the interval can be split
        not(  {X>=Split}),!,       % so X must be > split
        {X =< Split},
        domain(X, _(_, UB1) ),!,  % nl, print(X), 
        $absolve_r(X, DU1,UB1, NU1,Limit). 
$absolve_r(_, _, _,  _,_).

$trim_point( N,N, Limit, Delta, Delta).
$trim_point( N,M, Limit, Delta, Result):- N<Limit,N1 is N + 1,
       D is  Delta/2,
       $trim_point(N1,M,Limit,D, Result).
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   			side effect operations
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%		( these all use $replace_float(Old,New)
%		which overwrites an old float without trailing )
% Jan 95  $$dom added to deal with freeze constraints possibility
%   can NOT use domain because it copies the bounds and we need the originals here

$$dom( D, D):- structure(D),!.      % just interval constraints?
$$dom([D,_..], D):- structure(D).  % freeze constraints also

set_lower_bound(X, B) :-
		numeric(B),
		B1 is float(B),
		$domain(X,D),
		$$dom(D,T(_,_,L,U)), % not valid on booleans- changed 23/01/95
		$$interval_type(T,_),
		B1 =< U, 
		B1 > L -> $replace_float(L, B1).
set_upper_bound(X, B) :- 
		numeric(B),
		B1 is float(B),
        $domain(X,D),
		$$dom(D,T(_,_,L,U)), % not valid on booleans- changed 23/01/95
		$$interval_type(T,_),
        L =< B1, 
		B1 < U -> $replace_float(U, B1).

% accumulate is very dirty side-effect operation for backwards compatibility
% it should be eliminated entirely in favor of its most useful corollaries:
%  scan and integrate  (as described in User Guide)
accumulate( X, Y ):- 
		$domain( X,D),
		$$dom(D, T(_,_,LX,UX)),% make sure X is an interval- changed Jan 23 95
		$$interval_type(T,_),
		!, 
		{Z is X + Y},	 % note: won't work if X becomes bound !! Jan 1995
		domain( Z, _(LZ,UZ)),
		$replace_float( LX,LZ),
		$replace_float( UX,UZ).

/*  removed Jan 1995  - move into constraint utility file
%       card( N, Blist, M)  :- cardinality predicate
%        where N,M are interval variables/expressions
%              and Blist is a list of boolean interval variables/expressions
%        imposes constraint   N=< sum(Blist) =< M

card( NE, Blist, ME):-
     N is NE,
     M is ME,
     $sum_bool_list(Blist,0, Sum),
     N =< Sum, Sum =< M.

$sum_bool_list([],Sum, Sum).
$sum_bool_list([BE,Bs..], S1, Sum):-
     B is BE, domain(B, boolean(_,_)),
     S := S1 + B,
     $sum_bool_list( Bs,S,Sum).


end removal */
%
%   interval_control(  Max_ops, Inc, Dec )
%     gets/sets parameters that control interval iteration
%       Max_ops is initial allocation of ops permitted on each entry
%       Inc     is the amount added to opcount for each new node visited
%       Dec     is the amount subtracted from opcount for each node revisited
%       Iteration breaks off when opcount goes 0 or negative
%   Note:  Max_ops >0, Inc=Dec= 0  gives iteration to fixed point always
%          Max_ops >0, Inc=0 Dec=1 gives simple maximum opcount per iteration
%          Max_ops >0, Inc=n, Dec=1 permits roughly n periods over whole of visited space
%   default: interval_control(1000, 8, 1). 

interval_control( Max_Op, Inc, Dec) :- $intervalcontrol(Max_Op,Inc,Dec).

%  operations used in interval arithmetic networks

/* list of internal primitives for reference 
% note: first character of the name (after $) is used as discriminant
$interval_op( '+',        $add,        3).  % a
$interval_op( begin_tog,  $begin_tog,  2).  % b
$interval_op(  cos,       $cos,        2).  % c
%  $interval_op( integer,    $diophantine,1).  % d  removed Nov 93
$interval_op( '==',       $equal,      2).  % e
$interval_op( end_tog,    $finish_tog, 2).  % f
$interval_op( '>=',       $greatereq,  2).  % g
$interval_op( '>',        $higher,     2).  % h
$interval_op( min,        $inf,        3).  % i
$interval_op( '>=',       $j_less,     3).  % j
$interval_op( '==',       $k_equal,    2).  % k
$interval_op( max,        $lub,        3).  % l
$interval_op( '*',        $mul,        3).  % m
$interval_op( '<=',       $narrower,   2).  % m
$interval_op( ';', 		  $or,         3).  % o
$interval_op( '**',       $pow_odd,    3).  % p
$interval_op( '**',       $qpow_even,  3).  % q
$interval_op( sqrt,       $rootsquare, 2).  % r
$interval_op( sin,        $sin,        2).  % s
$interval_op( tan,        $tan,        2).  % t
$interval_op( '<>',       $unequal,    2).  % u
$interval_op( abs,        $vabs,       2).  % v
											% w
$interval_op( exp,        $xp,         2).  % x
$interval_op( d  ,        $ydelta,     3).  % y
											% z

new nodes added Nov 1993 to do boolean operations more efficiently:
(pure boolean operations functors start with $$...)
$interval_op( nand,       $$anynot,     3).  % a
$interval_op( nor,        $$butnot,     3).  % b
$interval_op( and,        $$conjunction,3).  % c
$interval_op( or,         $$disjunction,3).  % d
$interval_op( xor,        $$exor,       3).  % e
$interval_op( '~',        $$falseimplied,2). % f

*/


