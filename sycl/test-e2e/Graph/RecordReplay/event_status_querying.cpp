// RUN: %{build} -o %t.out
// RUN: %if ext_oneapi_level_zero || ext_oneapi_cuda %{ %{run} %t.out 2>&1 | FileCheck %s %} %else %{ %{run} %t.out %}
//
// CHECK: complete
//
// TODO enable cuda once buffer issue investigated and fixed
// UNSUPPORTED: cuda

#define GRAPH_E2E_RECORD_REPLAY

#include "../Inputs/event_status_querying.cpp"
