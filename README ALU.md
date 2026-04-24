# ALU Modular – Verilog Implementation
## Proiect Calculatoare Numerice

---

## Structura fișierelor

```
ALU_Project/
├── full_adder.v           # 1-bit Full Adder (bloc de bază)
├── adder_8bit.v           # 8-bit Ripple Carry Adder (din 8× full_adder)
├── subtractor_8bit.v      # 8-bit Subtractor  (A + ~B + 1, refolosește adder_8bit)
├── booth_multiplier.v     # Booth Radix-2 Multiplier (8×8→16 bit, signed)
│                          #   → folosește intern adder_8bit + subtractor_8bit
├── restoring_divider.v    # Restoring Division (8÷8, unsigned)
│                          #   → folosește intern adder_8bit + subtractor_8bit
├── control_unit.v         # FSM Control Unit
├── alu_top.v              # Top-level: integrează toate modulele
└── tb_alu_top.v           # Testbench complet
```

---

## Diagrama ierarhiei

```
alu_top
├── control_unit          (FSM)
├── adder_8bit            (ADD path)
│   └── full_adder ×8
├── subtractor_8bit       (SUB path)
│   └── adder_8bit
│       └── full_adder ×8
├── booth_multiplier      (MUL path, Booth Radix-2)
│   ├── adder_8bit        (P + M)
│   └── subtractor_8bit   (P - M)
└── restoring_divider_v2  (DIV path, Restoring)
    ├── subtractor_8bit   (R - D, trial subtraction)
    └── adder_8bit        (restore: R + D)
```

---

## Control Unit – FSM

### Intrări
| Semnal   | Descriere                                      |
|----------|------------------------------------------------|
| CLK      | Ceas                                           |
| RST      | Reset sincron                                  |
| START    | Puls pentru a porni o operație                 |
| OP[1:0]  | 00=ADD, 01=SUB, 10=MUL, 11=DIV                |
| MUL_RES  | DONE de la booth_multiplier                    |
| DIV_RES  | DONE de la restoring_divider                   |

### Ieșiri
| Semnal   | Descriere                                      |
|----------|------------------------------------------------|
| LOADX    | Încarcă operandul A în registrul intern        |
| LOADY    | Încarcă operandul B în registrul intern        |
| EN_SUM   | Activează adder-ul                             |
| EN_SUB   | Activează subtractor-ul                        |
| EN_MULT  | Pornește Booth multiplier-ul                   |
| EN_DIV   | Pornește Restoring divider-ul                  |
| DONE     | Puls: operația s-a terminat                    |

### Stările FSM
```
S_IDLE → S_LOAD → S_EXECUTE ─→ S_DONE          (ADD / SUB, 1 ciclu)
                              ─→ S_WAIT_MUL → S_DONE  (MUL, 8+ciclu)
                              ─→ S_WAIT_DIV → S_DONE  (DIV, 16+ciclu)
```

---

## Algoritmul Booth Radix-2

1. Inițializare: ACC = 0, Q = multiplicand, Q_prev = 0
2. La fiecare din cele 8 pași, examinăm (Q[0], Q_prev):
   - `01` → ACC = ACC + M  (folosind adder_8bit)
   - `10` → ACC = ACC - M  (folosind subtractor_8bit)
   - `00` / `11` → nicio operație
3. Shift aritmetic dreapta {ACC, Q, Q_prev}
4. Rezultat: {ACC[7:0], Q} → 16 biți

---

## Algoritmul Restoring Division

1. Inițializare: R = 0, Q_reg = dividend
2. La fiecare din cele 8 pași (2 faze pe ciclu):
   - **Faza shift**: {R, Q_reg} ← shift stânga cu 1
   - **Faza subtract**:
     - Trial: R ← R − Divisor  (subtractor_8bit)
     - Dacă R ≥ 0 (fără borrow): Q_reg[0] = 1
     - Dacă R < 0 (borrow): R ← R + Divisor (adder_8bit), Q_reg[0] = 0
3. Câtul = Q_reg, Restul = R

---

## Simulare

```bash
# Cu Icarus Verilog
iverilog -o alu_sim \
    full_adder.v adder_8bit.v subtractor_8bit.v \
    booth_multiplier.v restoring_divider.v \
    control_unit.v alu_top.v tb_alu_top.v
vvp alu_sim

# Vizualizare waveform
gtkwave tb_alu.vcd
```

---

## Codificarea OP

| OP[1:0] | Operație | Modul activat    |
|---------|----------|-----------------|
| 00      | A + B    | adder_8bit       |
| 01      | A − B    | subtractor_8bit  |
| 10      | A × B    | booth_multiplier |
| 11      | A ÷ B    | restoring_divider|
