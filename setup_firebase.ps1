# 🚀 Script PowerShell pour débloquer et installer Firebase Tools

# Étape 1: Débloquer l'exécution des scripts
Write-Host "🔓 Déblocage de PowerShell..." -ForegroundColor Cyan

# Vérifier si PowerShell est déjà configuré
$policy = Get-ExecutionPolicy
if ($policy -ne "RemoteSigned") {
    Write-Host "Configuration de la politique d'exécution..." -ForegroundColor Yellow
    
    # Option 1: RemoteSigned (recommandé pour les scripts signés)
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    
    # Option 2: Bypass (temporaire pour le déploiement)
    # Set-ExecutionPolicy Bypass -Scope Process -Force
    
    Write-Host "✅ Politique configurée : RemoteSigned" -ForegroundColor Green
} else {
    Write-Host "✅ PowerShell déjà configuré : $policy" -ForegroundColor Green
}

# Étape 2: Installation Firebase Tools
Write-Host "📦 Installation de Firebase Tools..." -ForegroundColor Cyan

# Méthode 1: npm (si disponible)
try {
    $npmVersion = npm --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ npm trouvé, installation en cours..." -ForegroundColor Green
        npm install -g firebase-tools
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "🎯 Firebase Tools installé avec succès !" -ForegroundColor Green
            Write-Host "Version : $(firebase --version)" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Échec de l'installation npm" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ npm non trouvé, tentative alternative..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur npm : $($_.Exception.Message)" -ForegroundColor Red
}

# Méthode 2: Téléchargement direct si npm échoue
if ($LASTEXITCODE -ne 0) {
    Write-Host "📥 Téléchargement direct de Firebase CLI..." -ForegroundColor Yellow
    
    try {
        # Télécharger l'installeur Windows
        $url = "https://firebase.tools/bin/windows/latest"
        $output = "$env:TEMP\firebase-installer.exe"
        
        Write-Host "Téléchargement depuis : $url" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $output
        
        # Exécuter l'installeur
        Start-Process -FilePath $output -Wait -Verb RunAs
        
        Write-Host "✅ Installation via installeur Windows terminée" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur téléchargement : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Étape 3: Vérification finale
Write-Host "🔍 Vérification de l'installation..." -ForegroundColor Cyan

try {
    $firebaseVersion = firebase --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎯 Firebase CLI v$firebaseVersion prêt à l'emploi !" -ForegroundColor Green
    } else {
        Write-Host "❌ Firebase non installé correctement" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur vérification : $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🚀 JTM est maintenant prêt pour le déploiement !" -ForegroundColor Green
Write-Host "📊 Prochaine étape : Exécutez .\deploy.ps1" -ForegroundColor Cyan
