! This test checks lowering of OpenACC parallel directive.

! RUN: bbc -fopenacc -emit-fir -hlfir=false %s -o - | FileCheck %s --check-prefixes=CHECK,FIR
! RUN: bbc -fopenacc -emit-hlfir %s -o - | FileCheck %s --check-prefixes=CHECK,HLFIR

! CHECK-LABEL: acc.firstprivate.recipe @firstprivatization_section_ext10xext10_ref_10x10xf32 : !fir.ref<!fir.array<10x10xf32>> init {
! CHECK: ^bb0(%{{.*}}: !fir.ref<!fir.array<10x10xf32>>):
! HLFIR:   %[[SHAPE:.*]] = fir.shape %{{.*}}, %{{.*}} : (index, index) -> !fir.shape<2>
! CHECK:   %[[ALLOCA:.*]] = fir.alloca !fir.array<10x10xf32>
! HLFIR:   %[[DECLARE:.*]]:2 = hlfir.declare %[[ALLOCA]](%[[SHAPE]]) {uniq_name = "acc.private.init"} : (!fir.ref<!fir.array<10x10xf32>>, !fir.shape<2>) -> (!fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>)
! HLFIR:   acc.yield %[[DECLARE]]#0 : !fir.ref<!fir.array<10x10xf32>>
! CHECK: } copy {
! CHECK: ^bb0(%arg0: !fir.ref<!fir.array<10x10xf32>>, %arg1: !fir.ref<!fir.array<10x10xf32>>):
! CHECK:   acc.terminator
! CHECK: }

! CHECK-LABEL: acc.private.recipe @privatization_ref_10x10xf32 : !fir.ref<!fir.array<10x10xf32>> init {
! CHECK: ^bb0(%{{.*}}: !fir.ref<!fir.array<10x10xf32>>):
! HLFIR:   %[[SHAPE:.*]] = fir.shape %{{.*}}, %{{.*}} : (index, index) -> !fir.shape<2>
! HLFIR:   %[[DECLARE:.*]]:2 = hlfir.declare %[[ALLOCA]](%[[SHAPE]]) {uniq_name = "acc.private.init"} : (!fir.ref<!fir.array<10x10xf32>>, !fir.shape<2>) -> (!fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>)
! HLFIR:   acc.yield %[[DECLARE]]#0 : !fir.ref<!fir.array<10x10xf32>>
! CHECK: }

! CHECK-LABEL: func.func @_QPacc_parallel()

subroutine acc_parallel
  integer :: i, j

  integer :: async = 1
  integer :: wait1 = 1
  integer :: wait2 = 2
  integer :: numGangs = 1
  integer :: numWorkers = 10
  integer :: vectorLength = 128
  logical :: ifCondition = .TRUE.
  real, dimension(10, 10) :: a, b, c
  real, pointer :: d, e
  integer :: reduction_i
  real :: reduction_r

!CHECK: %[[A:.*]] = fir.alloca !fir.array<10x10xf32> {{{.*}}uniq_name = "{{.*}}Ea"}
! HLFIR: %[[DECLA:.*]]:2 = hlfir.declare %[[A]]
!CHECK: %[[B:.*]] = fir.alloca !fir.array<10x10xf32> {{{.*}}uniq_name = "{{.*}}Eb"}
! HLFIR: %[[DECLB:.*]]:2 = hlfir.declare %[[B]]
!CHECK: %[[C:.*]] = fir.alloca !fir.array<10x10xf32> {{{.*}}uniq_name = "{{.*}}Ec"}
! HLFIR: %[[DECLC:.*]]:2 = hlfir.declare %[[C]]
!CHECK: %[[D:.*]] = fir.alloca !fir.box<!fir.ptr<f32>> {bindc_name = "d", uniq_name = "{{.*}}Ed"}
! HLFIR: %[[DECLD:.*]]:2 = hlfir.declare %[[D]]
!CHECK: %[[E:.*]] = fir.alloca !fir.box<!fir.ptr<f32>> {bindc_name = "e", uniq_name = "{{.*}}Ee"}
! HLFIR: %[[DECLE:.*]]:2 = hlfir.declare %[[E]]
!CHECK: %[[IFCONDITION:.*]] = fir.address_of(@{{.*}}ifcondition) : !fir.ref<!fir.logical<4>>
! HLFIR: %[[DECLIFCONDITION:.*]]:2 = hlfir.declare %[[IFCONDITION]]

  !$acc parallel
  !$acc end parallel

