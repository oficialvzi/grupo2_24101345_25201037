<?php
// =============================================================================
// Etapa 4 — Teste de SQL Injection na busca de carros.
// Uso (linha de comando, fora da pasta public/):
//   php testes/teste_sql_injection.php
//
// Compara a MESMA busca montada de duas formas:
//   (1) concatenando a entrada no SQL  -> versão vulnerável, só para o teste;
//   (2) prepared statement             -> a forma usada em CarroModel::listar().
// A versão concatenada existe apenas neste script; a aplicação não a usa.
// =============================================================================

require_once __DIR__ . '/../locadora/config/database.php';

$pdo   = getConnection();
$busca = $argv[1] ?? "' OR '1'='1";

function imprimir(array $linhas): void {
    if (!$linhas) {
        echo "   (nenhuma linha retornada)\n";
        return;
    }
    foreach ($linhas as $l) {
        printf("   id=%-3s placa=%-8s modelo=%-28s deleted_at=%s\n",
            $l['id'], $l['placa'], $l['modelo'], $l['deleted_at'] ?? 'NULL');
    }
}

echo "Entrada digitada na busca: {$busca}\n\n";

// (1) VULNERÁVEL — NÃO FAZER ISSO NA APLICAÇÃO
$sql = "SELECT id, placa, modelo, deleted_at FROM Veiculo
        WHERE modelo LIKE '%" . $busca . "%' AND deleted_at IS NULL";
echo "(1) CONSULTA CONCATENADA\n";
echo "   SQL que chega ao MySQL:\n   " . preg_replace('/\s+/', ' ', $sql) . "\n";
$linhas = $pdo->query($sql)->fetchAll();
echo "   Linhas retornadas: " . count($linhas) . "\n";
imprimir($linhas);

// (2) SEGURO — prepared statement
$sql = 'SELECT id, placa, modelo, deleted_at FROM Veiculo
        WHERE modelo LIKE :modelo AND deleted_at IS NULL';
echo "\n(2) PREPARED STATEMENT\n";
echo "   SQL enviado ao MySQL (o valor vai separado):\n   " . preg_replace('/\s+/', ' ', $sql) . "\n";
echo "   :modelo = '%{$busca}%'\n";
$stmt = $pdo->prepare($sql);
$stmt->execute([':modelo' => '%' . $busca . '%']);
$linhas = $stmt->fetchAll();
echo "   Linhas retornadas: " . count($linhas) . "\n";
imprimir($linhas);
