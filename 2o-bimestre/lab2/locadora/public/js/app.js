// Pede confirmação antes de enviar formulários de exclusão.
// Fica em arquivo próprio porque a Content-Security-Policy bloqueia JS inline.
document.addEventListener('submit', (ev) => {
    const msg = ev.target.dataset.confirmar;
    if (msg && !window.confirm(msg)) ev.preventDefault();
});
