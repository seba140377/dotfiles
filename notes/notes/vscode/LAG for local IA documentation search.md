# RAG für die Suche in meiner Projektdokumentation einrichten
  Das Konzept: Retrieval-Augmented Generation (RAG)

  Die Idee ist folgende:

  Ihr KI-Agent (LLM) kennt Ihre private Dokumentation nicht.

  Wenn Sie eine Frage stellen, sucht ein System (der "Server", den Sie meinen) zuerst in Ihrer Dokumentation (den Markdown-Dateien) nach den relevantesten Textstücken.

  Diese relevanten Textstücke werden dann zusammen mit Ihrer ursprünglichen Frage an den KI-Agenten gesendet.

  Der Agent nutzt diesen zusätzlichen Kontext, um eine präzise Antwort zu generieren, die auf Ihren Daten basiert.

  Der "Server", den Sie implementieren möchten, ist also ein Retrieval-System.

  1. RAG-Frameworks (Die einfachste Lösung)<br>
    Dies sind Bibliotheken, die genau für Ihren Anwendungsfall konzipiert sind. Sie sind der "Klebstoff" zwischen Ihren Dokumenten und Ihrem KI-Agenten.<br><br>
    LlamaIndex: Oft als die beste Wahl für RAG angesehen. Es ist darauf spezialisiert, Daten aus verschiedensten Quellen (wie Markdown-Ordnern) zu laden, zu indizieren und abfragbar zu machen. Es ist sehr effizient beim "Data Ingestion".<br><br>
    LangChain: Ein sehr populäres und umfassendes Framework, um KI-Anwendungen zu bauen. Es hat ebenfalls starke RAG-Funktionen (sogenannte "Chains") und kann Dokumente laden, aufteilen und indizieren.<br><br>
    Empfehlung: Starten Sie mit LlamaIndex oder LangChain. Diese Tools nehmen Ihnen 90% der Arbeit ab. Sie können einen einfachen Python-Server (z.B. mit FastAPI) erstellen, der eine Funktion aus LlamaIndex aufruft.
  2. Vektordatenbanken (Das "Gehirn" der Suche)<br>
    Um intelligent zu suchen (semantische Suche statt nur Keyword-Suche), werden Ihre Dokumente in sogenannte "Embeddings" (Zahlenvektoren) umgewandelt. Diese Vektoren werden in einer Vektordatenbank gespeichert.<br><br>
    ChromaDB: Eine sehr beliebte, Open-Source-Datenbank, die einfach zu starten ist und oft direkt in RAG-Anwendungen integriert wird. Sie können sie lokal laufen lassen.<br><br>
    Qdrant: Eine weitere leistungsstarke Open-Source-Option, die auch lokal betrieben werden kann.

  Links: https://www.youtube.com/watch?v=FfgffRmTjtg
  Helpful Google Searches: Using RAG to search my local documentation