!CHECK:      acc.parallel {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel async
  !$acc end parallel

!CHECK:      acc.parallel {
!CHECK:        acc.yield
!CHECK-NEXT: } attributes {asyncAttr}

  !$acc parallel async(1)
  !$acc end parallel

!CHECK:      [[ASYNC1:%.*]] = arith.constant 1 : i32
!CHECK:      acc.parallel async([[ASYNC1]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel async(async)
  !$acc end parallel

!CHECK:      [[ASYNC2:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      acc.parallel async([[ASYNC2]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel wait
  !$acc end parallel

!CHECK:      acc.parallel {
!CHECK:        acc.yield
!CHECK-NEXT: } attributes {waitAttr}

  !$acc parallel wait(1)
  !$acc end parallel

!CHECK:      [[WAIT1:%.*]] = arith.constant 1 : i32
!CHECK:      acc.parallel wait([[WAIT1]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel wait(1, 2)
  !$acc end parallel

!CHECK:      [[WAIT2:%.*]] = arith.constant 1 : i32
!CHECK:      [[WAIT3:%.*]] = arith.constant 2 : i32
!CHECK:      acc.parallel wait([[WAIT2]], [[WAIT3]] : i32, i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel wait(wait1, wait2)
  !$acc end parallel

!CHECK:      [[WAIT4:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      [[WAIT5:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      acc.parallel wait([[WAIT4]], [[WAIT5]] : i32, i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel num_gangs(1)
  !$acc end parallel

!CHECK:      [[NUMGANGS1:%.*]] = arith.constant 1 : i32
!CHECK:      acc.parallel num_gangs([[NUMGANGS1]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel num_gangs(numGangs)
  !$acc end parallel

!CHECK:      [[NUMGANGS2:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      acc.parallel num_gangs([[NUMGANGS2]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel num_gangs(1, 1, 1)
  !$acc end parallel

!CHECK:      acc.parallel num_gangs(%{{.*}}, %{{.*}}, %{{.*}} : i32, i32, i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel num_workers(10)
  !$acc end parallel

!CHECK:      [[NUMWORKERS1:%.*]] = arith.constant 10 : i32
!CHECK:      acc.parallel num_workers([[NUMWORKERS1]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel num_workers(numWorkers)
  !$acc end parallel

!CHECK:      [[NUMWORKERS2:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      acc.parallel num_workers([[NUMWORKERS2]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel vector_length(128)
  !$acc end parallel

!CHECK:      [[VECTORLENGTH1:%.*]] = arith.constant 128 : i32
!CHECK:      acc.parallel vector_length([[VECTORLENGTH1]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel vector_length(vectorLength)
  !$acc end parallel

!CHECK:      [[VECTORLENGTH2:%.*]] = fir.load %{{.*}} : !fir.ref<i32>
!CHECK:      acc.parallel vector_length([[VECTORLENGTH2]] : i32) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel if(.TRUE.)
  !$acc end parallel

!CHECK:      [[IF1:%.*]] = arith.constant true
!CHECK:      acc.parallel if([[IF1]]) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel if(ifCondition)
  !$acc end parallel

!CHECK:      [[IFCOND:%.*]] = fir.load %{{.*}} : !fir.ref<!fir.logical<4>>
!CHECK:      [[IF2:%.*]] = fir.convert [[IFCOND]] : (!fir.logical<4>) -> i1
!CHECK:      acc.parallel if([[IF2]]) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel self(.TRUE.)
  !$acc end parallel

!CHECK:      [[SELF1:%.*]] = arith.constant true
!CHECK:      acc.parallel self([[SELF1]]) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel self
  !$acc end parallel

!CHECK:      acc.parallel {
!CHECK:        acc.yield
!CHECK-NEXT: } attributes {selfAttr}

  !$acc parallel self(ifCondition)
  !$acc end parallel

!FIR:        %[[SELF2:.*]] = fir.convert %[[IFCONDITION]] : (!fir.ref<!fir.logical<4>>) -> i1
!HLFIR:      %[[SELF2:.*]] = fir.convert %[[DECLIFCONDITION]]#1 : (!fir.ref<!fir.logical<4>>) -> i1
!CHECK:      acc.parallel self(%[[SELF2]]) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel copy(a, b, c)
  !$acc end parallel

!FIR:        %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
!HLFIR:      %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
!FIR:        %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!HLFIR:      %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!FIR:        %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "c"}
!HLFIR:      %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[COPYIN_A]], %[[COPYIN_B]], %[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!FIR:        acc.copyout accPtr(%[[COPYIN_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}
!FIR:        acc.copyout accPtr(%[[COPYIN_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "b"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "b"}
!FIR:        acc.copyout accPtr(%[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "c"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "c"}

  !$acc parallel copy(a) copy(b) copy(c)
  !$acc end parallel

!FIR:        %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
!HLFIR:      %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
!FIR:        %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!HLFIR:      %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!FIR:        %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "c"}
!HLFIR:      %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[COPYIN_A]], %[[COPYIN_B]], %[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!FIR:        acc.copyout accPtr(%[[COPYIN_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}
!FIR:        acc.copyout accPtr(%[[COPYIN_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "b"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "b"}
!FIR:        acc.copyout accPtr(%[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "c"}
!HLFIR:      acc.copyout accPtr(%[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) {dataClause = #acc<data_clause acc_copy>, name = "c"}

  !$acc parallel copyin(a) copyin(readonly: b, c)
  !$acc end parallel

!FIR:        %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR:      %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!FIR:        %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "b"}
!HLFIR:      %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "b"}
!FIR:        %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "c"}
!HLFIR:      %[[COPYIN_C:.*]] = acc.copyin varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[COPYIN_A]], %[[COPYIN_B]], %[[COPYIN_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel copyout(a) copyout(zero: b) copyout(c)
  !$acc end parallel

!FIR:   %[[CREATE_A:.*]] = acc.create varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "a"}
!HLFIR: %[[CREATE_A:.*]] = acc.create varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "a"}
!FIR:   %[[CREATE_B:.*]] = acc.create varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "b"}
!HLFIR: %[[CREATE_B:.*]] = acc.create varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "b"}
!FIR:   %[[CREATE_C:.*]] = acc.create varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "c"}
!HLFIR: %[[CREATE_C:.*]] = acc.create varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copyout>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[CREATE_A]], %[[CREATE_B]], %[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!FIR:   acc.copyout accPtr(%[[CREATE_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) {name = "a"}
!HLFIR: acc.copyout accPtr(%[[CREATE_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) {name = "a"}
!FIR:   acc.copyout accPtr(%[[CREATE_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) {name = "b"}
!HLFIR: acc.copyout accPtr(%[[CREATE_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) {name = "b"}
!FIR:   acc.copyout accPtr(%[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) {name = "c"}
!HLFIR: acc.copyout accPtr(%[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) to varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) {name = "c"}

  !$acc parallel create(a, b) create(zero: c)
  !$acc end parallel

!FIR:   %[[CREATE_A:.*]] = acc.create varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR: %[[CREATE_A:.*]] = acc.create varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!FIR:   %[[CREATE_B:.*]] = acc.create varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!HLFIR: %[[CREATE_B:.*]] = acc.create varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!FIR:   %[[CREATE_C:.*]] = acc.create varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_create_zero>, name = "c"}
!HLFIR: %[[CREATE_C:.*]] = acc.create varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_create_zero>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[CREATE_A]], %[[CREATE_B]], %[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!CHECK: acc.delete accPtr(%[[CREATE_A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) {dataClause = #acc<data_clause acc_create>, name = "a"}
!CHECK: acc.delete accPtr(%[[CREATE_B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) {dataClause = #acc<data_clause acc_create>, name = "b"}
!CHECK: acc.delete accPtr(%[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) {dataClause = #acc<data_clause acc_create_zero>, name = "c"}

  !$acc parallel create(c) copy(b) create(a)
  !$acc end parallel
!FIR:   %[[CREATE_C:.*]] = acc.create varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!HLFIR: %[[CREATE_C:.*]] = acc.create varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!FIR:   %[[COPY_B:.*]] = acc.copyin varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!HLFIR: %[[COPY_B:.*]] = acc.copyin varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_copy>, name = "b"}
!FIR:   %[[CREATE_A:.*]] = acc.create varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR: %[[CREATE_A:.*]] = acc.create varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!CHECK: acc.parallel   dataOperands(%[[CREATE_C]], %[[COPY_B]], %[[CREATE_A]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {

  !$acc parallel no_create(a, b) create(zero: c)
  !$acc end parallel

!FIR:   %[[NO_CREATE_A:.*]] = acc.nocreate varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR: %[[NO_CREATE_A:.*]] = acc.nocreate varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!FIR:   %[[NO_CREATE_B:.*]] = acc.nocreate varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!HLFIR: %[[NO_CREATE_B:.*]] = acc.nocreate varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!FIR:   %[[CREATE_C:.*]] = acc.create varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_create_zero>, name = "c"}
!HLFIR: %[[CREATE_C:.*]] = acc.create varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {dataClause = #acc<data_clause acc_create_zero>, name = "c"}
!CHECK:      acc.parallel dataOperands(%[[NO_CREATE_A]], %[[NO_CREATE_B]], %[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!CHECK: acc.delete accPtr(%[[CREATE_C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) {dataClause = #acc<data_clause acc_create_zero>, name = "c"}


  !$acc parallel present(a, b, c)
  !$acc end parallel

!FIR:   %[[PRESENT_A:.*]] = acc.present varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR: %[[PRESENT_A:.*]] = acc.present varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!FIR:   %[[PRESENT_B:.*]] = acc.present varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!HLFIR: %[[PRESENT_B:.*]] = acc.present varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
!FIR:   %[[PRESENT_C:.*]] = acc.present varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!HLFIR: %[[PRESENT_C:.*]] = acc.present varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!CHECK:      acc.parallel dataOperands(%[[PRESENT_A]], %[[PRESENT_B]], %[[PRESENT_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel deviceptr(a) deviceptr(c)
  !$acc end parallel

!FIR:   %[[DEVICEPTR_A:.*]] = acc.deviceptr varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!HLFIR: %[[DEVICEPTR_A:.*]] = acc.deviceptr varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
!FIR:   %[[DEVICEPTR_C:.*]] = acc.deviceptr varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!HLFIR: %[[DEVICEPTR_C:.*]] = acc.deviceptr varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
!CHECK:      acc.parallel dataOperands(%[[DEVICEPTR_A]], %[[DEVICEPTR_C]] : !fir.ref<!fir.array<10x10xf32>>, !fir.ref<!fir.array<10x10xf32>>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}

  !$acc parallel attach(d, e)
  !$acc end parallel

!FIR:   %[[BOX_D:.*]] = fir.load %[[D]] : !fir.ref<!fir.box<!fir.ptr<f32>>>
!HLFIR: %[[BOX_D:.*]] = fir.load %[[DECLD]]#1 : !fir.ref<!fir.box<!fir.ptr<f32>>>
!CHECK: %[[BOX_ADDR_D:.*]] = fir.box_addr %[[BOX_D]] : (!fir.box<!fir.ptr<f32>>) -> !fir.ptr<f32>
!CHECK: %[[ATTACH_D:.*]] = acc.attach varPtr(%[[BOX_ADDR_D]] : !fir.ptr<f32>) -> !fir.ptr<f32> {name = "d"}
!FIR:   %[[BOX_E:.*]] = fir.load %[[E]] : !fir.ref<!fir.box<!fir.ptr<f32>>>
!HLFIR: %[[BOX_E:.*]] = fir.load %[[DECLE]]#1 : !fir.ref<!fir.box<!fir.ptr<f32>>>
!CHECK: %[[BOX_ADDR_E:.*]] = fir.box_addr %[[BOX_E]] : (!fir.box<!fir.ptr<f32>>) -> !fir.ptr<f32>
!CHECK: %[[ATTACH_E:.*]] = acc.attach varPtr(%[[BOX_ADDR_E]] : !fir.ptr<f32>) -> !fir.ptr<f32> {name = "e"}
!CHECK: acc.parallel dataOperands(%[[ATTACH_D]], %[[ATTACH_E]] : !fir.ptr<f32>, !fir.ptr<f32>) {
!CHECK:        acc.yield
!CHECK-NEXT: }{{$}}
!CHECK: acc.detach accPtr(%[[ATTACH_D]] : !fir.ptr<f32>) {dataClause = #acc<data_clause acc_attach>, name = "d"}
!CHECK: acc.detach accPtr(%[[ATTACH_E]] : !fir.ptr<f32>) {dataClause = #acc<data_clause acc_attach>, name = "e"}

!$acc parallel private(a) firstprivate(b) private(c)
!$acc end parallel

! FIR:        %[[ACC_PRIVATE_A:.*]] = acc.private varPtr(%[[A]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
! HLFIR:      %[[ACC_PRIVATE_A:.*]] = acc.private varPtr(%[[DECLA]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "a"}
! FIR:        %[[ACC_FPRIVATE_B:.*]] = acc.firstprivate varPtr(%[[B]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
! HLFIR:      %[[ACC_FPRIVATE_B:.*]] = acc.firstprivate varPtr(%[[DECLB]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "b"}
! FIR:        %[[ACC_PRIVATE_C:.*]] = acc.private varPtr(%[[C]] : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
! HLFIR:      %[[ACC_PRIVATE_C:.*]] = acc.private varPtr(%[[DECLC]]#1 : !fir.ref<!fir.array<10x10xf32>>) bounds(%{{.*}}, %{{.*}}) -> !fir.ref<!fir.array<10x10xf32>> {name = "c"}
! CHECK:      acc.parallel firstprivate(@firstprivatization_section_ext10xext10_ref_10x10xf32 -> %[[ACC_FPRIVATE_B]] : !fir.ref<!fir.array<10x10xf32>>) private(@privatization_ref_10x10xf32 -> %[[ACC_PRIVATE_A]] : !fir.ref<!fir.array<10x10xf32>>, @privatization_ref_10x10xf32 -> %[[ACC_PRIVATE_C]] : !fir.ref<!fir.array<10x10xf32>>) {
! CHECK:        acc.yield
! CHECK-NEXT: }{{$}}

!$acc parallel reduction(+:reduction_r) reduction(*:reduction_i)
!$acc end parallel

! CHECK:      acc.parallel reduction(@reduction_add_ref_f32 -> %{{.*}} : !fir.ref<f32>, @reduction_mul_ref_i32 -> %{{.*}} : !fir.ref<i32>) {
! CHECK:        acc.yield
! CHECK-NEXT: }{{$}}

!$acc parallel default(none)
!$acc end parallel

! CHECK: acc.parallel {
! CHECK: } attributes {defaultAttr = #acc<defaultvalue none>}

!$acc parallel default(present)
!$acc end parallel

! CHECK: acc.parallel {
! CHECK: } attributes {defaultAttr = #acc<defaultvalue present>}

end subroutine acc_parallel
