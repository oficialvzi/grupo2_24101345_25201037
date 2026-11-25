<?php
// Cadastro de usuários do sistema. Só o perfil admin acessa.

class UsuarioController {
    private const PERFIS = ['admin', 'atendente'];

    private UsuarioModel $usuarios;

    public function __construct() {
        $this->usuarios = new UsuarioModel();
    }

    public function index(): void {
        view('usuarios/index', ['titulo' => 'Usuários', 'usuarios' => $this->usuarios->listar()]);
    }

    public function criar(): void {
        $valores = [
            'nome'   => old('nome'),
            'email'  => old('email'),
            'perfil' => old('perfil', 'atendente'),
        ];
        $erros = $_SESSION['erros'] ?? [];
        unset($_SESSION['old'], $_SESSION['erros']);
        view('usuarios/form', [
            'titulo'  => 'Novo usuário',
            'usuario' => $valores,
            'perfis'  => self::PERFIS,
            'erros'   => $erros,
        ]);
    }

    public function salvar(): void {
        csrf_verificar();
        $dados = ['nome' => input('nome'), 'email' => input('email'), 'perfil' => input('perfil')];
        $senha = $_POST['senha'] ?? '';
        $confirmacao = $_POST['senha_confirmacao'] ?? '';

        $erros = [];
        if ($dados['nome'] === '') $erros[] = 'Informe o nome.';
        if (!filter_var($dados['email'], FILTER_VALIDATE_EMAIL)) $erros[] = 'Informe um e-mail válido.';
        if (!is_string($senha) || mb_strlen($senha) < 8) $erros[] = 'A senha deve ter pelo menos 8 caracteres.';
        elseif ($senha !== $confirmacao) $erros[] = 'A confirmação não confere com a senha.';
        if (!in_array($dados['perfil'], self::PERFIS, true)) $erros[] = 'Perfil inválido.';

        if (!$erros) {
            try {
                $this->usuarios->criar($dados['nome'], $dados['email'], $senha, $dados['perfil']);
                flash('sucesso', 'Usuário ' . $dados['email'] . ' cadastrado.');
                redirect('/usuarios');
            } catch (PDOException $e) {
                if (($e->errorInfo[1] ?? null) === 1062) {
                    $erros[] = 'Já existe um usuário com esse e-mail.';
                } else {
                    registrar_erro($e);
                    $erros[] = 'Não foi possível concluir a operação. Tente novamente.';
                }
            }
        }

        $_SESSION['erros'] = $erros;
        $_SESSION['old']   = $dados;   // a senha nunca volta para o formulário
        redirect('/usuarios/novo');
    }
}
