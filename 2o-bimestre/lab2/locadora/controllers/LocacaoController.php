<?php
// Abertura e devolução de locações, com validação de datas no servidor (Etapa 6).

class LocacaoController {
    private LocacaoModel $locacoes;

    public function __construct() {
        $this->locacoes = new LocacaoModel();
    }

    public function index(): void {
        view('locacoes/index', ['titulo' => 'Locações', 'locacoes' => $this->locacoes->listar()]);
    }

    public function criar(): void {
        $hoje = date('Y-m-d');
        $valores = [
            'id_cliente'          => old('id_cliente'),
            'id_veiculo'          => old('id_veiculo'),
            'id_filial_retirada'  => old('id_filial_retirada'),
            'id_filial_devolucao' => old('id_filial_devolucao'),
            'data_retirada'       => old('data_retirada', $hoje),
            'data_prevista'       => old('data_prevista', date('Y-m-d', strtotime('+1 day'))),
        ];
        $erros = $_SESSION['erros'] ?? [];
        unset($_SESSION['old'], $_SESSION['erros']);

        view('locacoes/form', [
            'titulo'    => 'Nova locação',
            'locacao'   => $valores,
            'clientes'  => (new ClienteModel())->listar(),
            'veiculos'  => $this->locacoes->veiculosDisponiveis(),
            'filiais'   => (new FilialModel())->listar(),
            'erros'     => $erros,
        ]);
    }

    public function salvar(): void {
        csrf_verificar();
        $d = [
            'id_cliente'          => (int) input('id_cliente'),
            'id_veiculo'          => (int) input('id_veiculo'),
            'id_filial_retirada'  => (int) input('id_filial_retirada'),
            'id_filial_devolucao' => (int) input('id_filial_devolucao'),
            'data_retirada'       => input('data_retirada'),
            'data_prevista'       => input('data_prevista'),
        ];

        $erros   = [];
        $filiais = new FilialModel();
        if (!(new ClienteModel())->buscarPorId($d['id_cliente'])) $erros[] = 'Selecione um cliente.';
        if ($d['id_veiculo'] <= 0) $erros[] = 'Selecione um veículo.';
        if (!$filiais->existe($d['id_filial_retirada']))  $erros[] = 'Selecione a filial de retirada.';
        if (!$filiais->existe($d['id_filial_devolucao'])) $erros[] = 'Selecione a filial de devolução.';

        $retirada = $this->data($d['data_retirada']);
        $prevista = $this->data($d['data_prevista']);
        if (!$retirada) $erros[] = 'Informe uma data de retirada válida.';
        if (!$prevista) $erros[] = 'Informe uma data de devolução válida.';
        if ($retirada && $prevista && $prevista <= $retirada) {
            $erros[] = 'A data de devolução deve ser posterior à data de retirada.';
        }

        if (!$erros) {
            try {
                $id = $this->locacoes->criar($d);
                if ($id === null) {
                    $erros[] = 'Esse veículo não está mais disponível.';
                } else {
                    flash('sucesso', 'Locação #' . $id . ' aberta com sucesso.');
                    redirect('/locacoes');
                }
            } catch (PDOException $e) {
                registrar_erro($e);
                $erros[] = 'Não foi possível concluir a operação. Tente novamente.';
            }
        }

        $_SESSION['erros'] = $erros;
        $_SESSION['old']   = $d;
        redirect('/locacoes/nova');
    }

    public function devolver(): void {
        csrf_verificar();
        $locacao  = $this->locacoes->buscarPorId((int) ($_POST['id'] ?? 0));
        $dataReal = $this->data(input('data_real'));

        if (!$locacao || $locacao['data_real'] !== null) {
            flash('erro', 'Locação não encontrada ou já finalizada.');
        } elseif (!$dataReal) {
            flash('erro', 'Informe uma data de devolução válida.');
        } elseif ($dataReal < $this->data($locacao['data_retirada'])) {
            flash('erro', 'A data de devolução não pode ser anterior à retirada (' . date('d/m/Y', strtotime($locacao['data_retirada'])) . ').');
        } else {
            try {
                $this->locacoes->registrarDevolucao($locacao['id'], $dataReal->format('Y-m-d'));
                flash('sucesso', 'Devolução da locação #' . $locacao['id'] . ' registrada.');
            } catch (PDOException $e) {
                registrar_erro($e);
                flash('erro', 'Não foi possível concluir a operação. Tente novamente.');
            }
        }
        redirect('/locacoes');
    }

    /** Aceita só datas reais no formato AAAA-MM-DD (rejeita 2026-02-31, por exemplo). */
    private function data(string $valor): ?DateTimeImmutable {
        $d = DateTimeImmutable::createFromFormat('!Y-m-d', $valor);
        return ($d && $d->format('Y-m-d') === $valor) ? $d : null;
    }
}
