# TEDxBooks4You
Questo progetto prevede la realizzazione di un'applicazione che data la propria cronologia di youtube (riguardo i Tedx) vada a consigliare dei libri inerenti ai video visti.
Il programma è hostato e funziona interamente su AWS, il database di tutti i video da usare come paragone, con i relativi tag e altre informazioni è stato fornito dal prof. Pelucchi Mauro.
Il funzionamento è molto semplice, data la cronologia, il sistema cerca i video visti con quelli nel DB e ne estrae i tag di ogni video. Una volta estrapolati e raggruppati, si vanno a cercare tramite Google Books API i libri più inerenti ai Tag rilevati.
Il progetto è stato interamente svolto da Bellosi Jacopo e Poloni Luca
