# Specs: memory-cli

## Reglas de Negocio

### RN-1: Tipos válidos
Solo se aceptan: `decision`, `snippet`, `context`. Cualquier otro tipo → error con código de salida 1.

### RN-2: Contenido obligatorio
Toda entrada requiere content no vacío. Si --file se usa, el contenido es el archivo leído. --content y --file son mutuamente excluyentes.

### RN-3: Tags opcionales
Tags son opcionales. Se almacenan como texto separado por comas. Se normalizan a lowercase y se eliminan espacios.

### RN-4: Auto-inicialización
Si la DB no existe al ejecutar cualquier comando, se crea automáticamente con el schema completo (tablas + FTS5).

### RN-5: Output JSON
Todo output a stdout es JSON válido. Errores van a stderr como texto plano.

### RN-6: IDs estables
Los IDs son enteros autoincrement de SQLite. Una vez asignado, un ID no se reutiliza.

### RN-7: Session ID
session_id es opcional. Si no se provee, se omite (NULL). Permite agrupar entradas por sesión.

---

## Escenarios

### E-1: Agregar decisión técnica
```
DADO que el agente ejecuta: mem add --type decision --tags "db,perf" --content "Usamos SQLite por FTS5"
CUANDO el comando se procesa
ENTONCES se inserta una fila con type=decision, tags="db,perf", content="Usamos SQLite por FTS5"
Y stdout retorna JSON: {"status":"ok","id":1}
Y el código de salida es 0
```

### E-2: Agregar snippet desde archivo
```
DADO que existe ./fix.rs con contenido válido
CUANDO el agente ejecuta: mem add --type snippet --tags "bugfix" --file ./fix.rs
ENTONCES content = contenido de ./fix.rs
Y stdout retorna JSON: {"status":"ok","id":2}
```

### E-3: Archivo no existe
```
DADO que ./noexiste.rs no existe
CUANDO el agente ejecuta: mem add --type snippet --file ./noexiste.rs
ENTONCES stderr muestra "error: file not found: ./noexiste.rs"
Y código de salida es 1
```

### E-4: Búsqueda full-text
```
DADO que existen entradas con "SQLite" en content
CUANDO el agente ejecuta: mem search "sqlite"
ENTONCES stdout retorna JSON array con las entradas que matchean FTS5
Y los resultados están ordenados por relevancia (rank)
```

### E-5: Búsqueda con filtros
```
CUANDO el agente ejecuta: mem search --type decision --tags db
ENTONCES solo retorna entradas de type=decision que contengan tag "db"
```

### E-6: Búsqueda sin resultados
```
CUANDO el agente ejecuta: mem search "xyznonexistent"
ENTONCES stdout retorna JSON: []
Y código de salida es 0
```

### E-7: Listar últimas N
```
CUANDO el agente ejecuta: mem list --last 5
ENTONCES retorna las últimas 5 entradas ordenadas por created_at DESC
```

### E-8: Eliminar entrada
```
DADO que existe entrada con id=3
CUANDO el agente ejecuta: mem delete 3
ENTONCES la entrada se elimina de la tabla principal y del índice FTS5
Y stdout retorna JSON: {"status":"ok","deleted":3}
```

### E-9: Eliminar ID inexistente
```
CUANDO el agente ejecuta: mem delete 999
ENTONCES stderr muestra "error: entry 999 not found"
Y código de salida es 1
```

### E-10: Export
```
CUANDO el agente ejecuta: mem export
ENTONCES stdout retorna JSON array con TODAS las entradas
```

### E-11: Tipo inválido
```
CUANDO el agente ejecuta: mem add --type nota --content "algo"
ENTONCES stderr muestra error indicando tipos válidos
Y código de salida es 1
```

### E-12: Content vacío
```
CUANDO el agente ejecuta: mem add --type decision --content ""
ENTONCES stderr muestra "error: content cannot be empty"
Y código de salida es 1
```

---

## Criterios de Aceptación

- [ ] `mem add` persiste en SQLite y retorna JSON con id
- [ ] `mem search <query>` usa FTS5 y retorna en <5ms para 500 entradas
- [ ] `mem search` con --type y --tags filtra correctamente
- [ ] `mem list` retorna entradas ordenadas por fecha
- [ ] `mem delete` elimina de tabla + índice FTS
- [ ] `mem export` dump completo en JSON
- [ ] DB se auto-crea en primer uso
- [ ] Errores van a stderr, datos a stdout
- [ ] Código de salida: 0 = ok, 1 = error
