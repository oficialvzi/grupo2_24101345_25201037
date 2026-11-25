<?php if (!empty($erros)): ?>
    <div class="alerta alerta--erro">
        <strong>Corrija os campos abaixo:</strong>
        <ul>
            <?php foreach ($erros as $erro): ?>
                <li><?= e($erro) ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>
