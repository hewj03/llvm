//==------- block_load_usm_pvc.cpp - DPC++ ESIMD on-device test ------------==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// REQUIRES: gpu-intel-pvc

// RUN: %{build} -o %t.out
// RUN: %{run} %t.out

// The test verifies esimd::block_load() functions accepting USM pointer
// and optional compile-time esimd::properties.
// The block_load() calls in this test can use mask and cache-hint
// properties which require PVC+ target device.

#include "Inputs/block_load.hpp"

int main() {
  auto Q = queue{gpu_selector_v};
  esimd_test::printTestLabel(Q);

  constexpr bool TestPVCFeatures = true;
  bool Passed = true;

  Passed &= testUSM<int8_t, TestPVCFeatures>(Q);
  Passed &= testUSM<int16_t, TestPVCFeatures>(Q);
  if (Q.get_device().has(sycl::aspect::fp16))
    Passed &= testUSM<sycl::half, TestPVCFeatures>(Q);
  Passed &= testUSM<uint32_t, TestPVCFeatures>(Q);
  Passed &= testUSM<float, TestPVCFeatures>(Q);
  Passed &=
      testUSM<ext::intel::experimental::esimd::tfloat32, TestPVCFeatures>(Q);
  Passed &= testUSM<int64_t, TestPVCFeatures>(Q);
  if (Q.get_device().has(sycl::aspect::fp64))
    Passed &= testUSM<double, TestPVCFeatures>(Q);

  std::cout << (Passed ? "Passed\n" : "FAILED\n");
  return Passed ? 0 : 1;
}
