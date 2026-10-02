# SNMPMonitor

Application macOS SwiftUI pour suivre les indicateurs SNMP d'un agent Net-SNMP Debian/Ubuntu dans le cadre du cours Linux Performance.

## Prerequis

La cible Linux doit exposer SNMP v2c avec la communaute utilisee par l'application.
L'application utilise la librairie Swift native SwiftSnmpKit, donc aucun outil Net-SNMP n'est requis sur le Mac.

## Compilation et lancement

Depuis ce dossier :

Pour compiler l'application :

```bash
swift build
```

Pour compiler puis executer l'application :

```bash
swift run SNMPMonitor
```

L'application utilise SwiftSnmpKit pour les requetes SNMP v2c. Les OID scalaires sont interroges en GET et les tables sont parcourues avec des requetes GETNEXT successives.

## Indicateurs suivis

- Systeme : description, uptime SNMP, contact, hostname, localisation.
- Charge : load average 1, 5 et 15 minutes.
- CPU : user, system, idle, iowait, nice, interrupt, softirq, steal et compteurs bruts.
- Memoire : RAM totale, disponible, partagee, buffers, cache.
- Swap : total, disponible, seuil minimum.
- Disques UCD-SNMP-MIB : points de montage, espace, inodes, erreurs.
- Reseau IF-MIB : interfaces, statuts, octets RX/TX, erreurs et drops.
- Processus HOST-RESOURCES-MIB : nom, PID, chemin, arguments et etat.
- Stockage HOST-RESOURCES-MIB : type, description, unite, taille, utilisation et erreurs.

## Notes

SwiftSnmpKit supporte les requetes SNMP sur UDP/161. Verifiez que le pare-feu de la VM ou de la machine Linux laisse passer ce trafic.
