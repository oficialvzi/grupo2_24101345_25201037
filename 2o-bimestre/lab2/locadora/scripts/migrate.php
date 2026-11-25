<?php
// =============================================================================
// Runner de migrations (Aula 30), adaptado para a locadora.
//
// Uso (a partir de lab2/locadora):
//   php scripts/migrate.php up     aplica as pendentes, em ordem
//   php scripts/migrate.php down   desfaz a última aplicada
//
// Cada arquivo em migrations/ tem duas seções separadas pela linha "-- down":
//   -- up
//   <uma instrução>
//   -- down
//   <uma instrução que desfaz a de cima>
// =============================================================================

// 1) só roda pela linha de comando, nunca pelo navegador
if (PHP_SAPI !== 'cli') { exit('Somente linha de comando.'); }

// 2) lê a configuração central e usa o usuário administrativo
//    (app_locadora não tem privilégio de DDL: ALTER/CREATE/DROP)
require_once __DIR__ . '/../config/config.php';
$pdo = new PDO(
    'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
    MIG_USER,
    MIG_PASS,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

// 3) as migrations ficam em ../migrations/
$dirMigrations = __DIR__ . '/../migrations';

$pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(100) PRIMARY KEY,
    aplicada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)");

// Separa o arquivo em duas partes: antes e depois da linha "-- down"
function separar(string $sql): array {
    $partes = preg_split('/^-- down\s*$/m', $sql);
    return [trim($partes[0]), trim($partes[1] ?? '')];
}

$comando = $argv[1] ?? 'up';

if ($comando === 'up') {
    $aplicadas = $pdo->query("SELECT version FROM schema_migrations")
                     ->fetchAll(PDO::FETCH_COLUMN);
    $arquivos = glob($dirMigrations . '/*.sql');
    sort($arquivos);

    $novas = 0;
    foreach ($arquivos as $arquivo) {
        $versao = basename($arquivo, '.sql');
        if (in_array($versao, $aplicadas, true)) {
            continue;
        }
        [$up] = separar(file_get_contents($arquivo));
        $pdo->exec($up);
        $pdo->prepare("INSERT INTO schema_migrations (version) VALUES (?)")
            ->execute([$versao]);
        echo "Aplicada: $versao\n";
        $novas++;
    }
    if ($novas === 0) {
        echo "Nenhuma migration pendente.\n";
    }
} elseif ($comando === 'down') {
    $ultima = $pdo->query(
        "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
    )->fetchColumn();

    if (!$ultima) {
        echo "Nada a desfazer.\n";
        exit;
    }
    [, $down] = separar(file_get_contents("$dirMigrations/$ultima.sql"));
    $pdo->exec($down);
    $pdo->prepare("DELETE FROM schema_migrations WHERE version = ?")
        ->execute([$ultima]);
    echo "Desfeita: $ultima\n";
} else {
    echo "Uso: php scripts/migrate.php up|down\n";
    exit(1);
}
