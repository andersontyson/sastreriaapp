# Propuesta Técnica: Sistema de Gestión para Sastrería (Android Tablet)

## 1. Arquitectura General
Se propone una **Arquitectura Limpia (Clean Architecture)** dividida en tres capas principales para garantizar la escalabilidad, mantenibilidad y facilidad de prueba:

*   **Capa de Presentación (UI/UX):** Implementada con Flutter y Jetpack Compose (en el caso de Flutter) utilizando **Bloc/Cubit** para la gestión de estados. Esta capa es totalmente reactiva y responde a los cambios en los datos de forma inmediata.
*   **Capa de Dominio (Business Logic):** Contiene las entidades puras de negocio y los casos de uso. No depende de ninguna librería externa de persistencia o UI.
*   **Capa de Datos:** Maneja la persistencia local mediante **SQLite (sqflite)**. Implementa los repositorios definidos en la capa de dominio.

## 2. Propuesta de Tecnología
**Tecnología Elegida: Flutter**
*   **Razón:** Flutter permite un desarrollo rápido con una UI altamente personalizada y fluida. Su motor gráfico es ideal para tablets, permitiendo layouts adaptativos (Responsive) que aprovechan el espacio de pantalla de forma óptima.
*   **Persistencia:** `sqflite` (SQLite nativo) para garantizar robustez y velocidad en transacciones locales.

## 3. Modelo de Datos (Entidades)

### Sastre
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | UUID/String | Identificador único |
| `nombre` | String | Nombre del sastre |
| `esDueno` | Boolean | Indica si es el propietario (recibe comisiones) |
| `comisionFija` | Double? | Comisión específica (si aplica) |
| `estaActivo` | Boolean | Para desactivar sastres sin borrar su historial |

### Cobro
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | UUID/String | Identificador único |
| `sastreId` | String | Referencia al sastre que realizó el trabajo |
| `monto` | Double | Monto bruto cobrado al cliente |
| `cliente` | String? | Nombre del cliente (opcional) |
| `prenda` | String? | Detalle de la prenda (opcional) |
| `fechaHora` | DateTime | Marca de tiempo automática |
| `comisionMonto` | Double | Monto calculado de la comisión para el dueño |
| `netoSastre` | Double | Monto que le corresponde al sastre |

### Configuración
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `nombreNegocio` | String | Nombre de la sastrería |
| `comisionGeneral` | Double | Porcentaje de comisión por defecto (0-100) |

## 4. Descripción de Pantallas y Flujo

1.  **Dashboard (Inicio):**
    *   Visualización de tarjetas con totales diarios.
    *   Sección de "Dueño" con su acumulado de comisiones + trabajos propios.
    *   Botones de acción rápida: "Nuevo Cobro", "Lista", "Cierre".
2.  **Nuevo Cobro:**
    *   Selección visual (iconos/nombres) del sastre.
    *   Teclado numérico grande para el monto.
    *   Campos opcionales de texto.
    *   Cálculo en tiempo real de lo que recibe el sastre vs la comisión.
3.  **Lista de Cobros:**
    *   Tabla detallada con opción de filtrado rápido por sastre.
    *   Botón de eliminación (con confirmación de administrador).
4.  **Cierre del Día:**
    *   Resumen tipo "Ticket" por sastre.
    *   Botón final de "Cerrar Día" que archiva y limpia el dashboard.
5.  **Módulo de Administración:**
    *   Gestión de personal (Sastres).
    *   Ajustes de porcentajes y nombre del negocio.

## 5. Estructura de Carpetas del Proyecto
```
lib/
├── core/               # Utilidades, constantes, temas y errores globales
├── domain/             # Entidades y contratos (interfaces) de repositorios
│   ├── entities/
│   └── repositories/
├── data/               # Implementaciones de repositorios y base de datos
│   ├── datasources/    # Helper de SQLite
│   ├── models/         # DTOs para conversión JSON/DB
│   └── repositories/
└── presentation/       # UI y Lógica de vista (Bloc/Cubit)
    ├── blocs/
    ├── pages/
    └── widgets/
```

## 6. Escalabilidad Futura
El diseño contempla la migración a una base de datos remota mediante el patrón Repository. Simplemente se añadiría un `RemoteDataSource` y el resto de la app (Dominio y UI) permanecería intacto.
