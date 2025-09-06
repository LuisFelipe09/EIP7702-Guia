# Sweeper — Tutorial práctico

Este tutorial explica de forma clara y práctica el ejemplo `Sweeper` incluido en `packages/foundry/contracts/Sweeper.sol`. Verás cómo funciona, cómo ejecutarlo localmente con Foundry, por qué funciona sin `approve` cuando se combina con la simulación de delegación (EIP‑7702) y qué riesgos tener en cuenta.

Contenido
- Contexto y objetivo
- Archivos relevantes
- Ejecución paso a paso (Foundry)
- ¿Por qué no necesita `approve` en este ejemplo?
- Diferencias con el flujo tradicional
- Riesgos y mitigaciones
- Ejemplos y ejercicios sugeridos

## Contexto y objetivo

`Sweeper` muestra un patrón práctico: "barrer" (sweep) varios tokens desde una EOA y enviarlos a uno o varios destinatarios en una única operación. Esto facilita tareas como consolidar saldos o migrar fondos.

En los tests del repo usamos la utilidad de Foundry `vm.signAndAttachDelegation` para simular EIP‑7702 — la delegación de ejecución hace que el código del `Sweeper` se ejecute en el contexto de la EOA, permitiendo llamadas directas a `transfer` que actúan como si las hiciera la EOA misma.

## Archivos relevantes

- `packages/foundry/contracts/Sweeper.sol` — implementación con:
  - `sweepTokens(address[] tokens, address to, uint256[] amounts)` — envía varios tokens a un único destinatario.
  - `sweepTokensToMany(address[] tokens, address[] tos, uint256[] amounts)` — envía cada token a su destinatario correspondiente.
- `packages/foundry/test/Sweeper.t.sol` — tests que muestran:
  - `testSweepMultipleTokens()` — sweeping a un único receptor.
  - `testSweepToMultipleDestinations()` — sweeping a múltiples destinos.

## Ejecución paso a paso (Foundry)

Requisitos: Foundry instalado.

1) Desde la raíz del repo:

```bash
cd packages/foundry
forge test -v
```

2) Estructura del test (resumen):
  - Se despliegan `MockERC20` (tokens de prueba) y se mintean fondos a `BOB_ADDRESS`.
  - Se despliega `Sweeper`.
  - `vm.signAndAttachDelegation(address(sweeper), BOB_PK);` simula que Bob delega ejecución al `Sweeper`.
  - Se hace la llamada desde la dirección EOA delegada:

```solidity
vm.startPrank(BOB_ADDRESS);
Sweeper(BOB_ADDRESS).sweepTokens(tokens, RECEIVER, amounts);
vm.stopPrank();
```

3) Validaciones en el test: comprobación de balances antes/después, y de que los `amounts` fueron transferidos.

## ¿Por qué no necesita `approve` en este ejemplo?

Normalmente, para que un contrato mueva tokens desde una EOA, la EOA debe dar `approve(spender, amount)` y el contrato hace `transferFrom`. En nuestro ejemplo la lógica es distinta:

- El `Sweeper` se ejecuta en el contexto de la EOA delegada (simulado por Foundry). Eso significa que dentro del `Sweeper` `msg.sender` es la EOA (Bob).
- Cuando `Sweeper` llama `IERC20(token).transfer(to, amount)`, la transferencia se ejecuta desde la cuenta que efectivamente tiene el balance (Bob), porque la EOA es el `msg.sender` para esa llamada.

En resumen: la delegación de ejecución permite que el contrato ejecute `transfer` como si fuese la cuenta que posee los tokens, evitando la necesidad de `approve` + `transferFrom`.

## Diferencias con el flujo tradicional (sin EIP‑7702)

- Sin delegación:
  - Usuario hace `approve(spender, amount)` (tx1).
  - Luego `spender`/dApp hace `transferFrom(user, to, amount)` (tx2).
  - Dos transacciones, más gas y peor UX.

- Con delegación (Sweeper + EIP‑7702 simulada):
  - Usuario autoriza ejecución del `Sweeper` (simulado en tests).
  - Una única ejecución realiza las transferencias directamente desde la EOA.
  - UX: una sola interacción; atomicidad.

Nota práctica: en producción EIP‑7702 introduce cambios de invariantes importantes (como se describe en la EIP); aquí solo mostramos un patrón de UX mejorado y sus riesgos.

## Riesgos y mitigaciones

- Confianza en el código delegado: si la EOA delega código malicioso, se pueden mover fondos. Mitigación: limitar delegaciones, usar validación de parámetros firmados, y auditoría del código delegado.
- Tokens no estándar: algunos tokens no devuelven `bool` en `transfer` — en prod usar `SafeERC20` o adaptadores.
- Gas: barrer muchos tokens o muchos destinos en una sola tx puede superar el gas límite; considera batching interno por tamaños y checks de gas.
- Reentrancia: aunque aquí el patrón es simple, si el Sweeper interactúa con contratos que llaman de vuelta, aplica `ReentrancyGuard` o patrones checks‑effects‑interactions.

## Ejemplos y variantes prácticas

- Variante firma‑basada: en lugar de delegación, se puede permitir que el usuario firme una orden (EIP‑712) que autorice al Sweeper a mover ciertos tokens; luego un relayer publica la tx. Esto añade control y revocabilidad por firmas.
- Límite por llamada: añade límites por token/EOA para prevenir extracción completa accidental.
