<?php
// =============================================================================
// Backfill (Etapa 1, Passo 2): copia Veiculo.cor -> Veiculo.cor_externa em lotes.
//
// Uso (a partir de lab2/locadora, depois da migration 002):
//   php scripts/backfill_cor.php
//
// Em lotes de 1000 linhas com pausa de 0,2 s entre eles: cada UPDATE trava poucas
// linhas por pouco tempo, então o sistema continua atendendo durante a cópia.
// Pode ser executado de novo sem problema: só copia o que ainda está NULL.
// =============================================================================

if (PHP_SAPI !== 'cli') { exit('Somente linha de comando.'); }

require_once __DIR__ . '/../config/config.php';
$pdo = new PDO(
    'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
    MIG_USER,
    MIG_PASS,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$total = 0;
do {
    // sem filtro em deleted_at: carros "excluídos" também precisam migrar
    $afetadas = $pdo->exec(
        'UPDATE Veiculo SET cor_externa = cor
          WHERE cor_externa IS NULL AND cor IS NOT NULL
          LIMIT 1000'
    );
    $total += $afetadas;
    echo 'Lote: ' . $afetadas . ' linhas' . PHP_EOL;
    usleep(200000);
} while ($afetadas > 0);

echo 'Total copiado: ' . $total . PHP_EOL;

// Checkpoint: precisa ser 0, contando os carros com deleted_at preenchido.
$faltam = (int) $pdo->query(
    'SELECT COUNT(*) FROM Veiculo WHERE cor_externa IS NULL AND cor IS NOT NULL'
)->fetchColumn();
echo 'Faltam migrar: ' . $faltam . PHP_EOL;
