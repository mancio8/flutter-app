String capitalizzaNomeSquadra(String testo) {
  if (testo.isEmpty) return testo;
  return testo.split(' ').map((parola) {
    if (parola.isEmpty) return parola;
    return parola[0].toUpperCase() + parola.substring(1).toLowerCase();
  }).join(' ');
}