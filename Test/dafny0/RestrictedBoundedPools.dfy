// RUN: %dafny /compile:0 /dprint:"%t.dprint" "%s" > "%t"
// RUN: %diff "%s.expect" "%t"

module Methods_EverythingGoes {
  predicate R<Y>(y: Y) { true }

  type Opaque(==)

  class Cell {
    var data: int
  }
  
  datatype List<G> = Nil | Cons(G, List<G>)

  method M0()
    requires forall x: Opaque :: R(x)  // error: may seem innocent enough, but it quantifies over all Opauqe

  method E0()
    requires exists x: Opaque :: R(x)  // error: may seem innocent enough, but it quantifies over all Opauqe

  method M1<X>()
    requires forall x: X :: R(x)  // error: may seem innocent enough, but it quantifies over all X

  method E1<X>()
    requires exists x: X :: R(x)  // error: may seem innocent enough, but it quantifies over all X

  method M2()
    requires forall c: Cell :: R(c)  // error: quantifies over all references

  method M2'(S: set<Cell>)
    requires forall c: Cell :: c in S ==> R(c)  // fine

  method M3()
    requires forall xs: List<nat> :: R(xs)  // fine (no issues of allocation here)

  method M4()
    requires forall xs: List<Cell> :: R(xs)  // error: involves references

  method M4'(S: set<List<Cell>>)
    requires forall xs: List<Cell> :: xs in S ==> R(xs)  // fine

  method M5<H>()
    requires forall xs: List<H> :: R(xs)  // error: may involved allocation state

  method M5'<H(==)>(S: set<List<H>>)
    requires forall xs: List<H> :: xs in S ==> R(xs)  // fine

  method M6()
    requires forall xs: List<Opaque> :: R(xs)  // error: may involved allocation state

  method M6'(S: set<List<Opaque>>)
    requires forall xs: List<Opaque> :: xs in S ==> R(xs)  // fine
}

module Functions_RestrictionsApply {
  predicate R<Y>(y: Y) { true }

  type Opaque(==)

  class Cell {
    var data: int
  }
  
  datatype List<G> = Nil | Cons(G, List<G>)

  predicate M0()
  {
    forall x: Opaque :: R(x)  // error: may seem innocent enough, but it quantifies over all Opauqe
  }
  
  predicate E0()
  {
    exists x: Opaque :: R(x)  // error: may seem innocent enough, but it quantifies over all Opauqe
  }

  predicate M1<X>()
  {
    forall x: X :: R(x)  // error: may seem innocent enough, but it quantifies over all X
  }

  predicate E1<X>()
  {
    exists x: X :: R(x)  // error: may seem innocent enough, but it quantifies over all X
  }

  predicate M2()
  {
    forall c: Cell :: R(c)  // error: quantifies over all references
  }

  predicate M2'(S: set<Cell>)
  {
    forall c: Cell :: c in S ==> R(c)  // fine
  }

  predicate M3()
  {
    forall xs: List<nat> :: R(xs)  // fine (no issues of allocation here)
  }

  predicate M4()
  {
    forall xs: List<Cell> :: R(xs)  // error: involves references
  }

  predicate M4'(S: set<List<Cell>>)
  {
    forall xs: List<Cell> :: xs in S ==> R(xs)  // fine
  }

  predicate M5<H>()
  {
    forall xs: List<H> :: R(xs)  // error: may involved allocation state
  }

  predicate M5'<H(==)>(S: set<List<H>>)
  {
    forall xs: List<H> :: xs in S ==> R(xs)  // fine
  }

  predicate M6()
  {
    forall xs: List<Opaque> :: R(xs)  // error: may involved allocation state
  }

  predicate M6'(S: set<List<Opaque>>)
  {
    forall xs: List<Opaque> :: xs in S ==> R(xs)  // fine
  }
}

module OtherComprehensions {
  predicate R<Y>(y: Y) { true }
  
  type Opaque(==)

  class Cell {
    var data: int
  }

  datatype List<G> = Nil | Cons(G, List<G>)

  method M0() {
    assert {} == set o: Opaque | R(o);  // error: may be infinite
  }

  method M1() {
    assert iset{} == iset o: Opaque | R(o);
  }

  method M2() returns (s: iset<Opaque>) {
    s := iset o: Opaque | R(o);  // error: not compilable, for may be infinite
  }

  function F0(): int
    requires iset{} == iset o: Opaque | R(o)  // error: may involve references
  {
    15
  }

  function F1(): int
    requires iset{} == iset n: nat | R(n)  // fine
  {
    15
  }

  function F2<G>(): int
    requires iset{} == iset xs: List<G> | R(xs)  // error: may involve references
  {
    15
  }

  function H0<G>(): (s: iset<List<G>>)
    ensures s == iset xs: List<G> | R(xs)  // error: may involve references (hmm, could this be allowed?)
  {
    iset{}
  }

  function K0<G>(c: Cell): int
    reads if iset{} == iset xs: List<G> | R(xs) then {c} else {}  // error: may involve references
  {
    15
  }
}

module Allocated {
  class Cell {
    var data: int
  }

  method M0() {
    assert forall c: Cell :: c != null ==> c.data < 100;
  }

  method M1() {
    assert forall c: Cell :: c != null && allocated(c) ==> c.data < 100;
  }
  
  method N0() returns (s: set<Cell>) {
    s := set c: Cell | c != null && c.data < 100;  // error: this involves the allocated state
  }

  method N1() returns (s: set<Cell>) {
    s := set c: Cell | c != null && allocated(c) && c.data < 100;  // error: finite, but not (comfortably) compilable
  }

  ghost method N2() returns (s: set<Cell>) {
    s := set c: Cell | c != null && allocated(c) && c.data < 100;  // fine: this is finite and need not be compiled
  }

  function F(): set<Cell> {
    set c: Cell | c != null && allocated(c) && c.data < 100  // error: function not allowed to depend on allocation state
  }

  function A(c: Cell): bool
  {
    allocated(c)  // error: function not allowed to depend on allocation state
  }

  twostate function TS0(c: Cell, new d: Cell): bool
  {
    allocated(c)  // this is always true
  }

  twostate function TS1(c: Cell, new d: Cell): bool
  {
    allocated(d)  // this is always true
  }

  twostate function TS2(c: Cell, new d: Cell): bool
  {
    old(allocated(d))  // this value depends on the pre-state, but it's allowed in any case
  }

  twostate function TS3(c: Cell, new d: Cell): bool
  {
    fresh(d)  // this value depends on the pre-state, but it's allowed in any case
  }
}