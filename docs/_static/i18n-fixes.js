document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('details > summary').forEach(s => {
    const t = s.textContent.trim();
    if (t === 'Details' || t === 'Detalles') s.firstChild.nodeValue = 'Detalls';
  });
});
