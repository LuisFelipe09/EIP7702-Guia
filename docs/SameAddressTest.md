
# Tutorial de Pruebas: SameAddress.t.sol y EIP-7702

Bienvenido a este tutorial, donde exploramos cómo funcionan las pruebas del contrato `SameAddress` y el mecanismo de delegación propuesto en EIP-7702, usando Foundry. Aquí aprenderás, paso a paso, qué ocurre en cada caso de prueba y por qué es relevante para la seguridad y la lógica de los smart contracts.

---

## Introducción: El escenario de Bob y Alice

Imagina dos cuentas: Bob y Alice. Bob es el propietario y Alice es quien intenta interactuar con el contrato bajo diferentes condiciones de delegación. El objetivo de las pruebas es verificar cómo responde el contrato ante estas situaciones y cómo la delegación afecta el resultado.

---

## ¿Qué es signAndAttachDelegation?

Antes de entrar en los casos, es clave entender la función `signAndAttachDelegation`. Esta herramienta de Foundry permite simular la delegación de permisos entre cuentas, siguiendo la propuesta EIP-7702. Así, una cuenta puede "autorizar" a otra para actuar en su nombre dentro de las pruebas.

**Ejemplo de uso:**
```solidity
vm.signAndAttachDelegation(address(sameAddress), BOB_PK);
```

---

## Casos de prueba explicados

### 1. testIsSameAddress
Bob delega correctamente y llama a la función `isSameAddress()` desde su propia dirección. El contrato reconoce a Bob como el dueño y devuelve `true`. Este caso demuestra el funcionamiento esperado de la delegación.

### 2. testDelegateCallIsSameAddress
Bob delega, pero ahora Alice intenta llamar a `isSameAddress()` usando la dirección de Bob como si fuera un contrato. El resultado es `false`, porque Alice no es Bob, aunque la dirección de Bob tiene código de contrato. Además, se verifica que la dirección de Bob corresponde efectivamente a un contrato desplegado.

### 3. testDelegateNotIsContract
Bob delega, y Alice intenta llamar a `isSameAddress()` usando su propia dirección como si fuera un contrato. Aquí se comprueba que la dirección de Alice no corresponde a un contrato (es una EOA, no tiene código), y el contrato lo detecta correctamente.

---

## Nota sobre la verificación de contratos

Al verificar si una dirección es un contrato, comprobamos que realmente esa cuenta se comporta como tal. Si la delegación no se realiza correctamente, Foundry genera un error indicando que la cuenta no es un contrato. Esta distinción entre EOA y contrato es fundamental, ya que afecta el resultado y el flujo de ejecución. Validar este comportamiento asegura que las pruebas reflejan escenarios reales de delegación y acceso en Ethereum.

---

## Reflexión: ¿Por qué el smart contract y la dirección de la cuenta pueden ser la misma?

En Ethereum, la dirección de un smart contract es única y corresponde al lugar donde el contrato fue desplegado. Cuando una cuenta (EOA) despliega un contrato, la dirección del contrato es distinta a la de la cuenta que lo creó. Sin embargo, en ciertos patrones de delegación y verificación, como los que se exploran en estas pruebas, el contrato y la cuenta pueden interactuar de forma que sus direcciones sean comparadas o tratadas como equivalentes en la lógica del negocio.

Esto ocurre, por ejemplo, cuando se busca validar que una acción proviene del propietario original o de una entidad delegada, y se compara la dirección que ejecuta la llamada con la dirección del contrato. Si la delegación está correctamente configurada, el contrato puede reconocer la cuenta como "la misma" para efectos de autorización o lógica interna. Este tipo de verificación es fundamental para garantizar la seguridad y la correcta gestión de permisos en aplicaciones descentralizadas.

---

## Resumen

Cada prueba simula un escenario diferente de delegación y verificación de direcciones, usando cuentas simuladas (Bob y Alice) para explorar el comportamiento del contrato. Así, se valida si una dirección es la misma, si corresponde a un contrato, o si es una EOA, y se entiende cómo la delegación afecta la lógica y la seguridad en Ethereum.

---

**Actualizado:** 25 de agosto de 2025
