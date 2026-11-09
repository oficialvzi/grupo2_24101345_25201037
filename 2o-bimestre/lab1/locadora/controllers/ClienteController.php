<?php
// Cadastro e listagem de Clientes pelo navegador (Etapa 2).

class ClienteController {
    private ClienteModel $clientes;

    public function __construct() {
        $this->clientes = new ClienteModel();
    }

    public function index(): void {
        $busca = isset($_GET['busca']) && is_string($_GET['busca']) ? trim($_GET['busca']) : '';
        view('clientes/index', [
            'titulo'   => 'Clientes',
            'clientes' => $this->clientes->listar($busca),
            'busca'    => $busca,
        ]);
    }

    public function criar(): void {
        $this->formulario('Novo cliente', null, url('/clientes/salvar'));
    }

    public function salvar(): void {
        csrf_verificar();
        $dados = $this->dadosDoFormulario();

        if ($erros = $this->validar($dados)) {
            $this->voltarComErro($erros, $dados, '/clientes/novo');
        }

        try {
            $this->clientes->criar($dados);
            flash('sucesso', 'Cliente ' . $dados['nome'] . ' cadastrado com sucesso.');
            redirect('/clientes');
        } catch (PDOException $e) {
            $this->voltarComErro([$this->mensagemDoBanco($e)], $dados, '/clientes/novo');
        }
    }

    public function editar(): void {
        $cliente = $this->clientes->buscarPorId((int) ($_GET['id'] ?? 0));
        if (!$cliente) {
            flash('erro', 'Cliente não encontrado.');
            redirect('/clientes');
        }
        $this->formulario('Editar cliente', $cliente, url('/clientes/atualizar', ['id' => $cliente['id']]));
    }

    public function atualizar(): void {
        csrf_verificar();
        $id    = (int) ($_GET['id'] ?? 0);
        $dados = $this->dadosDoFormulario();

        if (!$this->clientes->buscarPorId($id)) {
            flash('erro', 'Cliente não encontrado.');
            redirect('/clientes');
        }
        if ($erros = $this->validar($dados)) {
            $this->voltarComErro($erros, $dados, '/clientes/editar', ['id' => $id]);
        }

        try {
            $this->clientes->atualizar($id, $dados);
            flash('sucesso', 'Cliente ' . $dados['nome'] . ' atualizado com sucesso.');
            redirect('/clientes');
        } catch (PDOException $e) {
            $this->voltarComErro([$this->mensagemDoBanco($e)], $dados, '/clientes/editar', ['id' => $id]);
        }
    }

    public function excluir(): void {
        csrf_verificar();
        $cliente = $this->clientes->buscarPorId((int) ($_POST['id'] ?? 0));

        if (!$cliente) {
            flash('erro', 'Cliente não encontrado.');
            redirect('/clientes');
        }

        try {
            $this->clientes->excluir($cliente['id']);
            flash('sucesso', 'Cliente ' . $cliente['nome'] . ' excluído.');
        } catch (PDOException $e) {
            flash('erro', $this->mensagemDoBanco($e));
        }
        redirect('/clientes');
    }

    // -------------------------------------------------------------------------

    private function formulario(string $titulo, ?array $cliente, string $acao): void {
        $valores = [
            'nome' => old('nome', $cliente['nome'] ?? ''),
            'cpf'  => old('cpf', $cliente['cpf'] ?? ''),
        ];
        $erros = $_SESSION['erros'] ?? [];
        unset($_SESSION['old'], $_SESSION['erros']);

        view('clientes/form', [
            'titulo'  => $titulo,
            'acao'    => $acao,
            'cliente' => $valores,
            'erros'   => $erros,
        ]);
    }

    private function dadosDoFormulario(): array {
        return ['nome' => input('nome'), 'cpf' => input('cpf')];
    }

    private function validar(array $d): array {
        $erros = [];
        if ($d['nome'] === '') $erros[] = 'Informe o nome.';
        if (mb_strlen($d['nome']) > 100) $erros[] = 'O nome deve ter no máximo 100 caracteres.';
        if (!preg_match('/^\d{3}\.\d{3}\.\d{3}-\d{2}$/', $d['cpf'])) {
            $erros[] = 'Informe o CPF no formato 000.000.000-00.';
        }
        return $erros;
    }

    private function voltarComErro(array $erros, array $dados, string $rota, array $query = []): never {
        $_SESSION['erros'] = $erros;
        $_SESSION['old']   = $dados;
        redirect($rota, $query);
    }

    private function mensagemDoBanco(PDOException $e): string {
        $codigo = $e->errorInfo[1] ?? null;
        if ($codigo === 1062) return 'Já existe um cliente com esse CPF.';
        if ($codigo === 1451) return 'O cliente possui locações registradas e não pode ser excluído.';

        // Demais erros (ex.: 1142, DELETE negado ao app_locadora) vão só para o log.
        registrar_erro($e);
        return 'Não foi possível concluir a operação. Tente novamente.';
    }
}
