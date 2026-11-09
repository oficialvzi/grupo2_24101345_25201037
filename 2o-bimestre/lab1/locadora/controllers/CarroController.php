<?php
// CRUD de Carros (tabela Veiculo). Recebe a requisição, chama o model e
// escolhe a view. Não contém SQL.

class CarroController {
    private const STATUS = ['disponivel', 'locado'];

    private CarroModel $carros;
    private CategoriaModel $categorias;

    public function __construct() {
        $this->carros     = new CarroModel();
        $this->categorias = new CategoriaModel();
    }

    public function index(): void {
        $busca = isset($_GET['busca']) && is_string($_GET['busca']) ? trim($_GET['busca']) : '';
        view('carros/index', [
            'titulo' => 'Carros',
            'carros' => $this->carros->listar($busca),
            'busca'  => $busca,
        ]);
    }

    public function criar(): void {
        $this->formulario('Novo carro', null, url('/carros/salvar'));
    }

    public function salvar(): void {
        csrf_verificar();
        $dados = $this->dadosDoFormulario();

        if ($erros = $this->validar($dados)) {
            $this->voltarComErro($erros, $dados, '/carros/novo');
        }

        try {
            $this->carros->criar($dados);
            flash('sucesso', 'Carro ' . $dados['modelo'] . ' (' . $dados['placa'] . ') cadastrado com sucesso.');
            redirect('/carros');
        } catch (PDOException $e) {
            $this->voltarComErro([$this->mensagemDoBanco($e)], $dados, '/carros/novo');
        }
    }

    public function editar(): void {
        $carro = $this->carros->buscarPorId((int) ($_GET['id'] ?? 0));
        if (!$carro) {
            flash('erro', 'Carro não encontrado.');
            redirect('/carros');
        }
        $this->formulario('Editar carro', $carro, url('/carros/atualizar', ['id' => $carro['id']]));
    }

    public function atualizar(): void {
        csrf_verificar();
        $id    = (int) ($_GET['id'] ?? 0);
        $dados = $this->dadosDoFormulario();

        if (!$this->carros->buscarPorId($id)) {
            flash('erro', 'Carro não encontrado.');
            redirect('/carros');
        }
        if ($erros = $this->validar($dados)) {
            $this->voltarComErro($erros, $dados, '/carros/editar', ['id' => $id]);
        }

        try {
            $this->carros->atualizar($id, $dados);
            flash('sucesso', 'Carro ' . $dados['placa'] . ' atualizado com sucesso.');
            redirect('/carros');
        } catch (PDOException $e) {
            $this->voltarComErro([$this->mensagemDoBanco($e)], $dados, '/carros/editar', ['id' => $id]);
        }
    }

    public function excluir(): void {
        csrf_verificar();
        $carro = $this->carros->buscarPorId((int) ($_POST['id'] ?? 0));

        if (!$carro) {
            flash('erro', 'Carro não encontrado.');
        } elseif ($carro['status'] === 'locado') {
            flash('erro', 'O carro ' . $carro['placa'] . ' está locado e não pode ser excluído.');
        } else {
            try {
                $this->carros->excluir($carro['id']);
                flash('sucesso', 'Carro ' . $carro['placa'] . ' excluído (soft delete: o registro continua no banco).');
            } catch (PDOException $e) {
                flash('erro', $this->mensagemDoBanco($e));
            }
        }
        redirect('/carros');
    }

    // -------------------------------------------------------------------------

    private function formulario(string $titulo, ?array $carro, string $acao): void {
        // Após erro de validação, prevalece o que o usuário digitou.
        $valores = [
            'placa'        => old('placa', $carro['placa'] ?? ''),
            'modelo'       => old('modelo', $carro['modelo'] ?? ''),
            'id_categoria' => old('id_categoria', $carro['id_categoria'] ?? ''),
            'status'       => old('status', $carro['status'] ?? 'disponivel'),
        ];
        $erros = $_SESSION['erros'] ?? [];
        unset($_SESSION['old'], $_SESSION['erros']);

        view('carros/form', [
            'titulo'     => $titulo,
            'acao'       => $acao,
            'carro'      => $valores,
            'categorias' => $this->categorias->listar(),
            'statusList' => self::STATUS,
            'erros'      => $erros,
        ]);
    }

    private function dadosDoFormulario(): array {
        return [
            'placa'        => strtoupper(str_replace(['-', ' '], '', input('placa'))),
            'modelo'       => input('modelo'),
            'id_categoria' => (int) input('id_categoria'),
            'status'       => input('status'),
        ];
    }

    private function validar(array $d): array {
        $erros = [];
        if ($d['placa'] === '') {
            $erros[] = 'Informe a placa.';
        } elseif (!preg_match('/^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$/', $d['placa'])) {
            // Formato antigo (ABC1234) ou Mercosul (ABC1D23).
            $erros[] = 'Placa inválida. Use o formato ABC1234 ou ABC1D23.';
        }
        if ($d['modelo'] === '') $erros[] = 'Informe o modelo.';
        if (mb_strlen($d['modelo']) > 50) $erros[] = 'O modelo deve ter no máximo 50 caracteres.';
        if (!$this->categorias->existe($d['id_categoria'])) $erros[] = 'Selecione uma categoria válida.';
        if (!in_array($d['status'], self::STATUS, true))    $erros[] = 'Status inválido.';
        return $erros;
    }

    private function voltarComErro(array $erros, array $dados, string $rota, array $query = []): never {
        $_SESSION['erros'] = $erros;
        $_SESSION['old']   = $dados;
        redirect($rota, $query);
    }

    /** Traduz o erro do MySQL para uma mensagem amigável, sem expor detalhes técnicos. */
    private function mensagemDoBanco(PDOException $e): string {
        if (($e->errorInfo[1] ?? null) === 1062) {
            return 'Já existe um carro com essa placa (inclusive entre os excluídos).';
        }
        registrar_erro($e);
        return 'Não foi possível concluir a operação. Tente novamente.';
    }
}
