// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Built-in course templates for TDC Studio Editorial mode.
library;

import '../../tdc_parser_v2.dart';

class CourseTemplates {
  CourseTemplates._();

  static List<TdcResource> get all => [
        linuxAdmin(),
        networkSecurity(),
        productionIncident(),
      ];

  static TdcResource linuxAdmin() {
    return TdcResource(
      tdcVersion: '2',
      type: 'course',
      id: 'linux-admin',
      concrete: TdcCourse(
        id: 'linux-admin',
        title: 'Administration Linux',
        description: 'Maîtrisez les bases de l\'administration système Linux : shell, fichiers, processus, services.',
        category: 'linux',
        level: 'beginner',
        duration: '2h',
        icon: 'Terminal',
        modules: [
          TdcModule(
            id: 'intro',
            title: 'Introduction au shell',
            duration: '20min',
            content: '# Introduction\n\nLe shell est l\'interface textuelle avec le système.\n\n## Objectifs\n- Naviguer dans le système de fichiers\n- Lister et inspecter des fichiers\n- Comprendre les droits UNIX',
            questions: [
              TdcQuestion(
                text: 'Quelle commande affiche le répertoire courant ?',
                choices: [
                  TdcChoice(text: 'pwd', correct: true),
                  TdcChoice(text: 'ls', correct: false),
                  TdcChoice(text: 'cd', correct: false),
                ],
                explanation: 'pwd (print working directory) affiche le chemin absolu du répertoire courant.',
              ),
              TdcQuestion(
                text: 'Quelle option de ls affiche les fichiers cachés ?',
                choices: [
                  TdcChoice(text: '-a', correct: true),
                  TdcChoice(text: '-l', correct: false),
                  TdcChoice(text: '-h', correct: false),
                ],
                explanation: 'ls -a liste tous les fichiers, y compris ceux qui commencent par un point.',
              ),
            ],
          ),
          TdcModule(
            id: 'processes',
            title: 'Processus et ressources',
            duration: '25min',
            content: '# Processus\n\nSurveillez la charge CPU, la mémoire et les processus gourmands.',
            codeBlocks: [
              TdcCodeBlock(
                language: 'bash',
                title: 'Audit mémoire',
                code: 'uptime\nfree -h\nps aux --sort=-%mem | head -n 10',
              ),
            ],
            questions: [
              TdcQuestion(
                text: 'Quelle commande affiche la mémoire disponible ?',
                choices: [
                  TdcChoice(text: 'free -h', correct: true),
                  TdcChoice(text: 'whoami', correct: false),
                ],
                explanation: 'free -h affiche la RAM et le SWAP de façon lisible.',
              ),
              TdcQuestion(
                text: 'Que signifie un load average élevé ?',
                choices: [
                  TdcChoice(text: 'La machine est sollicitée', correct: true),
                  TdcChoice(text: 'Le disque est plein', correct: false),
                ],
                explanation: 'Le load average reflète la file d\'attente des processus prêts à tourner.',
              ),
            ],
          ),
          TdcModule(
            id: 'services',
            title: 'Services systemd',
            duration: '25min',
            content: '# systemd\n\nGérez les services avec systemctl.',
            codeBlocks: [
              TdcCodeBlock(
                language: 'bash',
                title: 'Statut d\'un service',
                code: 'systemctl status ssh\nsystemctl restart nginx',
              ),
            ],
            questions: [
              TdcQuestion(
                text: 'Quelle commande redémarre un service ?',
                choices: [
                  TdcChoice(text: 'systemctl restart [service]', correct: true),
                  TdcChoice(text: 'service kill [service]', correct: false),
                ],
                explanation: 'systemctl restart arrête puis relance le service demandé.',
              ),
              TdcQuestion(
                text: 'Où se trouvent les unit files ?',
                choices: [
                  TdcChoice(text: '/etc/systemd/system', correct: true),
                  TdcChoice(text: '/var/log', correct: false),
                ],
                explanation: 'Les units locales sont typiquement dans /etc/systemd/system.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static TdcResource networkSecurity() {
    return TdcResource(
      tdcVersion: '2',
      type: 'course',
      id: 'network-security',
      concrete: TdcCourse(
        id: 'network-security',
        title: 'Réseau & Sécurité',
        description: 'Diagnostiquer un réseau, comprendre TCP/IP et sécuriser les accès.',
        category: 'network',
        level: 'intermediate',
        duration: '3h',
        icon: 'Lan',
        modules: [
          TdcModule(
            id: 'tcpip',
            title: 'Fondamentaux TCP/IP',
            duration: '30min',
            content: '# TCP/IP\n\nCouches, ports, adressage.',
            questions: [
              TdcQuestion(
                text: 'Quel port utilise HTTPS par défaut ?',
                choices: [
                  TdcChoice(text: '443', correct: true),
                  TdcChoice(text: '80', correct: false),
                  TdcChoice(text: '22', correct: false),
                ],
                explanation: 'HTTPS écoute sur le port 443.',
              ),
              TdcQuestion(
                text: 'Quelle commande teste la connectivité ICMP ?',
                choices: [
                  TdcChoice(text: 'ping', correct: true),
                  TdcChoice(text: 'curl', correct: false),
                ],
                explanation: 'ping envoie des paquets ICMP Echo Request.',
              ),
              TdcQuestion(
                text: 'À quoi sert DNS ?',
                choices: [
                  TdcChoice(text: 'Résoudre un nom en IP', correct: true),
                  TdcChoice(text: 'Chiffrer le trafic', correct: false),
                ],
                explanation: 'Le DNS associe des noms de domaine à des adresses IP.',
              ),
            ],
          ),
          TdcModule(
            id: 'diag',
            title: 'Diagnostic réseau',
            duration: '30min',
            content: '# Diagnostic\n\nOutils : ping, traceroute, dig, ss.',
            codeBlocks: [
              TdcCodeBlock(
                language: 'bash',
                title: 'Inspection ports',
                code: 'ss -tulpn\nip addr show',
              ),
            ],
            questions: [
              TdcQuestion(
                text: 'Quelle commande liste les sockets ouvertes ?',
                choices: [
                  TdcChoice(text: 'ss -tulpn', correct: true),
                  TdcChoice(text: 'ls /proc', correct: false),
                ],
                explanation: 'ss remplace netstat pour inspecter les sockets.',
              ),
              TdcQuestion(
                text: 'dig sert à interroger le DNS.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'dig interroge les serveurs DNS.',
              ),
              TdcQuestion(
                text: 'traceroute montre le chemin des paquets.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'traceroute affiche les hops jusqu\'à la destination.',
              ),
            ],
          ),
          TdcModule(
            id: 'ssh',
            title: 'Sécuriser SSH',
            duration: '25min',
            content: '# SSH\n\nClés, fail2ban, désactivation root.',
            questions: [
              TdcQuestion(
                text: 'Quelle authentification est préférable aux mots de passe ?',
                choices: [
                  TdcChoice(text: 'Clés publiques', correct: true),
                  TdcChoice(text: 'Telnet', correct: false),
                ],
                explanation: 'Les clés SSH réduisent le risque de brute-force.',
              ),
              TdcQuestion(
                text: 'PermitRootLogin no est une bonne pratique.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'Désactiver le login root limite la surface d\'attaque.',
              ),
              TdcQuestion(
                text: 'Quel fichier configure le serveur SSH ?',
                choices: [
                  TdcChoice(text: '/etc/ssh/sshd_config', correct: true),
                  TdcChoice(text: '/etc/hosts', correct: false),
                ],
                explanation: 'sshd_config contrôle le démon SSH.',
              ),
            ],
          ),
          TdcModule(
            id: 'firewall',
            title: 'Pare-feu de base',
            duration: '25min',
            content: '# Firewall\n\nufw / nftables : règles minimales.',
            questions: [
              TdcQuestion(
                text: 'ufw allow 22/tcp autorise SSH.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'Le port 22/tcp est celui de SSH.',
              ),
              TdcQuestion(
                text: 'Un firewall doit partir du principe deny by default.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'On n\'ouvre que ce qui est nécessaire.',
              ),
              TdcQuestion(
                text: 'Quelle commande active ufw ?',
                choices: [
                  TdcChoice(text: 'ufw enable', correct: true),
                  TdcChoice(text: 'ufw start', correct: false),
                ],
                explanation: 'ufw enable active le pare-feu au démarrage.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static TdcResource productionIncident() {
    return TdcResource(
      tdcVersion: '2',
      type: 'course',
      id: 'prod-incident',
      concrete: TdcCourse(
        id: 'prod-incident',
        title: 'Incident de Production',
        description: 'Scénario réaliste : diagnostiquer et résoudre un incident serveur sous pression.',
        category: 'system',
        level: 'intermediate',
        duration: '1h30',
        icon: 'Warning',
        modules: [
          TdcModule(
            id: 'scenario',
            title: 'Scénario',
            duration: '15min',
            content: '# 🚨 Incident\n\nVous êtes d\'astreinte. Le monitoring alerte : latence API x10, CPU 95%.\n\n## Contexte\n- Serveur Linux\n- Service API derrière nginx\n- Base PostgreSQL locale',
            questions: [
              TdcQuestion(
                text: 'Quelle est la première étape recommandée ?',
                choices: [
                  TdcChoice(text: 'Stabiliser et observer', correct: true),
                  TdcChoice(text: 'Redémarrer immédiatement tout', correct: false),
                ],
                explanation: 'Observer avant d\'agir évite d\'aggraver la situation.',
              ),
            ],
          ),
          TdcModule(
            id: 'diagnostic',
            title: 'Diagnostic',
            duration: '30min',
            content: '# Diagnostic\n\nAudit CPU, mémoire, I/O, logs.',
            codeBlocks: [
              TdcCodeBlock(
                language: 'bash',
                title: 'Check rapide',
                code: 'uptime\nfree -h\ndf -h\njournalctl -u api -n 50 --no-pager',
              ),
            ],
            questions: [
              TdcQuestion(
                text: 'Quelle commande lit les logs systemd d\'un service ?',
                choices: [
                  TdcChoice(text: 'journalctl -u [service]', correct: true),
                  TdcChoice(text: 'cat /etc/passwd', correct: false),
                ],
                explanation: 'journalctl -u filtre les logs d\'une unit.',
              ),
              TdcQuestion(
                text: 'df -h indique l\'espace disque.',
                choices: [
                  TdcChoice(text: 'Vrai', correct: true),
                  TdcChoice(text: 'Faux', correct: false),
                ],
                explanation: 'df -h montre l\'utilisation des systèmes de fichiers.',
              ),
            ],
          ),
          TdcModule(
            id: 'solution',
            title: 'Solution & post-mortem',
            duration: '30min',
            content: '# Remédiation\n\n1. Identifier le process gourmand\n2. Mitiger (restart contrôlé / scale)\n3. Documenter le post-mortem',
            questions: [
              TdcQuestion(
                text: 'Un post-mortem doit blâmer un individu.',
                choices: [
                  TdcChoice(text: 'Faux', correct: true),
                  TdcChoice(text: 'Vrai', correct: false),
                ],
                explanation: 'Les post-mortems sont blameless : on corrige le système.',
              ),
              TdcQuestion(
                text: 'Que faut-il livrer après un incident ?',
                choices: [
                  TdcChoice(text: 'Timeline + actions correctives', correct: true),
                  TdcChoice(text: 'Rien, c\'est fini', correct: false),
                ],
                explanation: 'Documenter évite la récurrence.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
