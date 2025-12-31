# AWS Infrastructure Automation with Terraform & GitHub Actions

Déploiement automatisé d'infrastructure AWS EC2 avec gestion complète du cycle de vie via GitHub Actions.

## Prérequis

- ✅ Compte AWS (Sandbox étudiant)
- ✅ Compte GitHub
- ✅ Git installé localement
- ✅ VS Code

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Bootstrap   │→ │    Apply     │→ │   Destroy    │  │
│  │  (S3 Bucket) │  │ (EC2 + SG)   │  │ (Cleanup)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  S3 Bucket   │  │  EC2 Instance│  │Security Group│  │
│  │ (TF State)   │  │  + Apache    │  │  (Port 80)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Configuration (5 minutes)

### Étape 1: Configuration AWS

**Créer les Access Keys:**
   - Lancer un lab Sandbox
   - **⚠️ Noter les credentials:**
     - Access Key ID
     - Secret Access Key

### Étape 2: Configuration GitHub

1. **Créer le repository:**
   ```bash
   # Sur GitHub.com
   New repository → terraform-aws-automation
   ```

2. **Ajouter les secrets:**
   - Settings → Secrets and variables → Actions → New secret
   
   | Secret Name | Value |
   |-------------|-------|
   | `AWS_ACCESS_KEY_ID` | Votre Access Key ID |
   | `AWS_SECRET_ACCESS_KEY` | Votre Secret Access Key |

### Étape 3: Cloner et Push

```bash
# Cloner le repo
git clone https://github.com/[USERNAME]/terraform-aws-automation.git
cd terraform-aws-automation

# Créer la structure (copier tous les fichiers fournis)
# bootstrap/s3-backend.tf
# infrastructure/main.tf, variables.tf, outputs.tf
# .github/workflows/terraform.yml
# README.md

# Commit et push
git add .
git commit -m "[bootstrap] Initial setup"
git push origin main
```

## Utilisation

### Premier déploiement (avec Bootstrap)

Le commit avec `[bootstrap]` dans le message déclenche automatiquement:
1. Création du bucket S3
2. Déploiement de l'infrastructure EC2

```bash
git commit -m "[bootstrap] Deploy infrastructure"
git push
```

**OU via l'interface GitHub:**
- Actions → Workflow → Run workflow
- Action: `apply`
- Bootstrap: ✅ (coché)
- Run workflow

### Déploiements suivants (sans Bootstrap)

```bash
# Modifier un fichier
git add .
git commit -m "Update infrastructure"
git push
```

**OU via l'interface GitHub:**
- Actions → Workflow → Run workflow
- Action: `apply`
- Bootstrap: ⬜ (décoché)
- Run workflow

### Tester avant d'appliquer

```bash
# Via l'interface GitHub uniquement
Actions → Workflow → Run workflow
Action: plan
Run workflow
```

###  Détruire l'infrastructure

```bash
# Via l'interface GitHub
Actions → Workflow → Run workflow
Action: destroy
Bootstrap: ⬜ (pour garder le bucket S3)
Run workflow
```

### Nettoyage complet (supprimer aussi le S3)

```bash
# Via l'interface GitHub
Actions → Workflow → Run workflow
Action: destroy
Bootstrap: ✅ (coché - supprime aussi le bucket)
Run workflow
```

##  Outputs du Workflow

Après chaque déploiement, vous obtenez:

```
 Infrastructure Deployed Successfully!

EC2 Instance Details
┌──────────────────┬─────────────────────────┐
│ Instance ID      │ i-0123456789abcdef0     │
│ Public IP        │ 54.123.45.67            │
│ Region           │ us-east-1               │
└──────────────────┴─────────────────────────┘

🌐 Access: http://54.123.45.67
 Wait 2-3 minutes for server to start
```

##  Page Web Déployée

L'instance EC2 héberge une page web avec:
- ✅ Design moderne et responsive
- ✅ Informations de l'instance (ID, Zone, Type)
- ✅ Badges Terraform + GitHub Actions + AWS
- ✅ Apache HTTP Server

##  Personnalisation

### Changer la région AWS

**Fichier: `.github/workflows/terraform.yml`**
```yaml
env:
  AWS_REGION: eu-west-1  # Changer ici
```

