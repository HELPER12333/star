/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2008 Tord Romstad (Glaurung author)
  Copyright (C) 2008-2014 Marco Costalba, Joona Kiiski, Tord Romstad

  Stockfish is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Stockfish is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  This file is based on original code written and dedicated to
  the public domain by Sebastiano Vigna (2014).
    <http://xorshift.di.unimi.it/xorshift64star.c>
*/

#ifndef PRNG_H_INCLUDED
#define PRNG_H_INCLUDED

#include "types.h"

/// xorshift64star Pseudo-Random Number Generator
/// This generator has the following characteristics:
///  -  It outputs 64-bit numbers
///  -  Passes Dieharder and SmallCrush test batteries
///  -  Does not require warm-up, no zeroland to escape
///  -  Internal state is a single 64-bit integer
///  -  Period is 2^64 - 1
///  -  Speed: 1.60 ns/call (Core i7 @3.40GHz)
/// For further analysis see
///   <http://vigna.di.unimi.it/ftp/papers/xorshift.pdf>

class PRNG {

  uint64_t x;

  uint64_t rand64() {
    x^=x>>12; x^=x<<25; x^=x>>27;
    return x * 2685821657736338717LL;
  }

public:
  PRNG(uint64_t seed) : x(seed) { assert(seed); }

  template<typename T> T rand() { return T(rand64()); }

  /// Special generator used to fast init magic numbers.
  /// Output values only have 1/8th of their bits set on average.
  template<typename T> T sparse_rand() { return T(rand64() & rand64() & rand64()); }
};

#endif // #ifndef PRNG_H_INCLUDED
