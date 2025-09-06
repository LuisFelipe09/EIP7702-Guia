# Batcher — Tutorial práctico

Este tutorial explica, paso a paso y de forma práctica, cómo funciona el ejemplo `Batcher` de este repositorio y qué cambia cuando usamos la delegación EIP‑7702 frente al flujo tradicional (sin EIP).

Dirigido a: desarrolladores que quieren entender el patrón "approve + acción" combinado en una sola ejecución atómica y cómo la delegación (EIP‑7702) mejora la UX.

Archivos clave
- `packages/foundry/contracts/Batcher.sol` — contrato que aprueba y luego ejecuta una llamada objetivo.
- `packages/foundry/contracts/Dapp.sol` — receptor que implementa `depositFrom(from, token, amount)`.
- `packages/foundry/contracts/MockERC20.sol` — token de pruebas (estilo OpenZeppelin en este repo).
- `packages/foundry/test/Batcher.t.sol` — test que demuestra el flujo con Foundry.

Objetivo del ejemplo
- Mostrar cómo combinar `approve(token, dapp, amount)` y la llamada a `dapp` en una sola ejecución desde la EOA delegada.
- Comparar con el flujo tradicional donde el usuario hace dos transacciones separadas: `approve` y luego `deposit`.

Entendiendo el problema (sin EIP)
1) Flujo clásico (sin delegación):
  - El usuario A envía una tx: `token.approve(dapp, amount)`.
  - Espera que la tx mine.
  - Luego el usuario A (o la dApp actuando por A) envía otra tx: `dapp.deposit(token, amount)` que hace `transferFrom(A, dapp, amount)`.

Problemas del flujo clásico:
- Dos transacciones = peor UX (dos confirmaciones en la wallet).
- Mayor exposición a front‑running y race conditions mientras la allowance está activa.
- Más tarifas de gas.

Cómo lo resuelve EIP‑7702 (en este ejemplo)
- EIP‑7702 permite que una EOA establezca temporalmente/definitivamente código delegado para ejecutar acciones en su contexto.
- En los tests usamos `vm.signAndAttachDelegation(address(batcher), privateKey)` (Foundry) para simular que la EOA ha delegado al `Batcher`.
- Luego llamamos a `Batcher` a través de la dirección de la EOA (p. ej. `Batcher(BOB_ADDRESS).batchApproveAndDeposit(...)`). Como el código del `Batcher` se ejecuta con `msg.sender == BOB_ADDRESS`, el `approve` y la llamada al `dapp` actúan como si la EOA hubiese hecho ambas operaciones en una sola transacción.

Tutorial paso a paso (práctico)

Requisitos: Foundry instalado. Desde la raíz del repo:

```bash
cd packages/foundry
forge test -v
```

1) Preparar el escenario (ve el test `test/Batcher.t.sol`):
  - Se despliegan `MockERC20`, `Dapp` y `Batcher`.
  - Se hace `token.mint(BOB_ADDRESS, amount)` para darle saldo a Bob.

2) Simular delegación con Foundry:
  - `vm.signAndAttachDelegation(address(batcher), BOB_PK);`
  - Esto hace que la siguiente llamada desde `BOB_ADDRESS` se trate como EIP‑7702 delegada y utilice `batcher`.

3) Ejecutar el batch en una única llamada (como en `test`):

```solidity
vm.startPrank(BOB_ADDRESS);
Batcher(BOB_ADDRESS).batchApproveAndDeposit(address(token), address(dapp), amount);
vm.stopPrank();
```

4) ¿Qué ocurrió internamente?
  - `Batcher` ejecuta `approve(token, dapp, amount)` con `msg.sender == BOB_ADDRESS`.
  - Inmediatamente después `Batcher` llama a `dapp.depositFrom(BOB_ADDRESS, token, amount)`.
  - `dapp` realiza `transferFrom(BOB_ADDRESS, address(this), amount)` y recibe los tokens.
  - Todo en la misma ejecución: UX de una sola confirmación y atomicidad.

Comparación práctica: con y sin EIP

- Sin EIP (tradicional): dos txs separadas, allowance persistente entre ellas.
- Con EIP‑7702 (delegación): una sola ejecución atomiza approve + deposit; la EOA no necesita realizar dos firmas separadas.

Ventajas del enfoque con delegación
- Mejor UX (una sola firma/confirmación).
- Menos gas total (a veces) y menor latencia para el usuario final.
- Permite patrones avanzados (batching, patrocinio, desescalada de privilegios).

Riesgos y mitigaciones prácticas
- Replay y seguridad: en producción no confíes solo en `signAndAttachDelegation`—implementa nonces y validación de parámetros con firma (EIP‑712).
- Tokens incompatibles: usa adaptadores o `SafeERC20` si el token no retorna `bool`.
- Reentrancia: sigue checks‑effects‑interactions y considera `ReentrancyGuard` cuando llames a contratos externos.

Referencias en el repo
- `packages/foundry/test/Batcher.t.sol` — ejemplo ejecutable que reproduce este tutorial.
- `packages/foundry/contracts/Batcher.sol` — código del `Batcher`.