### Changer le type d'instance

**Fichier: `infrastructure/variables.tf`**
```hcl
variable "instance_type" {
  default = "t2.small"  # Au lieu de t2.micro
}
```

### Modifier la page web

**Fichier: `infrastructure/main.tf`**
```hcl
# Dans le user_data, section HTML
cat > /var/www/html/index.html <<'HTML'
  [Votre HTML personnalisé]
HTML
```

##  Structure du Projet

```
terraform-aws-automation/
├── .github/
│   └── workflows/
│       └── terraform.yml          # Workflow principal
├── bootstrap/
│   └── s3-backend.tf              # Création bucket S3
├── infrastructure/
│   ├── main.tf                    # Infrastructure EC2
│   ├── variables.tf               # Variables
│   └── outputs.tf                 # Outputs
└── README.md
```

##  Sécurité

- ✅ Credentials AWS dans GitHub Secrets
- ✅ Bucket S3 avec versioning activé
- ✅ Bucket S3 avec chiffrement AES256
- ✅ Bucket S3 avec accès public bloqué
- ✅ Security Group restrictif (ports 80 et 22 uniquement)

##  Dépannage

### Le workflow échoue au bootstrap
```bash
# Vérifier que les secrets sont bien configurés
Settings → Secrets → Actions → Vérifier les 2 secrets
```

### L'instance ne répond pas
```bash
# Attendre 2-3 minutes après le déploiement
# Vérifier le Security Group dans AWS Console
# Essayer http:// (pas https://)
```

### Erreur "bucket already exists"
```bash
# Le bucket existe déjà, pas besoin de bootstrap
# Lancer uniquement avec action: apply
```

### Lab AWS expiré
```bash
# Relancer un nouveau lab
# Regénérer les Access Keys
# Mettre à jour les secrets GitHub
# Relancer avec bootstrap: true
```

## 💡 Astuces

1. **Déploiement rapide:** Utilisez `[bootstrap]` dans le message de commit pour le premier déploiement uniquement

2. **Test sans risque:** Utilisez `action: plan` pour voir les changements avant de les appliquer

3. **Économiser des crédits AWS:** Pensez à détruire l'infrastructure après vos tests

4. **Nouveau lab AWS:** À chaque nouveau lab, lancez avec `bootstrap: true` pour recréer le bucket S3

5. **Monitoring:** Vérifiez les logs dans Actions → Workflow run → Job → Step

##  Workflow Triggers

| Trigger | Action | Quand l'utiliser |
|---------|--------|------------------|
| Push sur `main` avec `[bootstrap]` | Bootstrap + Apply | Premier déploiement |
| Push sur `main` | Apply | Mise à jour de l'infra |
| Manual: `apply` | Apply | Déploiement manuel |
| Manual: `plan` | Plan | Test avant apply |
| Manual: `destroy` | Destroy | Nettoyage |

##  Concepts Couverts

- ✅ Infrastructure as Code (Terraform)
- ✅ CI/CD (GitHub Actions)
- ✅ Cloud Computing (AWS EC2)
- ✅ Remote State Management (S3)
- ✅ Automation & Orchestration
- ✅ Security Best Practices

##  Ressources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2)

## Checklist de Validation

Avant de soumettre votre projet:

- [ ] Le bootstrap crée bien le bucket S3
- [ ] L'infrastructure se déploie automatiquement
- [ ] La page web est accessible via HTTP
- [ ] Le workflow destroy fonctionne
- [ ] Les secrets GitHub sont configurés
- [ ] Le README est à jour avec vos captures d'écran
- [ ] Les logs des workflows sont propres (pas d'erreurs)

##  Résultat Attendu

Après avoir suivi ce guide, vous aurez:

1. ✅ Un pipeline CI/CD complètement automatisé
2. ✅ Une infrastructure AWS déployable en 1 clic
3. ✅ Un système de versioning du state Terraform
4. ✅ Une application web fonctionnelle sur EC2
5. ✅ La capacité de détruire/recréer l'infra à volonté

**Temps total de setup: ~5 minutes**
**Temps de déploiement: ~3 minutes**

---

**Fait Par Ratib Laeliha**