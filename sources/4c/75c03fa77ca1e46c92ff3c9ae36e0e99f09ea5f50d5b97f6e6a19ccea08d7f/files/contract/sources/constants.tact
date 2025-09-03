//  SPDX-License-Identifier: MIT
//  Copyright © 2025 Rubeton Studio

const gasForBurn: Int = 6700;
const gasForTransfer: Int = 10500;
const minTonsForStorage: Int = ton("0.01"); // This should use https://github.com/tact-lang/tact/issues/2336 in the future
const Basechain: Int = 0;

// This is an approximate value. Real one must be less than this, and it is checked in tests.
const walletStateInitCells: Int = 30;
const walletStateInitBits: Int = 20000;



const op_stonfi_swap_ok: Int = 0xc64370e5;
const op_stonfi_swap: Int = 0x25938561;
const op_dedust_swap: Int = 0xE3A0D482;
const op_dedust_swap1: Int = 0x2E1CFA82;
const op_dedust_swap2: Int = 773651074;
const op_dedust_swap3: Int = 3818968194;
const op_dedust_swap4: Int = 260734629;
const op_dedust_swap5: Int = 3926267997;
