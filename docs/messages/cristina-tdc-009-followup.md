# Message prêt à envoyer — Cristina / TDC-009

**À :** (email Cristina)  
**De :** Maxime MARTIN CIVET \<contact@tutodecode.org\>  
**Objet :** TDC-009 — suite du claim (nouveau flux « prendre #N »)

---

Bonjour Cristina,

Merci encore pour ton intérêt sur **TDC-009** (empty state quiz guidé).

La Merge Request **!7** (*Claim TDC-009*) a été **fermée** : ce n’était pas un rejet de ton travail, mais un **changement de procédure** côté association. Le claim bénévole ne passe plus par une MR « Claim TDC-xxx » libre : on utilise maintenant un flux anti-collision standardisé.

## Ce que tu peux faire pour continuer TDC-009

1. Repère l’**issue GitLab** correspondante (board bénévolat / label `benevolat`) — ou dis-moi si tu as besoin du lien exact.
2. Crée une branche du type `volunteer/prendre-<iid>` (ex. `volunteer/prendre-42` si l’issue est `#42`).
3. Ajoute le fichier marqueur `volunteer/claims/<iid>.md` avec ton **pseudo GitLab** :

```markdown
username: ton-pseudo
```

4. Ouvre une Merge Request dont le titre est **exactement** : `prendre #<iid>`  
   (ex. `prendre #42`). Corps minimal OK ; **DCO** obligatoire (`Signed-off-by`).
5. Dès que la MR de claim est mergée, l’issue te sera assignée (label `en-cours`). Ensuite tu poursuis avec une MR de code classique pour livrer TDC-009.

Docs utiles :
- [VOLUNTEER_BOARD.md](https://gitlab.com/tutodecode-org/tdc-sdk/-/blob/main/VOLUNTEER_BOARD.md)
- [CONTRIBUTING.md](https://gitlab.com/tutodecode-org/tdc-sdk/-/blob/main/CONTRIBUTING.md)

N’hésite pas si tu as une question sur le titre de MR ou le marqueur — on t’accompagne.

Bien cordialement,  
Maxime  
Association TUTODECODE  
contact@tutodecode.org
