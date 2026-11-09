<?php
// Login e logout (Etapa 6).

class AuthController {
    private const MSG_LOGIN_INVALIDO = 'E-mail ou senha inválidos.';

    public function formulario(): void {
        if (usuario_logado()) {
            redirect('/carros');
        }
        $erros = $_SESSION['erros'] ?? [];
        $email = old('email');
        unset($_SESSION['old'], $_SESSION['erros']);
        view('auth/login', ['titulo' => 'Entrar', 'erros' => $erros, 'email' => $email]);
    }

    public function entrar(): void {
        csrf_verificar();
        $email = input('email');
        $senha = $_POST['senha'] ?? '';

        $erros = [];
        if ($email === '' || !is_string($senha) || $senha === '') {
            $erros[] = 'Informe e-mail e senha.';
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $erros[] = 'Informe um e-mail válido.';
        }
        if ($erros) {
            $this->voltar($erros, $email);
        }

        try {
            $usuario = (new UsuarioModel())->buscarPorEmail($email);
        } catch (PDOException $e) {
            registrar_erro($e);
            $this->voltar(['Não foi possível concluir a operação. Tente novamente.'], $email);
        }

        // Mesma mensagem para e-mail inexistente e senha errada.
        if (!$usuario || !password_verify($senha, $usuario['senha_hash'])) {
            $this->voltar([self::MSG_LOGIN_INVALIDO], $email);
        }

        session_regenerate_id(true);
        $_SESSION['usuario_id']   = $usuario['id'];
        $_SESSION['usuario_nome'] = $usuario['nome'];
        $_SESSION['perfil']       = $usuario['perfil'];
        flash('sucesso', 'Bem-vindo(a), ' . $usuario['nome'] . '.');
        redirect('/carros');
    }

    public function sair(): void {
        csrf_verificar();
        $_SESSION = [];
        session_regenerate_id(true);
        flash('sucesso', 'Você saiu do sistema.');
        redirect('/login');
    }

    private function voltar(array $erros, string $email): never {
        $_SESSION['erros'] = $erros;
        $_SESSION['old']   = ['email' => $email];
        redirect('/login');
    }
}
